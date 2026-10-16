import 'dart:convert';

import 'package:dien_chan_app/api_client.dart';
import 'package:dien_chan_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory stand-in for the Railway API.
class FakeBackend {
  final users = <String, Map<String, dynamic>>{};
  final passwords = <String, String>{};
  final avatars = <String, List<int>>{};
  final sessions = <String, String>{};
  final messages = <Map<String, dynamic>>[];
  final registrations = <Map<String, dynamic>>[];
  final notifications = <Map<String, dynamic>>[];
  final supportRequests = <Map<String, dynamic>>[];
  final requests = <String>[];
  int _ids = 0;

  String addUser({
    String fullName = 'Nguyễn An',
    String email = 'an@example.com',
    String password = 'mat-khau-123',
    String phone = '0901234567',
    String country = 'Việt Nam',
  }) {
    final id = 'user-${++_ids}';
    users[id] = {
      'id': id,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'country': country,
      'hasPassword': true,
      'appleLinked': false,
      'avatarUpdatedAt': null,
      'settings': {'reminders': false, 'reminderMinute': 420},
    };
    passwords[email] = password;
    return id;
  }

  String signIn(String userId) {
    final token = 'token-${++_ids}';
    sessions[token] = userId;
    return token;
  }

  http.Response _json(int status, Object body) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  MockClient get client => MockClient((request) async {
    final path = request.url.path.replaceFirst('/api/v1', '');
    requests.add('${request.method} $path');
    final token = request.headers['Authorization']?.replaceFirst('Bearer ', '');
    final userId = sessions[token];
    final user = users[userId];
    Map<String, dynamic> body() => request.body.isEmpty
        ? {}
        : jsonDecode(request.body) as Map<String, dynamic>;
    Map<String, dynamic> session(String id) {
      final newToken = signIn(id);
      return {'token': newToken, 'user': users[id]};
    }

    switch ('${request.method} $path') {
      case 'POST /auth/login':
        final data = body();
        final match = users.values.where((u) => u['email'] == data['email']);
        if (match.isEmpty || passwords[data['email']] != data['password']) {
          return _json(401, {'error': 'Email hoặc mật khẩu không đúng'});
        }
        return _json(200, session(match.first['id'] as String));
      case 'POST /auth/register':
        final data = body();
        if (users.values.any((u) => u['email'] == data['email'])) {
          return _json(409, {'error': 'Email này đã được đăng ký.'});
        }
        final id = addUser(
          fullName: data['fullName'] as String,
          email: data['email'] as String,
          password: data['password'] as String,
          phone: data['phone'] as String,
          country: data['country'] as String,
        );
        return _json(201, session(id));
      case 'POST /auth/logout':
        sessions.remove(token);
        return _json(200, {'ok': true});
      case 'POST /course-registrations':
        final data = body();
        registrations.add(data);
        return _json(201, {
          'registration': {
            'id': 'reg-${registrations.length}',
            'courseCode': data['courseCode'],
            'courseName': 'Khóa 48 - Offline',
            'status': 'new',
            'createdAt': DateTime.now().toIso8601String(),
          },
        });
    }
    if (user == null) {
      return _json(401, {'error': 'Phiên đăng nhập đã hết hạn'});
    }
    switch ('${request.method} $path') {
      case 'GET /me':
        return _json(200, {
          'user': user,
          'stats': {
            'bookmarks': 0,
            'journals': 2,
            'courseRegistrations': registrations.length,
          },
        });
      case 'PATCH /me':
        user.addAll(body());
        return _json(200, {'user': user});
      case 'DELETE /me':
        if (body()['password'] != passwords[user['email']]) {
          return _json(400, {'error': 'Mật khẩu không đúng'});
        }
        users.remove(userId);
        sessions.removeWhere((_, value) => value == userId);
        return _json(200, {'ok': true});
      case 'PUT /me/settings':
        user['settings'] = body();
        return _json(200, user['settings'] as Object);
      case 'GET /me/avatar':
        final bytes = avatars[userId];
        if (bytes == null) return _json(404, {'error': 'Chưa có ảnh'});
        return http.Response.bytes(bytes, 200);
      case 'DELETE /me/avatar':
        avatars.remove(userId);
        user['avatarUpdatedAt'] = null;
        return _json(200, {'user': user});
      case 'GET /me/notifications':
        return _json(200, {
          'notifications': notifications,
          'unread': notifications.where((n) => n['read'] != true).length,
        });
      case 'POST /me/notifications/read':
        final ids = body()['ids'] as List?;
        for (final item in notifications) {
          if (ids == null || ids.contains(item['id'])) item['read'] = true;
        }
        return _json(200, {'ok': true});
      case 'POST /support-requests':
        supportRequests.add({...body(), 'userId': userId});
        return _json(201, {'ok': true});
      case 'GET /chat/messages':
        return _json(200, {'messages': messages, 'hasMore': false});
      case 'POST /chat/messages':
        final message = {
          'id': '${messages.length + 1}',
          'body': body()['body'],
          'createdAt': DateTime.now().toIso8601String(),
          'isMine': true,
          'author': {
            'id': userId,
            'fullName': user['fullName'],
            'country': user['country'],
          },
        };
        messages.add(message);
        return _json(201, {'message': message});
    }
    return _json(404, {'error': 'Not found'});
  });
}

late FakeBackend backend;
late MemoryTokenStore tokens;

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'medical_disclaimer_v1': true});
    backend = FakeBackend();
    tokens = MemoryTokenStore();
    configureBackendForTesting(
      DienChanApi(
        baseUrl: 'http://api.test',
        client: backend.client,
        tokenStore: tokens,
      ),
    );
  });

  testWidgets('Dữ liệu cục bộ sai kiểu không làm kẹt màn hình tải', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'auth_cached_user': 123,
      'settings_last_reminder': 5,
      'medical_disclaimer_v1': true,
    });
    tokens.token = 'expired-token';
    await tester.pumpWidget(const MultiDemoApp());
    await tester.pumpAndSettle();
    expect(find.text('Trang chủ'), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tokens.token, isNull, reason: 'phiên hết hạn bị xóa');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('App mở thẳng Mẫu A vào trang chủ', (tester) async {
    await tester.pumpWidget(const MultiDemoApp());
    await tester.pumpAndSettle();

    expect(find.text('Trang chủ'), findsWidgets);
    expect(find.text('Tra cứu'), findsWidgets);
    expect(find.text('Bản mẫu giao diện Diện Chẩn'), findsNothing);
    expect(find.text('Đăng ký / Đăng nhập'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Khách cần đăng nhập khi mở Kết nối', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CommunityTab(preset: finflowPreset)),
      ),
    );
    expect(find.text('Đăng ký / Đăng nhập'), findsOneWidget);
    expect(
      find.text('Đăng nhập để tham gia cộng đồng Diện Chẩn.'),
      findsOneWidget,
    );
    expect(backend.requests, isEmpty, reason: 'khách không gọi API chat');
    await tester.tap(find.text('Đăng ký / Đăng nhập'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Quên mật khẩu?'), findsOneWidget);
    await tester.tap(find.text('Đăng ký'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(4));
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(
      find.text('Đăng nhập để tham gia cộng đồng Diện Chẩn.'),
      findsOneWidget,
    );
  });

  testWidgets('Hồ sơ khách có nút đăng nhập và không có đăng xuất', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileTab(preset: finflowPreset, onLogout: () async {}),
        ),
      ),
    );
    expect(find.text('Đăng ký / Đăng nhập'), findsOneWidget);
    expect(find.text('Đăng xuất'), findsNothing);
  });

  Future<void> openProfileAsGuest(WidgetTester tester) async {
    await tester.pumpWidget(const MultiDemoApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hồ sơ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đăng ký / Đăng nhập'));
    await tester.pumpAndSettle();
  }

  testWidgets('Đăng nhập sai báo lỗi, đúng thì vào hồ sơ', (tester) async {
    backend.addUser();
    await openProfileAsGuest(tester);
    await tester.enterText(find.byType(TextFormField).at(0), 'an@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'sai-mat-khau');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Email hoặc mật khẩu không đúng'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(1), 'mat-khau-123');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Nguyễn An'), findsOneWidget);
    expect(find.text('an@example.com · 0901234567'), findsOneWidget);
    expect(find.text('Đăng xuất'), findsOneWidget);
    expect(tokens.token, isNotNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Đăng ký tài khoản mới', (tester) async {
    await openProfileAsGuest(tester);
    await tester.tap(find.text('Đăng ký'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Trần Bình');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'binh@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(2), '123');
    await tester.ensureVisible(find.text('Tạo tài khoản'));
    await tester.tap(find.text('Tạo tài khoản'));
    await tester.pumpAndSettle();
    expect(find.text('Mật khẩu cần ít nhất 8 ký tự'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(2), 'mat-khau-123');
    await tester.ensureVisible(find.text('Tạo tài khoản'));
    await tester.tap(find.text('Tạo tài khoản'));
    await tester.pumpAndSettle();
    expect(find.text('Trần Bình'), findsOneWidget);
    expect(backend.users.values.single['email'], 'binh@example.com');
    await tester.pumpWidget(const SizedBox());
  });

  Future<String> openProfile(WidgetTester tester) async {
    final id = backend.addUser();
    tokens.token = backend.signIn(id);
    await tester.pumpWidget(const MultiDemoApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hồ sơ'));
    await tester.pumpAndSettle();
    return id;
  }

  testWidgets('Khôi phục phiên và hiển thị thống kê từ máy chủ', (
    tester,
  ) async {
    await openProfile(tester);
    expect(find.text('Nguyễn An'), findsOneWidget);
    expect(find.text('Nhật ký'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Sửa hồ sơ được lưu lên máy chủ', (tester) async {
    final id = await openProfile(tester);
    await tester.tap(find.text('Chỉnh sửa hồ sơ'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Nguyễn Bình');
    await tester.ensureVisible(find.text('Lưu thay đổi'));
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();
    expect(find.text('Nguyễn Bình'), findsOneWidget);
    expect(backend.users[id]!['fullName'], 'Nguyễn Bình');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Cài đặt nhắc giờ được lưu theo tài khoản', (tester) async {
    final id = await openProfile(tester);
    await tester.drag(find.byType(ListView).first, const Offset(0, -200));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quản lý nhắc giờ trong ứng dụng'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(backend.users[id]!['settings']['reminders'], isTrue);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(backend.users[id]!['settings']['reminders'], isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Xóa tài khoản cần mật khẩu và chuyển về khách', (tester) async {
    final id = await openProfile(tester);
    await tester.ensureVisible(find.text('Bảo mật và riêng tư'));
    await tester.tap(find.text('Bảo mật và riêng tư'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byIcon(Icons.delete_forever),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byIcon(Icons.delete_forever));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    expect(backend.users, contains(id));

    await tester.tap(find.byIcon(Icons.delete_forever));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'sai-mat-khau');
    await tester.tap(find.widgetWithText(FilledButton, 'Xóa tài khoản').last);
    await tester.pumpAndSettle();
    expect(find.text('Mật khẩu không đúng'), findsOneWidget);
    expect(backend.users, contains(id));

    ScaffoldMessenger.of(
      tester.element(find.byIcon(Icons.delete_forever)),
    ).removeCurrentSnackBar();
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_forever));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'mat-khau-123');
    await tester.tap(find.widgetWithText(FilledButton, 'Xóa tài khoản').last);
    await tester.pumpAndSettle();
    expect(backend.users, isNot(contains(id)));
    expect(find.text('Khách'), findsOneWidget);
    expect(tokens.token, isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Bản nháp hỗ trợ được giữ khi mở lại màn hình', (tester) async {
    await openProfile(tester);
    await tester.drag(find.byType(ListView).first, const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Trợ giúp và hỗ trợ'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(TextFormField));
    await tester.enterText(
      find.byType(TextFormField),
      'Tôi cần hỗ trợ sử dụng camera.',
    );
    await tester.ensureVisible(find.text('Lưu bản nháp'));
    await tester.tap(find.text('Lưu bản nháp'));
    await tester.pumpAndSettle();
    expect(
      (await SharedPreferences.getInstance()).getString(
        'settings_support_draft',
      ),
      'Tôi cần hỗ trợ sử dụng camera.',
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Trợ giúp và hỗ trợ'));
    await tester.tap(find.text('Trợ giúp và hỗ trợ'));
    await tester.pumpAndSettle();
    expect(find.text('Tôi cần hỗ trợ sử dụng camera.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Xem huyệt từ phác đồ mở đúng huyệt kèm nhãn nhận diện', (
    tester,
  ) async {
    await tester.pumpWidget(const MultiDemoApp());
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Phác đồ điều trị bệnh'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bồi bổ, thông khí huyết'));
    await tester.pumpAndSettle();
    expect(find.text('Xem huyệt'), findsWidgets);
    await tester.tap(find.text('Xem huyệt').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Huyệt 26'), findsWidgets);
    expect(find.textContaining('Giữa hai lông mày'), findsWidgets);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Tải và xóa ảnh đại diện trên máy chủ', (tester) async {
    final id = backend.addUser();
    backend.users[id]!['avatarUpdatedAt'] = '2026-10-15T00:00:00Z';
    backend.avatars[id] = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a6XcAAAAASUVORK5CYII=',
    );
    tokens.token = backend.signIn(id);
    await tester.pumpWidget(const MultiDemoApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hồ sơ'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.add_a_photo_outlined), findsNothing);
    await tester.tap(find.bySemanticsLabel('Ảnh đại diện'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa ảnh đại diện'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Xóa ảnh'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.add_a_photo_outlined), findsOneWidget);
    expect(backend.avatars, isNot(contains(id)));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Chat cộng đồng tải tin thật và gửi tin mới', (tester) async {
    SharedPreferences.setMockInitialValues({
      'community_rules_accepted_v1': true,
      'medical_disclaimer_v1': true,
    });
    final other = backend.addUser(fullName: 'Kenji Sato', email: 'k@x.com');
    backend.messages.add({
      'id': '1',
      'body': 'Xin chào cả nhà',
      'createdAt': DateTime.now().toIso8601String(),
      'isMine': false,
      'author': {'id': other, 'fullName': 'Kenji Sato', 'country': 'Nhật Bản'},
    });
    tokens.token = backend.signIn(backend.addUser());
    await tester.pumpWidget(const MultiDemoApp());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Kết nối'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Kết nối'));
    await tester.pumpAndSettle();
    expect(find.text('Chat cộng đồng'), findsOneWidget);
    expect(find.text('Xin chào cả nhà'), findsOneWidget);
    expect(find.text('Kenji Sato · Nhật Bản'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'Chào Kenji');
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Chào Kenji'), findsOneWidget);
    expect(backend.messages.last['body'], 'Chào Kenji');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Lần mở đầu tiên hiện lưu ý sức khỏe một lần', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MultiDemoApp());
    await tester.pumpAndSettle();
    expect(find.text('Lưu ý sức khỏe'), findsOneWidget);
    await tester.tap(find.text('Tôi đã hiểu'));
    await tester.pumpAndSettle();
    expect(find.text('Lưu ý sức khỏe'), findsNothing);
    expect(
      (await SharedPreferences.getInstance()).getBool('medical_disclaimer_v1'),
      isTrue,
    );

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(const MultiDemoApp());
    await tester.pumpAndSettle();
    expect(find.text('Lưu ý sức khỏe'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Thông báo lấy từ máy chủ và đánh dấu đã đọc', (tester) async {
    backend.notifications.addAll([
      {
        'id': '2',
        'kind': 'course',
        'title': 'Đã nhận đăng ký Khóa 49 - Online',
        'body': 'Trung tâm sẽ liên hệ.',
        'createdAt': '2026-10-15T03:00:00Z',
        'read': false,
      },
      {
        'id': '1',
        'kind': 'info',
        'title': 'Chào mừng bạn đến với Diện Chẩn',
        'body': '',
        'createdAt': '2026-10-14T03:00:00Z',
        'read': true,
      },
    ]);
    tokens.token = backend.signIn(backend.addUser());
    await tester.pumpWidget(const MultiDemoApp());
    await tester.pumpAndSettle();
    expect(notificationUnreadCount.value, 1);

    await tester.tap(find.byIcon(Icons.notifications_none));
    await tester.pumpAndSettle();
    expect(find.text('Đã nhận đăng ký Khóa 49 - Online'), findsOneWidget);
    expect(find.text('Chào mừng bạn đến với Diện Chẩn'), findsOneWidget);
    expect(find.text('Chưa đọc (1)'), findsOneWidget);

    await tester.tap(find.text('Đọc tất cả'));
    await tester.pumpAndSettle();
    expect(find.text('Chưa đọc (0)'), findsOneWidget);
    expect(backend.notifications.every((n) => n['read'] == true), isTrue);
    expect(notificationUnreadCount.value, 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Khách mở thông báo được nhắc đăng nhập', (tester) async {
    await tester.pumpWidget(const MultiDemoApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.notifications_none));
    await tester.pumpAndSettle();
    expect(
      find.text('Đăng nhập để nhận thông báo khóa học và cộng đồng.'),
      findsOneWidget,
    );
    expect(backend.requests, isNot(contains('GET /me/notifications')));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Gửi yêu cầu hỗ trợ lên máy chủ', (tester) async {
    final id = await openProfile(tester);
    await tester.drag(find.byType(ListView).first, const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Trợ giúp và hỗ trợ'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(TextFormField));
    await tester.enterText(
      find.byType(TextFormField),
      'Ứng dụng không mở được camera trên máy tôi.',
    );
    await tester.ensureVisible(find.text('Gửi đến bộ phận hỗ trợ'));
    await tester.tap(find.text('Gửi đến bộ phận hỗ trợ'));
    await tester.pumpAndSettle();
    expect(backend.supportRequests.single['userId'], id);
    expect(
      backend.supportRequests.single['message'],
      'Ứng dụng không mở được camera trên máy tôi.',
    );
    expect(
      find.text('Đã gửi yêu cầu. Bộ phận hỗ trợ sẽ liên hệ lại với bạn.'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
  });
}
