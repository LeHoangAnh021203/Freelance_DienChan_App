part of 'main.dart';

final _appMessenger = GlobalKey<ScaffoldMessengerState>();
final _profileSettings = _ProfileSettings();

class _ProfileSettings extends ChangeNotifier {
  bool reminders = false;
  int minute = 7 * 60;
  String lastReminder = '';
  String draft = '';

  Future<void> load(SharedPreferences preferences) async {
    reminders = preferences.getBool('settings_reminders') ?? false;
    minute = (preferences.getInt('settings_reminder_minute') ?? 420).clamp(
      0,
      1439,
    );
    lastReminder = preferences.getString('settings_last_reminder') ?? '';
    draft = preferences.getString('settings_support_draft') ?? '';
    notifyListeners();
  }

  Future<void> saveReminder(bool enabled, int time) async {
    final preferences = await SharedPreferences.getInstance();
    // One record prevents a partially saved schedule.
    final saved = await preferences.setString(
      'settings_schedule',
      jsonEncode({'enabled': enabled, 'minute': time}),
    );
    if (!saved) throw StateError('Không lưu được lịch');
    reminders = enabled;
    minute = time;
    notifyListeners();
  }

  Future<void> restoreSchedule() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString('settings_schedule');
    if (raw == null) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      reminders = data['enabled'] == true;
      minute = (data['minute'] as int).clamp(0, 1439);
      notifyListeners();
    } catch (_) {
      reminders = false;
    }
  }
}

bool _checkingReminder = false;
Future<void> _checkReminder() async {
  if (_checkingReminder ||
      _currentUserProfile.value == null ||
      !_profileSettings.reminders) {
    return;
  }
  final now = DateTime.now();
  final date = '${now.year}-${now.month}-${now.day}';
  if (now.hour * 60 + now.minute != _profileSettings.minute ||
      _profileSettings.lastReminder == date) {
    return;
  }
  _checkingReminder = true;
  try {
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.setString('settings_last_reminder', date)) return;
    _profileSettings.lastReminder = date;
    _appMessenger.currentState?.showSnackBar(
      const SnackBar(
        content: Text('Đến giờ tự chăm sóc bạn đã đặt. Mở phác đồ để bắt đầu.'),
        duration: Duration(seconds: 12),
      ),
    );
  } catch (_) {
    // Retry on the next tick if device storage is temporarily unavailable.
  } finally {
    _checkingReminder = false;
  }
}

void _openSettingsPage(BuildContext context, Widget page) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
}

Future<void> _editProfile(BuildContext context, _AppUserProfile profile) async {
  await Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (pageContext) => _ProfileLoginPage(
        initialProfile: profile,
        onCompleted: (updated) async {
          await _AuthGateState._saveProfile(updated);
          if (pageContext.mounted) Navigator.pop(pageContext);
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Đã cập nhật hồ sơ.')));
          }
        },
      ),
    ),
  );
}

class _PrivacyPage extends StatefulWidget {
  const _PrivacyPage({required this.onLogout});
  final Future<void> Function() onLogout;
  @override
  State<_PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<_PrivacyPage> {
  bool _busy = false;

  Future<void> _clearData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa dữ liệu cá nhân trên thiết bị?'),
        content: const Text(
          'Hồ sơ, ảnh khuôn mặt, lịch nhắc và bản nháp hỗ trợ sẽ bị xóa. Bạn sẽ chuyển sang chế độ khách. Thao tác này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa dữ liệu'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final preferences = await SharedPreferences.getInstance();
      for (final key in [
        'settings_schedule',
        'settings_last_reminder',
        'settings_support_draft',
        'settings_reminders',
        'settings_reminder_minute',
      ]) {
        if (!await preferences.remove(key)) {
          throw StateError('Không xóa được dữ liệu');
        }
      }
      await _profileSettings.load(preferences);
      await widget.onLogout();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chưa xóa hết dữ liệu. Vui lòng thử lại.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Bảo mật và riêng tư')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Hồ sơ được lưu trên trình duyệt hoặc thiết bị này. Phiên bản hiện tại chưa có tài khoản xác thực, mật khẩu, OTP hoặc đồng bộ dữ liệu giữa các thiết bị.',
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Dữ liệu khuôn mặt',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const Text(
          'Ảnh chụp được giữ trong phiên sử dụng để đặt huyệt. Bạn có thể xóa ảnh bất kỳ lúc nào.',
        ),
        ValueListenableBuilder<Uint8List?>(
          valueListenable: userFacePhotoBytes,
          builder: (context, photo, _) => OutlinedButton.icon(
            onPressed: photo == null
                ? null
                : () {
                    userFacePhotoBytes.value = null;
                    userFaceAlignment.value = null;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã xóa ảnh khuôn mặt.')),
                    );
                  },
            icon: const Icon(Icons.delete_outline),
            label: Text(
              photo == null ? 'Không có ảnh khuôn mặt' : 'Xóa ảnh khuôn mặt',
            ),
          ),
        ),
        const Divider(height: 32),
        const Text(
          'Xóa dữ liệu cục bộ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const Text(
          'Xóa hồ sơ, ảnh, lịch nhắc và bản nháp hỗ trợ khỏi thiết bị này.',
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFB91C1C),
          ),
          onPressed: _busy ? null : _clearData,
          icon: const Icon(Icons.delete_forever),
          label: Text(_busy ? 'Đang xóa...' : 'Xóa dữ liệu cá nhân'),
        ),
      ],
    ),
  );
}

class _ReminderSettingsPage extends StatefulWidget {
  const _ReminderSettingsPage();
  @override
  State<_ReminderSettingsPage> createState() => _ReminderSettingsPageState();
}

class _ReminderSettingsPageState extends State<_ReminderSettingsPage> {
  bool _busy = false;
  Future<void> _save(bool enabled, int minute) async {
    setState(() => _busy = true);
    try {
      await _profileSettings.saveReminder(enabled, minute);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu cài đặt nhắc giờ.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không lưu được cài đặt. Vui lòng thử lại.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Cài đặt thông báo')),
    body: ListenableBuilder(
      listenable: _profileSettings,
      builder: (context, _) {
        final time = TimeOfDay(
          hour: _profileSettings.minute ~/ 60,
          minute: _profileSettings.minute % 60,
        );
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Nhắc giờ chỉ hiển thị khi ứng dụng đang mở và bạn đã đăng nhập. Không gửi thông báo khi đóng ứng dụng. Giờ nhắc theo giờ trên thiết bị.',
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Nhắc tự chăm sóc hằng ngày'),
              value: _profileSettings.reminders,
              onChanged: _busy
                  ? null
                  : (value) => _save(value, _profileSettings.minute),
            ),
            ListTile(
              title: const Text('Giờ nhắc'),
              subtitle: Text(time.format(context)),
              trailing: const Icon(Icons.schedule),
              enabled: !_busy && _profileSettings.reminders,
              onTap: () async {
                final selected = await showTimePicker(
                  context: context,
                  initialTime: time,
                );
                if (selected != null && mounted) {
                  await _save(true, selected.hour * 60 + selected.minute);
                }
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: !_profileSettings.reminders || _busy
                  ? null
                  : () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Nhắc thử: Đến giờ tự chăm sóc bạn đã đặt.',
                        ),
                      ),
                    ),
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text('Thử thông báo'),
            ),
          ],
        );
      },
    ),
  );
}

class _HelpPage extends StatefulWidget {
  const _HelpPage();
  @override
  State<_HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<_HelpPage> {
  final _controller = TextEditingController(text: _profileSettings.draft);
  final _formKey = GlobalKey<FormState>();
  bool _busy = false;
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveDraft() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final text = _controller.text.trim();
      final preferences = await SharedPreferences.getInstance();
      if (!await preferences.setString('settings_support_draft', text)) {
        throw StateError('Không lưu được');
      }
      _profileSettings.draft = text;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Đã lưu bản nháp trên thiết bị. Chưa gửi đến bộ phận hỗ trợ.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không lưu được bản nháp. Vui lòng thử lại.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Trợ giúp và hỗ trợ')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const ExpansionTile(
          title: Text('Tôi có thể dùng app khi chưa đăng nhập?'),
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Bạn có thể xem trang chủ và tra cứu. Mở Hồ sơ hoặc Kết nối để đăng ký / đăng nhập khi cần.',
              ),
            ),
          ],
        ),
        const ExpansionTile(
          title: Text('Làm sao thay đổi thông tin cá nhân?'),
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Vào Hồ sơ → Chỉnh sửa hồ sơ, cập nhật thông tin rồi bấm Lưu thay đổi.',
              ),
            ),
          ],
        ),
        const ExpansionTile(
          title: Text('Vì sao tôi không nhận được nhắc giờ?'),
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Bật nhắc trong Hồ sơ → Thông báo và chọn giờ. Giữ app mở ở giờ đã chọn. Nhắc giờ tạm dừng khi đăng xuất hoặc đóng app.',
              ),
            ),
          ],
        ),
        const ExpansionTile(
          title: Text('Dữ liệu của tôi được lưu ở đâu?'),
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Dữ liệu được lưu trên thiết bị hiện tại. Xóa dữ liệu trình duyệt có thể làm mất hồ sơ. Chưa có đồng bộ sang thiết bị khác.',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Nội dung cần hỗ trợ',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Chưa có kênh tiếp nhận hỗ trợ được cấu hình. Bạn có thể lưu bản nháp hoặc sao chép nội dung để gửi qua kênh liên hệ của mình.',
        ),
        const SizedBox(height: 12),
        Form(
          key: _formKey,
          child: TextFormField(
            controller: _controller,
            maxLines: 5,
            maxLength: 2000,
            decoration: const InputDecoration(
              labelText: 'Mô tả vấn đề',
              hintText: 'Bạn gặp vấn đề ở màn hình nào? Các bước thực hiện...',
              border: OutlineInputBorder(),
            ),
            validator: (value) => (value?.trim().length ?? 0) < 10
                ? 'Vui lòng mô tả ít nhất 10 ký tự'
                : null,
          ),
        ),
        FilledButton(
          onPressed: _busy ? null : _saveDraft,
          child: Text(_busy ? 'Đang lưu...' : 'Lưu bản nháp'),
        ),
        OutlinedButton.icon(
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            try {
              await Clipboard.setData(
                ClipboardData(text: _controller.text.trim()),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã sao chép nội dung hỗ trợ.')),
                );
              }
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Không sao chép được. Bạn có thể chọn và sao chép nội dung trực tiếp.',
                    ),
                  ),
                );
              }
            }
          },
          icon: const Icon(Icons.copy),
          label: const Text('Sao chép nội dung'),
        ),
      ],
    ),
  );
}

final _profileAvatar = ValueNotifier<Uint8List?>(null);

Future<void> _restoreAvatar(
  SharedPreferences preferences,
  bool signedIn,
) async {
  _profileAvatar.value = null;
  final stored = preferences.getString('profile_avatar');
  if (!signedIn || stored == null) return;
  try {
    final bytes = base64Decode(stored);
    final codec = await instantiateImageCodec(bytes);
    codec.dispose();
    _profileAvatar.value = bytes;
  } catch (_) {
    // A damaged local image must not prevent opening the app.
  }
}

class _ProfileAvatarEditor extends StatefulWidget {
  const _ProfileAvatarEditor();

  @override
  State<_ProfileAvatarEditor> createState() => _ProfileAvatarEditorState();
}

class _ProfileAvatarEditorState extends State<_ProfileAvatarEditor> {
  bool _busy = false;

  Future<void> _changeAvatar() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(
                _profileAvatar.value == null
                    ? 'Thêm ảnh đại diện'
                    : 'Chọn ảnh đại diện mới',
              ),
              onTap: () => Navigator.pop(context, 'choose'),
            ),
            if (_profileAvatar.value != null)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Xóa ảnh đại diện'),
                onTap: () => Navigator.pop(context, 'remove'),
              ),
            ListTile(
              title: const Text('Hủy'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;
    final owner = _currentUserProfile.value;
    setState(() => _busy = true);
    try {
      Uint8List? bytes;
      if (action == 'choose') {
        final file = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          maxWidth: 512,
          maxHeight: 512,
          imageQuality: 85,
        );
        if (file == null) return;
        if (await file.length() > 10 * 1024 * 1024) {
          throw StateError('Ảnh quá lớn');
        }
        final original = await file.readAsBytes();
        final codec = await instantiateImageCodec(original, targetWidth: 384);
        try {
          final frame = await codec.getNextFrame();
          try {
            bytes = (await frame.image.toByteData(
              format: ImageByteFormat.png,
            ))?.buffer.asUint8List();
          } finally {
            frame.image.dispose();
          }
        } finally {
          codec.dispose();
        }
        if (bytes == null || bytes.length > 2 * 1024 * 1024) {
          throw StateError('Ảnh không phù hợp');
        }
      }
      if (!mounted || owner != _currentUserProfile.value || owner == null) {
        return;
      }
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            action == 'remove' ? 'Xóa ảnh đại diện?' : 'Xem trước ảnh đại diện',
          ),
          content: action == 'remove'
              ? const Text('Ảnh đại diện sẽ trở về biểu tượng mặc định.')
              : SizedBox(
                  height: 180,
                  width: 180,
                  child: Center(
                    child: ClipOval(
                      child: Image.memory(
                        bytes!,
                        width: 160,
                        height: 160,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(action == 'remove' ? 'Xóa ảnh' : 'Lưu ảnh'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted || owner != _currentUserProfile.value) {
        return;
      }
      final preferences = await SharedPreferences.getInstance();
      final success = bytes == null
          ? await preferences.remove('profile_avatar')
          : await preferences.setString('profile_avatar', base64Encode(bytes));
      if (!success) throw StateError('Không lưu được ảnh');
      _profileAvatar.value = bytes;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              bytes == null
                  ? 'Đã xóa ảnh đại diện.'
                  : 'Đã cập nhật ảnh đại diện.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Không cập nhật được ảnh. Hãy chọn ảnh JPG/PNG dưới 10 MB và thử lại.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<_AppUserProfile?>(
        valueListenable: _currentUserProfile,
        builder: (context, profile, _) => ValueListenableBuilder<Uint8List?>(
          valueListenable: _profileAvatar,
          builder: (context, bytes, _) => Column(
            children: [
              Semantics(
                label: 'Ảnh đại diện',
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: profile == null || _busy ? null : _changeAvatar,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: const Color(0xFF2B5E47),
                    child: _busy
                        ? const CircularProgressIndicator(color: Colors.white)
                        : profile != null && bytes != null
                        ? ClipOval(
                            child: Image.memory(
                              bytes,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(
                            profile == null
                                ? Icons.person_rounded
                                : Icons.add_a_photo_outlined,
                            size: profile == null ? 38 : 26,
                            color: Colors.white,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

void _showCommunityMember(BuildContext context, _OnlineUser member) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Thông tin thành viên'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: const Color(0xFFE9D8CA),
              foregroundColor: const Color(0xFF7A3F2C),
              child: Text(
                member.name.isEmpty ? '?' : member.name.characters.first,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              member.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.public, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text('Quốc gia: ${member.country}')),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Cộng đồng Diện Chẩn',
              style: TextStyle(color: Color(0xFF8A6E5C)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
      ],
    ),
  );
}
