part of 'main.dart';

final _appMessenger = GlobalKey<ScaffoldMessengerState>();
final _profileSettings = _ProfileSettings();

class _ProfileSettings extends ChangeNotifier {
  bool reminders = false;
  int minute = 7 * 60;
  String lastReminder = '';
  String draft = '';

  void loadLocal(SharedPreferences preferences) {
    final last = preferences.get('settings_last_reminder');
    final savedDraft = preferences.get('settings_support_draft');
    lastReminder = last is String ? last : '';
    draft = savedDraft is String ? savedDraft : '';
    notifyListeners();
  }

  void applyRemote(UserSettings settings) {
    reminders = settings.reminders;
    minute = settings.reminderMinute;
    notifyListeners();
  }

  void reset() {
    reminders = false;
    minute = 7 * 60;
    notifyListeners();
  }

  Future<void> saveReminder(bool enabled, int time) async {
    final saved = await _api.saveSettings(
      UserSettings(reminders: enabled, reminderMinute: time),
    );
    applyRemote(saved);
    final user = _currentUserProfile.value;
    if (user != null) await _setSignedIn(user.copyWith(settings: saved));
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

Future<void> _editProfile(BuildContext context, ApiUser profile) async {
  await Navigator.of(context).push<void>(
    MaterialPageRoute(builder: (_) => _ProfileFormPage(user: profile)),
  );
}

class _PrivacyPage extends StatefulWidget {
  const _PrivacyPage();
  @override
  State<_PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<_PrivacyPage> {
  bool _busy = false;

  Future<void> _changePassword(ApiUser user) async {
    final result = await showDialog<({String current, String next})>(
      context: context,
      builder: (_) => _PasswordDialog(
        title: user.hasPassword ? 'Đổi mật khẩu' : 'Tạo mật khẩu',
        currentLabel: user.hasPassword ? 'Mật khẩu hiện tại' : null,
        askNewPassword: true,
        confirmLabel: 'Lưu',
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await _api.changePassword(
        currentPassword: user.hasPassword ? result.current : null,
        newPassword: result.next,
      );
      await _refreshStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Đã lưu mật khẩu. Các thiết bị khác đã được đăng xuất.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) _showApiError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteAccount(ApiUser user) async {
    final result = await showDialog<({String current, String next})>(
      context: context,
      builder: (_) => _PasswordDialog(
        title: 'Xóa tài khoản vĩnh viễn?',
        message:
            'Hồ sơ, ảnh đại diện, nhật ký, mục đã lưu, tin nhắn cộng đồng và đăng ký khóa học của bạn sẽ bị xóa khỏi máy chủ. Thao tác này không thể hoàn tác.',
        currentLabel: user.hasPassword ? 'Nhập mật khẩu để xác nhận' : null,
        confirmLabel: 'Xóa tài khoản',
        danger: true,
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await _api.deleteAccount(
        password: user.hasPassword ? result.current : null,
      );
      await _signOutLocally();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã xóa tài khoản.')));
      Navigator.pop(context);
    } catch (error) {
      if (mounted) _showApiError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Bảo mật và riêng tư')),
    body: ValueListenableBuilder<ApiUser?>(
      valueListenable: _currentUserProfile,
      builder: (context, user, _) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                user == null
                    ? 'Bạn chưa đăng nhập.'
                    : 'Tài khoản: ${user.email.isEmpty ? 'Apple ID (ẩn email)' : user.email}\n'
                          'Đăng nhập bằng: ${[if (user.hasPassword) 'Email và mật khẩu', if (user.appleLinked) 'Apple'].join(', ')}\n\n'
                          'Hồ sơ, nhật ký, mục đã lưu và cài đặt được lưu trên máy chủ theo tài khoản. Ảnh khuôn mặt dùng để đặt huyệt chỉ nằm trên thiết bị này.',
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Dữ liệu khuôn mặt',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const Text(
            'Ảnh chụp được giữ trong phiên sử dụng để đặt huyệt và không gửi lên máy chủ.',
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
          if (user != null) ...[
            const Divider(height: 32),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.password_rounded),
              title: Text(user.hasPassword ? 'Đổi mật khẩu' : 'Tạo mật khẩu'),
              subtitle: Text(
                user.hasPassword
                    ? 'Đăng xuất các thiết bị khác sau khi đổi'
                    : 'Để đăng nhập bằng email ngoài Apple',
              ),
              enabled: !_busy && (user.hasPassword || user.email.isNotEmpty),
              onTap: () => _changePassword(user),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.block_rounded),
              title: const Text('Thành viên đã chặn'),
              subtitle: const Text('Bỏ chặn để xem lại tin nhắn của họ'),
              onTap: () =>
                  _openSettingsPage(context, const _BlockedMembersPage()),
            ),
            const Divider(height: 32),
            const Text(
              'Xóa tài khoản',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const Text(
              'Xóa vĩnh viễn tài khoản và toàn bộ dữ liệu liên quan trên máy chủ.',
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB91C1C),
              ),
              onPressed: _busy ? null : () => _deleteAccount(user),
              icon: const Icon(Icons.delete_forever),
              label: Text(_busy ? 'Đang xử lý...' : 'Xóa tài khoản'),
            ),
          ],
        ],
      ),
    ),
  );
}

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog({
    required this.title,
    required this.confirmLabel,
    this.message,
    this.currentLabel,
    this.askNewPassword = false,
    this.danger = false,
  });

  final String title;
  final String confirmLabel;
  final String? message;

  /// Label of the existing-password field; null hides it.
  final String? currentLabel;
  final bool askNewPassword;
  final bool danger;

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.message != null) ...[
                Text(widget.message!),
                const SizedBox(height: 12),
              ],
              if (widget.currentLabel != null)
                TextFormField(
                  controller: _currentController,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(labelText: widget.currentLabel),
                  validator: (value) =>
                      (value ?? '').isEmpty ? 'Vui lòng nhập mật khẩu' : null,
                ),
              if (widget.askNewPassword)
                TextFormField(
                  controller: _newController,
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
                  validator: _validateNewPassword,
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          style: widget.danger
              ? FilledButton.styleFrom(backgroundColor: const Color(0xFFB91C1C))
              : null,
          onPressed: () {
            if (!(_formKey.currentState?.validate() ?? false)) return;
            Navigator.pop(context, (
              current: _currentController.text,
              next: _newController.text,
            ));
          },
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

class _BlockedMembersPage extends StatefulWidget {
  const _BlockedMembersPage();

  @override
  State<_BlockedMembersPage> createState() => _BlockedMembersPageState();
}

class _BlockedMembersPageState extends State<_BlockedMembersPage> {
  late Future<List<CommunityMember>> _future = _api.blockedUsers();

  Future<void> _unblock(CommunityMember member) async {
    try {
      await _api.unblockUser(member.id);
      setState(() => _future = _api.blockedUsers());
    } catch (error) {
      if (mounted) _showApiError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Thành viên đã chặn')),
    body: FutureBuilder<List<CommunityMember>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }
        final members = snapshot.data!;
        if (members.isEmpty) {
          return const Center(child: Text('Bạn chưa chặn thành viên nào.'));
        }
        return ListView.builder(
          itemCount: members.length,
          itemBuilder: (context, index) {
            final member = members[index];
            return ListTile(
              title: Text(member.fullName),
              subtitle: Text(member.country),
              trailing: TextButton(
                onPressed: () => _unblock(member),
                child: const Text('Bỏ chặn'),
              ),
            );
          },
        );
      },
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
    } catch (error) {
      if (mounted) _showApiError(context, error);
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
              'Cài đặt được lưu theo tài khoản. Nhắc giờ hiển thị khi ứng dụng đang mở và bạn đã đăng nhập; chưa gửi thông báo khi đóng ứng dụng. Giờ nhắc theo giờ trên thiết bị.',
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
  final _contactController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _busy = false;
  bool _sending = false;
  @override
  void dispose() {
    _controller.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      await _api.sendSupportRequest(
        _controller.text.trim(),
        contact: _currentUserProfile.value == null
            ? _contactController.text.trim()
            : null,
      );
      _controller.clear();
      _profileSettings.draft = '';
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove('settings_support_draft');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Đã gửi yêu cầu. Bộ phận hỗ trợ sẽ liên hệ lại với bạn.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) _showApiError(context, error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
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
                'Bạn có thể xem trang chủ, tra cứu và đăng ký khóa học. Đăng nhập để chat cộng đồng, lưu nhật ký và mục yêu thích.',
              ),
            ),
          ],
        ),
        const ExpansionTile(
          title: Text('Tôi quên mật khẩu thì làm sao?'),
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Ở màn Đăng nhập, bấm "Quên mật khẩu?", nhập email để nhận mã 6 số rồi đặt mật khẩu mới.',
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
                'Hồ sơ, nhật ký, mục đã lưu và cài đặt được lưu trên máy chủ theo tài khoản, nên đăng nhập ở thiết bị khác vẫn thấy đủ. Bạn có thể xóa tài khoản trong Hồ sơ → Bảo mật và riêng tư.',
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
          'Gửi yêu cầu trực tiếp tại đây, hoặc liên hệ $_hotlineDisplay, Facebook "Buiminhtam dien chan".',
        ),
        const SizedBox(height: 12),
        Form(
          key: _formKey,
          child: Column(
            children: [
              if (_currentUserProfile.value == null) ...[
                TextFormField(
                  controller: _contactController,
                  decoration: const InputDecoration(
                    labelText: 'Email hoặc số điện thoại liên hệ',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value?.trim().length ?? 0) < 5
                      ? 'Vui lòng nhập email hoặc số điện thoại'
                      : null,
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _controller,
                maxLines: 5,
                maxLength: 2000,
                decoration: const InputDecoration(
                  labelText: 'Mô tả vấn đề',
                  hintText:
                      'Bạn gặp vấn đề ở màn hình nào? Các bước thực hiện...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value?.trim().length ?? 0) < 10
                    ? 'Vui lòng mô tả ít nhất 10 ký tự'
                    : null,
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: _sending ? null : _send,
          icon: const Icon(Icons.send_rounded),
          label: Text(_sending ? 'Đang gửi...' : 'Gửi đến bộ phận hỗ trợ'),
        ),
        TextButton(
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
        const SizedBox(height: 20),
        const _LegalLinksCard(),
      ],
    ),
  );
}

final _profileAvatar = ValueNotifier<Uint8List?>(null);

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
    final ownerId = _currentUserProfile.value?.id;
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
      if (!mounted || ownerId == null) return;
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
      if (confirmed != true ||
          !mounted ||
          ownerId != _currentUserProfile.value?.id) {
        return;
      }
      final updated = bytes == null
          ? await _api.deleteAvatar()
          : await _api.uploadAvatar(bytes);
      await _setSignedIn(updated);
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
    } on ApiException catch (error) {
      if (mounted) _showApiError(context, error);
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
  Widget build(BuildContext context) => ValueListenableBuilder<ApiUser?>(
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
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                          ),
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

/// Returns true when the viewer blocked [member].
Future<bool> _showCommunityMember(
  BuildContext context,
  CommunityMember member,
) async {
  final isMe = member.id == _currentUserProfile.value?.id;
  final action = await showDialog<String>(
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
                member.fullName.isEmpty
                    ? '?'
                    : member.fullName.characters.first,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isMe ? '${member.fullName} (bạn)' : member.fullName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.public, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Quốc gia: ${member.country.isEmpty ? 'Chưa cập nhật' : member.country}',
                  ),
                ),
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
        if (!isMe)
          TextButton(
            onPressed: () => Navigator.pop(context, 'block'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFB91C1C),
            ),
            child: const Text('Chặn'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
      ],
    ),
  );
  if (action != 'block' || !context.mounted) return false;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Chặn ${member.fullName}?'),
      content: const Text(
        'Bạn và thành viên này sẽ không thấy tin nhắn của nhau trong cộng đồng. Có thể bỏ chặn trong Hồ sơ → Bảo mật và riêng tư.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Chặn'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return false;
  try {
    await _api.blockUser(member.id);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Đã chặn ${member.fullName}.')));
    }
    return true;
  } catch (error) {
    if (context.mounted) _showApiError(context, error);
    return false;
  }
}
