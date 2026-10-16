import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

const _definedApiBaseUrl = String.fromEnvironment('API_BASE_URL');

/// Pass `--dart-define=API_BASE_URL=https://<app>.up.railway.app` for real builds.
String defaultApiBaseUrl() {
  if (_definedApiBaseUrl.isNotEmpty) return _definedApiBaseUrl;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:5173';
  }
  return 'http://localhost:5173';
}

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode = 0, this.code});

  final String message;
  final int statusCode;
  final String? code;

  bool get isUnauthorized => statusCode == 401;
  bool get isNetwork => statusCode == 0;

  @override
  String toString() => message;
}

abstract class TokenStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

class SecureTokenStore implements TokenStore {
  static const _key = 'auth_session_token';
  final _storage = const FlutterSecureStorage();

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

class MemoryTokenStore implements TokenStore {
  MemoryTokenStore([this.token]);

  String? token;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String token) async => this.token = token;

  @override
  Future<void> clear() async => token = null;
}

class UserSettings {
  const UserSettings({this.reminders = false, this.reminderMinute = 7 * 60});

  factory UserSettings.fromJson(Map<String, dynamic>? json) => UserSettings(
    reminders: json?['reminders'] == true,
    reminderMinute: ((json?['reminderMinute'] as num?)?.toInt() ?? 420).clamp(
      0,
      1439,
    ),
  );

  final bool reminders;
  final int reminderMinute;

  Map<String, dynamic> toJson() => {
    'reminders': reminders,
    'reminderMinute': reminderMinute,
  };
}

class ApiUser {
  const ApiUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.country,
    this.hasPassword = true,
    this.appleLinked = false,
    this.avatarUpdatedAt,
    this.settings = const UserSettings(),
  });

  factory ApiUser.fromJson(Map<String, dynamic> json) => ApiUser(
    id: json['id'] as String,
    email: (json['email'] as String?) ?? '',
    fullName: (json['fullName'] as String?) ?? '',
    phone: (json['phone'] as String?) ?? '',
    country: (json['country'] as String?) ?? '',
    hasPassword: json['hasPassword'] == true,
    appleLinked: json['appleLinked'] == true,
    avatarUpdatedAt: json['avatarUpdatedAt'] as String?,
    settings: UserSettings.fromJson(json['settings'] as Map<String, dynamic>?),
  );

  final String id;
  final String email;
  final String fullName;
  final String phone;
  final String country;
  final bool hasPassword;
  final bool appleLinked;
  final String? avatarUpdatedAt;
  final UserSettings settings;

  bool get needsProfile => fullName.trim().length < 2 || country.isEmpty;

  ApiUser copyWith({UserSettings? settings}) => ApiUser(
    id: id,
    email: email,
    fullName: fullName,
    phone: phone,
    country: country,
    hasPassword: hasPassword,
    appleLinked: appleLinked,
    avatarUpdatedAt: avatarUpdatedAt,
    settings: settings ?? this.settings,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'fullName': fullName,
    'phone': phone,
    'country': country,
    'hasPassword': hasPassword,
    'appleLinked': appleLinked,
    'avatarUpdatedAt': avatarUpdatedAt,
    'settings': settings.toJson(),
  };
}

class UserStats {
  const UserStats({
    this.bookmarks = 0,
    this.journals = 0,
    this.courseRegistrations = 0,
  });

  factory UserStats.fromJson(Map<String, dynamic>? json) => UserStats(
    bookmarks: (json?['bookmarks'] as num?)?.toInt() ?? 0,
    journals: (json?['journals'] as num?)?.toInt() ?? 0,
    courseRegistrations: (json?['courseRegistrations'] as num?)?.toInt() ?? 0,
  );

  final int bookmarks;
  final int journals;
  final int courseRegistrations;
}

class CommunityMember {
  const CommunityMember({
    required this.id,
    required this.fullName,
    required this.country,
  });

  factory CommunityMember.fromJson(Map<String, dynamic> json) =>
      CommunityMember(
        id: json['id'] as String,
        fullName: (json['fullName'] as String?) ?? 'Thành viên',
        country: (json['country'] as String?) ?? '',
      );

  final String id;
  final String fullName;
  final String country;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.body,
    required this.createdAt,
    required this.isMine,
    required this.author,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'].toString(),
    body: json['body'] as String,
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal() ??
        DateTime.now(),
    isMine: json['isMine'] == true,
    author: CommunityMember.fromJson(json['author'] as Map<String, dynamic>),
  );

  final String id;
  final String body;
  final DateTime createdAt;
  final bool isMine;
  final CommunityMember author;
}

class Bookmark {
  const Bookmark({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.title,
    required this.createdAt,
  });

  factory Bookmark.fromJson(Map<String, dynamic> json) => Bookmark(
    id: json['id'] as String,
    targetType: json['targetType'] as String,
    targetId: json['targetId'] as String,
    title: (json['title'] as String?) ?? '',
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal() ??
        DateTime.now(),
  );

  final String id;
  final String targetType;
  final String targetId;
  final String title;
  final DateTime createdAt;
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.read,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        kind: (json['kind'] as String?) ?? 'info',
        title: json['title'] as String,
        body: (json['body'] as String?) ?? '',
        read: json['read'] == true,
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal() ??
            DateTime.now(),
      );

  final String id;

  /// One of `info`, `course`, `warning`, `community`.
  final String kind;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;

  AppNotification markedRead() => AppNotification(
    id: id,
    kind: kind,
    title: title,
    body: body,
    createdAt: createdAt,
    read: true,
  );
}

class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.title,
    required this.note,
    required this.createdAt,
    this.mood,
    this.relatedType,
    this.relatedId,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
    id: json['id'] as String,
    title: json['title'] as String,
    note: (json['note'] as String?) ?? '',
    mood: (json['mood'] as num?)?.toInt(),
    relatedType: json['relatedType'] as String?,
    relatedId: json['relatedId'] as String?,
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal() ??
        DateTime.now(),
  );

  final String id;
  final String title;
  final String note;
  final int? mood;
  final String? relatedType;
  final String? relatedId;
  final DateTime createdAt;
}

class CourseRegistration {
  const CourseRegistration({
    required this.id,
    required this.courseCode,
    required this.courseName,
    required this.status,
    required this.createdAt,
  });

  factory CourseRegistration.fromJson(Map<String, dynamic> json) =>
      CourseRegistration(
        id: json['id'] as String,
        courseCode: json['courseCode'] as String,
        courseName: (json['courseName'] as String?) ?? '',
        status: (json['status'] as String?) ?? 'new',
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal() ??
            DateTime.now(),
      );

  final String id;
  final String courseCode;
  final String courseName;
  final String status;
  final DateTime createdAt;
}

class AuthResult {
  const AuthResult({
    required this.token,
    required this.user,
    this.isNewUser = false,
  });

  final String token;
  final ApiUser user;
  final bool isNewUser;
}

/// Sign in with Apple: Apple receives the SHA-256 of the nonce, the server the raw value.
String sha256OfString(String input) =>
    sha256.convert(utf8.encode(input)).toString();

class DienChanApi {
  DienChanApi({String? baseUrl, http.Client? client, TokenStore? tokenStore})
    : baseUrl = (baseUrl ?? defaultApiBaseUrl()).replaceAll(RegExp(r'/+$'), ''),
      _client = client ?? http.Client(),
      tokenStore = tokenStore ?? SecureTokenStore();

  final String baseUrl;
  final http.Client _client;
  final TokenStore tokenStore;
  String? _token;

  /// Called when the server rejects the stored session.
  VoidCallback? onUnauthorized;

  String? get token => _token;
  bool get hasSession => _token != null;

  Uri get realtimeUri {
    final uri = Uri.parse('$baseUrl/api/v1/realtime');
    return uri.replace(scheme: uri.scheme == 'https' ? 'wss' : 'ws');
  }

  Future<void> restoreToken() async {
    try {
      _token = await tokenStore.read();
    } catch (_) {
      _token = null;
    }
  }

  Future<void> _saveToken(String token) async {
    _token = token;
    await tokenStore.write(token);
  }

  Future<void> clearToken() async {
    _token = null;
    try {
      await tokenStore.clear();
    } catch (_) {
      // Storage failures must not keep the user signed in on screen.
    }
  }

  Future<http.Response> _raw(
    String method,
    String path, {
    Object? json,
    Uint8List? bytes,
    String? contentType,
  }) async {
    final request = http.Request(method, Uri.parse('$baseUrl/api/v1$path'));
    if (_token != null) request.headers['Authorization'] = 'Bearer $_token';
    if (json != null) {
      request.headers['Content-Type'] = 'application/json; charset=utf-8';
      request.body = jsonEncode(json);
    } else if (bytes != null) {
      request.headers['Content-Type'] =
          contentType ?? 'application/octet-stream';
      request.bodyBytes = bytes;
    }
    final http.Response response;
    try {
      response = await http.Response.fromStream(
        await _client.send(request).timeout(const Duration(seconds: 20)),
      );
    } on TimeoutException {
      throw const ApiException('Máy chủ phản hồi quá lâu. Vui lòng thử lại.');
    } catch (_) {
      throw const ApiException(
        'Không kết nối được máy chủ. Kiểm tra mạng và thử lại.',
      );
    }
    if (response.statusCode >= 400) {
      String message = 'Có lỗi xảy ra (${response.statusCode}).';
      String? code;
      try {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data is Map && data['error'] is String) {
          message = data['error'] as String;
          code = data['code'] as String?;
        }
      } catch (_) {}
      if (response.statusCode == 401 && _token != null) onUnauthorized?.call();
      throw ApiException(message, statusCode: response.statusCode, code: code);
    }
    return response;
  }

  Future<Map<String, dynamic>> _json(
    String method,
    String path, {
    Object? body,
    Uint8List? bytes,
    String? contentType,
  }) async {
    final response = await _raw(
      method,
      path,
      json: body,
      bytes: bytes,
      contentType: contentType,
    );
    if (response.bodyBytes.isEmpty) return const {};
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    return data is Map<String, dynamic> ? data : {'data': data};
  }

  Future<AuthResult> _session(Map<String, dynamic> data) async {
    final result = AuthResult(
      token: data['token'] as String,
      user: ApiUser.fromJson(data['user'] as Map<String, dynamic>),
      isNewUser: data['isNewUser'] == true,
    );
    await _saveToken(result.token);
    return result;
  }

  // ---------- Auth ----------

  Future<AuthResult> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String country,
  }) async => _session(
    await _json(
      'POST',
      '/auth/register',
      body: {
        'email': email,
        'password': password,
        'fullName': fullName,
        'phone': phone,
        'country': country,
      },
    ),
  );

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async => _session(
    await _json(
      'POST',
      '/auth/login',
      body: {'email': email, 'password': password},
    ),
  );

  Future<AuthResult> signInWithApple({
    required String identityToken,
    required String rawNonce,
    String? authorizationCode,
    String? fullName,
  }) async => _session(
    await _json(
      'POST',
      '/auth/apple',
      body: {
        'identityToken': identityToken,
        'nonce': rawNonce,
        'authorizationCode': ?authorizationCode,
        'fullName': ?fullName,
      },
    ),
  );

  Future<void> logout() async {
    try {
      if (_token != null) await _json('POST', '/auth/logout');
    } finally {
      await clearToken();
    }
  }

  Future<void> forgotPassword(String email) =>
      _json('POST', '/auth/password/forgot', body: {'email': email});

  Future<AuthResult> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async => _session(
    await _json(
      'POST',
      '/auth/password/reset',
      body: {'email': email, 'code': code, 'password': password},
    ),
  );

  Future<void> changePassword({
    String? currentPassword,
    required String newPassword,
  }) => _json(
    'POST',
    '/auth/password/change',
    body: {'currentPassword': ?currentPassword, 'newPassword': newPassword},
  );

  // ---------- Profile ----------

  Future<(ApiUser, UserStats)> me() async {
    final data = await _json('GET', '/me');
    return (
      ApiUser.fromJson(data['user'] as Map<String, dynamic>),
      UserStats.fromJson(data['stats'] as Map<String, dynamic>?),
    );
  }

  Future<ApiUser> updateProfile({
    required String fullName,
    required String phone,
    required String country,
  }) async {
    final data = await _json(
      'PATCH',
      '/me',
      body: {'fullName': fullName, 'phone': phone, 'country': country},
    );
    return ApiUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> deleteAccount({String? password}) async {
    await _json(
      'DELETE',
      '/me',
      body: password == null ? {'confirm': 'DELETE'} : {'password': password},
    );
    await clearToken();
  }

  Future<Uint8List?> avatar() async {
    try {
      return (await _raw('GET', '/me/avatar')).bodyBytes;
    } on ApiException catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<ApiUser> uploadAvatar(
    Uint8List bytes, {
    String type = 'image/png',
  }) async {
    final data = await _json(
      'PUT',
      '/me/avatar',
      bytes: bytes,
      contentType: type,
    );
    return ApiUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<ApiUser> deleteAvatar() async {
    final data = await _json('DELETE', '/me/avatar');
    return ApiUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<UserSettings> saveSettings(UserSettings settings) async =>
      UserSettings.fromJson(
        await _json('PUT', '/me/settings', body: settings.toJson()),
      );

  // ---------- Bookmarks & journals ----------

  Future<List<Bookmark>> bookmarks() async {
    final data = await _json('GET', '/me/bookmarks');
    return (data['bookmarks'] as List)
        .map((item) => Bookmark.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Bookmark> addBookmark({
    required String targetType,
    required String targetId,
    required String title,
  }) async {
    final data = await _json(
      'POST',
      '/me/bookmarks',
      body: {'targetType': targetType, 'targetId': targetId, 'title': title},
    );
    return Bookmark.fromJson(data['bookmark'] as Map<String, dynamic>);
  }

  Future<void> removeBookmark(String id) =>
      _json('DELETE', '/me/bookmarks/$id');

  Future<List<JournalEntry>> journals() async {
    final data = await _json('GET', '/me/journals');
    return (data['journals'] as List)
        .map((item) => JournalEntry.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<JournalEntry> addJournal({
    required String title,
    String note = '',
    int? mood,
    String? relatedType,
    String? relatedId,
  }) async {
    final data = await _json(
      'POST',
      '/me/journals',
      body: {
        'title': title,
        'note': note,
        'mood': ?mood,
        'relatedType': ?relatedType,
        'relatedId': ?relatedId,
      },
    );
    return JournalEntry.fromJson(data['journal'] as Map<String, dynamic>);
  }

  Future<void> removeJournal(String id) => _json('DELETE', '/me/journals/$id');

  /// [contact] is only needed when nobody is signed in.
  Future<void> sendSupportRequest(String message, {String? contact}) => _json(
    'POST',
    '/support-requests',
    body: {'message': message, 'contact': ?contact},
  );

  // ---------- Notifications ----------

  Future<List<AppNotification>> notifications() async {
    final data = await _json('GET', '/me/notifications');
    return (data['notifications'] as List)
        .map((item) => AppNotification.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Marks [ids] as read, or every notification when [ids] is null.
  Future<void> markNotificationsRead([List<String>? ids]) =>
      _json('POST', '/me/notifications/read', body: {'ids': ?ids});

  // ---------- Courses ----------

  Future<CourseRegistration> registerCourse({
    required String courseCode,
    required String fullName,
    required String phone,
    String note = '',
  }) async {
    final data = await _json(
      'POST',
      '/course-registrations',
      body: {
        'courseCode': courseCode,
        'fullName': fullName,
        'phone': phone,
        'note': note,
      },
    );
    return CourseRegistration.fromJson(
      data['registration'] as Map<String, dynamic>,
    );
  }

  Future<List<CourseRegistration>> myCourseRegistrations() async {
    final data = await _json('GET', '/me/course-registrations');
    return (data['registrations'] as List)
        .map(
          (item) => CourseRegistration.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  // ---------- Community ----------

  Future<(List<ChatMessage>, bool)> chatMessages({String? before}) async {
    final query = before == null ? '' : '?before=$before';
    final data = await _json('GET', '/chat/messages$query');
    return (
      (data['messages'] as List)
          .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
          .toList(),
      data['hasMore'] == true,
    );
  }

  Future<ChatMessage> sendChat(String body) async {
    final data = await _json('POST', '/chat/messages', body: {'body': body});
    return ChatMessage.fromJson(data['message'] as Map<String, dynamic>);
  }

  Future<void> deleteChat(String id) => _json('DELETE', '/chat/messages/$id');

  Future<void> reportChat(String id, String reason) =>
      _json('POST', '/chat/messages/$id/report', body: {'reason': reason});

  Future<List<CommunityMember>> onlineUsers() async {
    final data = await _json('GET', '/chat/online');
    return _members(data['users']);
  }

  Future<List<CommunityMember>> blockedUsers() async {
    final data = await _json('GET', '/me/blocks');
    return _members(data['users']);
  }

  Future<void> blockUser(String userId) =>
      _json('POST', '/me/blocks', body: {'userId': userId});

  Future<void> unblockUser(String userId) =>
      _json('DELETE', '/me/blocks/$userId');

  static List<CommunityMember> _members(Object? list) => (list as List)
      .map((item) => CommunityMember.fromJson(item as Map<String, dynamic>))
      .toList();
}

typedef SocketConnector = WebSocketChannel Function(Uri uri);

/// Keeps one WebSocket open while signed in: online list + live chat events.
class CommunityRealtime extends ChangeNotifier {
  CommunityRealtime(this.api, {this.connector = WebSocketChannel.connect});

  final DienChanApi api;

  /// Null disables realtime (widget tests).
  SocketConnector? connector;

  List<CommunityMember> online = const [];
  bool connected = false;

  final _events = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get events => _events.stream;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _retryTimer;
  int _attempt = 0;
  bool _running = false;

  void start() {
    if (_running) return;
    _running = true;
    _attempt = 0;
    _connect();
  }

  void stop() {
    _running = false;
    _retryTimer?.cancel();
    _closeChannel();
    online = const [];
    connected = false;
    notifyListeners();
  }

  void _closeChannel() {
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
  }

  Future<void> _connect() async {
    final connect = connector;
    final token = api.token;
    if (!_running || connect == null || token == null) return;
    _closeChannel();
    try {
      final channel = connect(api.realtimeUri);
      _channel = channel;
      await channel.ready;
      if (!_running || _channel != channel) return;
      channel.sink.add(jsonEncode({'type': 'auth', 'token': token}));
      _subscription = channel.stream.listen(
        _handle,
        onDone: () => _disconnected(channel.closeCode),
        onError: (_) => _disconnected(null),
      );
    } catch (_) {
      _disconnected(null);
    }
  }

  void _handle(dynamic raw) {
    final Map<String, dynamic> event;
    try {
      event = jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    switch (event['type']) {
      case 'ready':
        _attempt = 0;
        connected = true;
        notifyListeners();
      case 'presence':
        online = DienChanApi._members(event['users']);
        notifyListeners();
      default:
        _events.add(event);
    }
  }

  void _disconnected(int? closeCode) {
    if (connected) {
      connected = false;
      notifyListeners();
    }
    if (!_running) return;
    if (closeCode == 4401) {
      // Session is no longer valid; the next API call will sign out.
      _running = false;
      return;
    }
    _attempt += 1;
    final seconds = math.min(30, 1 << math.min(_attempt, 5));
    _retryTimer?.cancel();
    _retryTimer = Timer(Duration(seconds: seconds), _connect);
  }

  @override
  void dispose() {
    stop();
    _events.close();
    super.dispose();
  }
}
