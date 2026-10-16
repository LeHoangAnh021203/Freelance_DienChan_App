part of 'main.dart';

DienChanApi _api = DienChanApi();
CommunityRealtime _realtime = CommunityRealtime(_api);
final ValueNotifier<UserStats> _userStats = ValueNotifier(const UserStats());
StreamSubscription<Map<String, dynamic>>? _notificationEvents;

const _cachedUserKey = 'auth_cached_user';

/// Swaps the backend for widget tests (fake HTTP client, realtime disabled).
@visibleForTesting
void configureBackendForTesting(DienChanApi api) {
  _realtime.stop();
  _notificationEvents?.cancel();
  _notificationEvents = null;
  _api = api;
  _realtime = CommunityRealtime(api, connector: null);
}

Future<void> _restoreSession() async {
  final preferences = await SharedPreferences.getInstance();
  await _api.restoreToken();
  if (!_api.hasSession) {
    await _signOutLocally();
    return;
  }
  final cached = _readCachedUser(preferences);
  if (cached != null) {
    // Show the cached account immediately; the server copy replaces it when it arrives.
    await _setSignedIn(cached);
    unawaited(_refreshSession());
    return;
  }
  await _refreshSession();
}

ApiUser? _readCachedUser(SharedPreferences preferences) {
  final raw = preferences.get(_cachedUserKey);
  if (raw is! String) return null;
  try {
    return ApiUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  } catch (_) {
    return null;
  }
}

Future<void> _refreshSession() async {
  try {
    final (user, stats) = await _api.me();
    _userStats.value = stats;
    await _setSignedIn(user);
    unawaited(_refreshNotificationCount());
    await _loadAvatar(user);
  } on ApiException catch (error) {
    if (error.isUnauthorized) await _signOutLocally();
  }
}

Future<void> _refreshStats() async {
  if (!_api.hasSession) return;
  try {
    final (user, stats) = await _api.me();
    _userStats.value = stats;
    await _setSignedIn(user);
  } catch (_) {
    // Stats are decorative; keep the previous numbers when offline.
  }
}

Future<void> _refreshNotificationCount() async {
  if (!_api.hasSession) {
    notificationUnreadCount.value = 0;
    return;
  }
  try {
    final items = await _api.notifications();
    notificationUnreadCount.value = items.where((item) => !item.read).length;
  } catch (_) {
    // Keep the previous badge when offline.
  }
}

Future<void> _setSignedIn(ApiUser user) async {
  _currentUserProfile.value = user;
  _profileSettings.applyRemote(user.settings);
  _realtime.start();
  _notificationEvents ??= _realtime.events
      .where((event) => event['type'] == 'notification')
      .listen((_) => _refreshNotificationCount());
  try {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_cachedUserKey, jsonEncode(user.toJson()));
  } catch (_) {
    // The cache only speeds up the next launch.
  }
}

Future<void> _completeSignIn(AuthResult result) async {
  await _setSignedIn(result.user);
  unawaited(_loadAvatar(result.user));
  unawaited(_refreshStats());
  unawaited(_refreshNotificationCount());
}

Future<void> _loadAvatar(ApiUser user) async {
  if (user.avatarUpdatedAt == null) {
    _profileAvatar.value = null;
    return;
  }
  try {
    final bytes = await _api.avatar();
    if (_currentUserProfile.value?.id == user.id) _profileAvatar.value = bytes;
  } catch (_) {
    // Fall back to the placeholder icon.
  }
}

Future<void> _signOutLocally() async {
  _realtime.stop();
  _notificationEvents?.cancel();
  _notificationEvents = null;
  notificationUnreadCount.value = 0;
  await _api.clearToken();
  try {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_cachedUserKey);
  } catch (_) {}
  _currentUserProfile.value = null;
  _profileAvatar.value = null;
  _userStats.value = const UserStats();
  _profileSettings.reset();
  userFacePhotoBytes.value = null;
  userFaceAlignment.value = null;
}

Future<void> _logout() async {
  try {
    await _api.logout();
  } catch (_) {
    // The session is dropped locally even if the server is unreachable.
  }
  await _signOutLocally();
}

/// Runs [action] when signed in; otherwise opens login first.
Future<void> _requireSignIn(
  BuildContext context,
  Future<void> Function() action,
) async {
  if (_currentUserProfile.value == null) {
    await _openLoginPage(context);
    if (_currentUserProfile.value == null || !context.mounted) return;
  }
  await action();
}

void _showApiError(BuildContext context, Object error) {
  final message = error is ApiException
      ? error.message
      : 'Có lỗi xảy ra. Vui lòng thử lại.';
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
