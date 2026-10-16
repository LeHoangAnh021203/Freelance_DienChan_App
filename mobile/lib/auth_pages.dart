part of 'main.dart';

const _appleServiceId = String.fromEnvironment('APPLE_SERVICE_ID');
const _appleRedirectUri = String.fromEnvironment('APPLE_REDIRECT_URI');

const _authAccent = Color(0xFFB55238);
const _authFill = Color(0xFFFFF7ED);

const _countries = [
  'Việt Nam',
  'Hoa Kỳ',
  'Canada',
  'Úc',
  'Nhật Bản',
  'Hàn Quốc',
  'Singapore',
  'Thái Lan',
  'Pháp',
  'Đức',
  'Quốc gia khác',
];

bool get _appleSignInSupported {
  if (kIsWeb) return _appleServiceId.isNotEmpty && _appleRedirectUri.isNotEmpty;
  return defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;
}

Future<void> _openLoginPage(BuildContext context) async {
  final user = await Navigator.of(
    context,
  ).push<ApiUser>(MaterialPageRoute(builder: (_) => const _AuthPage()));
  if (user == null || !user.needsProfile || !context.mounted) return;
  await Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => _ProfileFormPage(user: user, completing: true),
    ),
  );
}

class _SignInPrompt extends StatelessWidget {
  const _SignInPrompt({
    this.message = 'Đăng nhập để tham gia cộng đồng Diện Chẩn.',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      heightFactor: 1,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _openLoginPage(context),
              icon: const Icon(Icons.login_rounded),
              label: const Text('Đăng ký / Đăng nhập'),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _authInputDecoration({
  required String label,
  String? hint,
  required IconData icon,
  Widget? suffix,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: Icon(icon, color: _authAccent),
    suffixIcon: suffix,
    labelStyle: const TextStyle(
      color: _authAccent,
      fontWeight: FontWeight.w600,
    ),
    filled: true,
    fillColor: _authFill,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: _authAccent.withValues(alpha: 0.28)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: _authAccent.withValues(alpha: 0.36)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _authAccent, width: 1.8),
    ),
  );
}

String? _validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Vui lòng nhập email';
  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(email)) {
    return 'Email chưa đúng định dạng';
  }
  return null;
}

String? _validateNewPassword(String? value) {
  if ((value ?? '').length < 8) return 'Mật khẩu cần ít nhất 8 ký tự';
  return null;
}

String? _validateFullName(String? value) {
  final name = value?.trim() ?? '';
  if (name.isEmpty) return 'Vui lòng nhập họ tên';
  if (name.length < 2) return 'Họ tên cần có ít nhất 2 ký tự';
  return null;
}

String? _validateOptionalPhone(String? value) {
  final phone = (value ?? '').replaceAll(RegExp(r'[\s().-]'), '');
  if (phone.isEmpty) return null;
  if (!RegExp(r'^\+?[0-9]{8,15}$').hasMatch(phone)) {
    return 'Số điện thoại chưa đúng định dạng';
  }
  return null;
}

class _AuthScaffold extends StatelessWidget {
  const _AuthScaffold({
    required this.title,
    required this.heading,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String heading;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF1E6),
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFCF9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFF3C9A9)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x339A3412),
                      blurRadius: 28,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFFF3C9A9)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          'assets/images/intro_dien_chan_logo.jpg',
                          fit: BoxFit.cover,
                          semanticLabel: 'Logo Diện Chẩn',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      heading,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF651B16),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF8A4B35),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 22),
                    ...children,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthSubmitButton extends StatelessWidget {
  const _AuthSubmitButton({
    required this.label,
    required this.busy,
    required this.onPressed,
    this.icon = Icons.login_rounded,
  });

  final String label;
  final bool busy;
  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: _authAccent,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFD6A08B),
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
          : Icon(icon),
      label: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _PasswordField extends StatefulWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    this.validator,
    this.newPassword = false,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String>? validator;
  final bool newPassword;
  final VoidCallback? onSubmitted;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _hidden,
      autofillHints: [
        widget.newPassword ? AutofillHints.newPassword : AutofillHints.password,
      ],
      validator:
          widget.validator ??
          (value) => (value ?? '').isEmpty ? 'Vui lòng nhập mật khẩu' : null,
      onFieldSubmitted: (_) => widget.onSubmitted?.call(),
      decoration: _authInputDecoration(
        label: widget.label,
        icon: Icons.lock_outline_rounded,
        suffix: IconButton(
          tooltip: _hidden ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
          onPressed: () => setState(() => _hidden = !_hidden),
          icon: Icon(
            _hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          ),
        ),
      ),
    );
  }
}

class _CountryField extends StatelessWidget {
  const _CountryField({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: _countries.contains(value) ? value : _countries.first,
      decoration: _authInputDecoration(
        label: 'Quốc gia',
        icon: Icons.public_rounded,
      ),
      items: _countries
          .map(
            (country) => DropdownMenuItem(value: country, child: Text(country)),
          )
          .toList(),
      onChanged: (country) {
        if (country != null) onChanged(country);
      },
    );
  }
}

class _AuthPage extends StatefulWidget {
  const _AuthPage();

  @override
  State<_AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<_AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _country = _countries.first;
  bool _registering = false;
  bool _busy = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<AuthResult> Function() action) async {
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final result = await action();
      await _completeSignIn(result);
      if (mounted) Navigator.of(context).pop(result.user);
    } catch (error) {
      if (mounted) _showApiError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;
    _run(
      () => _registering
          ? _api.register(
              email: email,
              password: password,
              fullName: _nameController.text.trim(),
              phone: _phoneController.text.trim(),
              country: _country,
            )
          : _api.login(email: email, password: password),
    );
  }

  Future<void> _signInWithApple() async {
    final rawNonce = generateNonce();
    final AuthorizationCredentialAppleID credential;
    try {
      credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: sha256OfString(rawNonce),
        webAuthenticationOptions: kIsWeb
            ? WebAuthenticationOptions(
                clientId: _appleServiceId,
                redirectUri: Uri.parse(_appleRedirectUri),
              )
            : null,
      );
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code != AuthorizationErrorCode.canceled && mounted) {
        _showApiError(
          context,
          const ApiException('Đăng nhập Apple không thành công.'),
        );
      }
      return;
    } catch (_) {
      if (mounted) {
        _showApiError(
          context,
          const ApiException('Thiết bị chưa hỗ trợ đăng nhập Apple.'),
        );
      }
      return;
    }
    final identityToken = credential.identityToken;
    if (identityToken == null) return;
    // Vietnamese order: family name first.
    final fullName = [
      credential.familyName,
      credential.givenName,
    ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' ');
    await _run(
      () => _api.signInWithApple(
        identityToken: identityToken,
        rawNonce: rawNonce,
        authorizationCode: credential.authorizationCode,
        fullName: fullName.isEmpty ? null : fullName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(
      title: 'Đăng ký / Đăng nhập',
      heading: 'Chào mừng đến với Diện Chẩn',
      subtitle: _registering
          ? 'Tạo tài khoản để lưu hồ sơ, nhật ký và tham gia cộng đồng.'
          : 'Đăng nhập để đồng bộ dữ liệu trên mọi thiết bị.',
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Đăng nhập')),
            ButtonSegment(value: true, label: Text('Đăng ký')),
          ],
          selected: {_registering},
          showSelectedIcon: false,
          onSelectionChanged: _busy
              ? null
              : (value) => setState(() => _registering = value.first),
        ),
        const SizedBox(height: 18),
        AutofillGroup(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_registering) ...[
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.name],
                    validator: _validateFullName,
                    decoration: _authInputDecoration(
                      label: 'Họ và tên',
                      hint: 'Nguyễn Văn An',
                      icon: Icons.person_outline_rounded,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: _validateEmail,
                  decoration: _authInputDecoration(
                    label: 'Email',
                    hint: 'tenban@gmail.com',
                    icon: Icons.mail_outline_rounded,
                  ),
                ),
                const SizedBox(height: 14),
                _PasswordField(
                  controller: _passwordController,
                  label: 'Mật khẩu',
                  newPassword: _registering,
                  validator: _registering ? _validateNewPassword : null,
                  onSubmitted: _registering ? null : _submit,
                ),
                if (_registering) ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    validator: _validateOptionalPhone,
                    decoration: _authInputDecoration(
                      label: 'Số điện thoại (không bắt buộc)',
                      hint: '0901 234 567',
                      icon: Icons.phone_outlined,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _CountryField(
                    value: _country,
                    onChanged: (country) => setState(() => _country = country),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (!_registering)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _busy
                  ? null
                  : () async {
                      final user = await Navigator.of(context).push<ApiUser>(
                        MaterialPageRoute(
                          builder: (_) => _ForgotPasswordPage(
                            initialEmail: _emailController.text.trim(),
                          ),
                        ),
                      );
                      if (user != null && context.mounted) {
                        Navigator.of(context).pop(user);
                      }
                    },
              child: const Text('Quên mật khẩu?'),
            ),
          )
        else
          const SizedBox(height: 18),
        _AuthSubmitButton(
          label: _busy
              ? 'Đang xử lý...'
              : _registering
              ? 'Tạo tài khoản'
              : 'Đăng nhập',
          busy: _busy,
          onPressed: _submit,
        ),
        if (_appleSignInSupported) ...[
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text('hoặc', style: TextStyle(color: Color(0xFF9A6654))),
              ),
              Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: SignInWithAppleButton(
              text: 'Tiếp tục với Apple',
              onPressed: _busy ? () {} : _signInWithApple,
              borderRadius: const BorderRadius.all(Radius.circular(14)),
            ),
          ),
        ],
        const SizedBox(height: 14),
        const Text(
          'Tài khoản và dữ liệu được lưu an toàn trên máy chủ, dùng chung trên mọi thiết bị bạn đăng nhập.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF9A6654),
            fontSize: 12,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text(
              'Khi tiếp tục, bạn đồng ý với',
              style: TextStyle(color: Color(0xFF9A6654), fontSize: 12),
            ),
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(fontSize: 12),
              ),
              onPressed: () => _openExternal(context, _legalUri('/terms')),
              child: const Text('Điều khoản'),
            ),
            const Text(
              'và',
              style: TextStyle(color: Color(0xFF9A6654), fontSize: 12),
            ),
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(fontSize: 12),
              ),
              onPressed: () => _openExternal(context, _legalUri('/privacy')),
              child: const Text('Chính sách quyền riêng tư'),
            ),
          ],
        ),
      ],
    );
  }
}

class _ForgotPasswordPage extends StatefulWidget {
  const _ForgotPasswordPage({this.initialEmail = ''});

  final String initialEmail;

  @override
  State<_ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<_ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  late final _emailController = TextEditingController(
    text: widget.initialEmail,
  );
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      await _api.forgotPassword(_emailController.text.trim().toLowerCase());
      if (!mounted) return;
      setState(() => _codeSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nếu email đã đăng ký, mã xác nhận 6 số đã được gửi. Hãy kiểm tra cả thư rác.',
          ),
        ),
      );
    } catch (error) {
      if (mounted) _showApiError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      final result = await _api.resetPassword(
        email: _emailController.text.trim().toLowerCase(),
        code: _codeController.text.trim(),
        password: _passwordController.text,
      );
      await _completeSignIn(result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã đặt lại mật khẩu và đăng nhập.')),
      );
      Navigator.of(context).pop(result.user);
    } catch (error) {
      if (mounted) _showApiError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(
      title: 'Quên mật khẩu',
      heading: 'Đặt lại mật khẩu',
      subtitle: _codeSent
          ? 'Nhập mã 6 số trong email và mật khẩu mới.'
          : 'Nhập email đã đăng ký, chúng tôi sẽ gửi mã xác nhận.',
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                enabled: !_codeSent,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                validator: _validateEmail,
                decoration: _authInputDecoration(
                  label: 'Email',
                  icon: Icons.mail_outline_rounded,
                ),
              ),
              if (_codeSent) ...[
                const SizedBox(height: 14),
                TextFormField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  maxLength: 6,
                  validator: (value) =>
                      RegExp(r'^\d{6}$').hasMatch(value?.trim() ?? '')
                      ? null
                      : 'Mã gồm 6 chữ số',
                  decoration: _authInputDecoration(
                    label: 'Mã xác nhận',
                    icon: Icons.pin_outlined,
                  ),
                ),
                const SizedBox(height: 6),
                _PasswordField(
                  controller: _passwordController,
                  label: 'Mật khẩu mới',
                  newPassword: true,
                  validator: _validateNewPassword,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        _AuthSubmitButton(
          label: _codeSent ? 'Đặt lại mật khẩu' : 'Gửi mã xác nhận',
          icon: _codeSent ? Icons.lock_reset_rounded : Icons.send_rounded,
          busy: _busy,
          onPressed: _codeSent ? _reset : _sendCode,
        ),
        if (_codeSent)
          TextButton(
            onPressed: _busy ? null : _sendCode,
            child: const Text('Gửi lại mã'),
          ),
      ],
    );
  }
}

class _ProfileFormPage extends StatefulWidget {
  const _ProfileFormPage({required this.user, this.completing = false});

  final ApiUser user;
  final bool completing;

  @override
  State<_ProfileFormPage> createState() => _ProfileFormPageState();
}

class _ProfileFormPageState extends State<_ProfileFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.user.fullName,
  );
  late final _phoneController = TextEditingController(text: widget.user.phone);
  late String _country = widget.user.country.isEmpty
      ? _countries.first
      : widget.user.country;
  bool _busy = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      final updated = await _api.updateProfile(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        country: _country,
      );
      await _setSignedIn(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.completing ? 'Chào mừng bạn!' : 'Đã cập nhật hồ sơ.',
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (mounted) _showApiError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(
      title: widget.completing ? 'Hoàn thiện hồ sơ' : 'Chỉnh sửa hồ sơ',
      heading: widget.completing ? 'Thêm vài thông tin' : 'Hồ sơ của bạn',
      subtitle: widget.user.email.isEmpty
          ? 'Tên và quốc gia sẽ hiển thị với cộng đồng.'
          : 'Tài khoản: ${widget.user.email}',
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                validator: _validateFullName,
                decoration: _authInputDecoration(
                  label: 'Họ và tên',
                  icon: Icons.person_outline_rounded,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumber],
                validator: _validateOptionalPhone,
                decoration: _authInputDecoration(
                  label: 'Số điện thoại (không bắt buộc)',
                  icon: Icons.phone_outlined,
                ),
              ),
              const SizedBox(height: 14),
              _CountryField(
                value: _country,
                onChanged: (country) => setState(() => _country = country),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _AuthSubmitButton(
          label: _busy
              ? 'Đang lưu...'
              : widget.completing
              ? 'Bắt đầu sử dụng'
              : 'Lưu thay đổi',
          icon: Icons.check_rounded,
          busy: _busy,
          onPressed: _save,
        ),
      ],
    );
  }
}
