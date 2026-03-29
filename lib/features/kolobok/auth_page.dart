import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hiddify/features/kolobok/api_service.dart';

const Color _kAccent = Color(0xFFF5A623);
const Color _kBorder = Color(0xFFE0E0E0);
const TextStyle _kFieldLabelStyle = TextStyle(
  color: Color(0xFF333333),
  fontSize: 14,
);

const TextStyle _kFieldInputStyle = TextStyle(color: Color(0xFF1A1A2E));

const String _kTrialWelcomeMessage = '🎉 Добро пожаловать! У вас 7 дней бесплатного доступа';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.onAuthenticated});

  final VoidCallback onAuthenticated;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _api = ApiService();

  bool _isLogin = true;
  bool _loading = false;
  String? _errorText;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _termsAccepted = false;

  @override
  void dispose() {
    _emailController.dispose();
    _fullNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({Widget? suffixIcon}) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kAccent, width: 2),
      ),
    );
  }

  Widget _logoHeader() {
    return Column(
      children: [
        Image.asset(
          'assets/images/logo.png',
          width: double.infinity,
          height: 320,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  void _showComingSoonSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Скоро')),
    );
  }

  String _usernameFromEmail(String email) {
    final local = email.split('@').first.trim();
    if (local.isEmpty) return 'user';
    return local;
  }

  Widget _title(String text) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: _kAccent,
      ),
    );
  }

  Widget _orDivider() {
    return const Row(
      children: [
        Expanded(child: Divider(color: _kBorder, thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Или войти через',
            style: TextStyle(
              color: Color(0xFF333333),
              fontSize: 14,
            ),
          ),
        ),
        Expanded(child: Divider(color: _kBorder, thickness: 1)),
      ],
    );
  }

  Widget _circleSocialButton({required Widget child}) {
    return SizedBox(
      width: 56,
      height: 56,
      child: OutlinedButton(
        onPressed: _showComingSoonSnackBar,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          side: const BorderSide(color: Color(0xFFE0E0E0)),
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: child,
      ),
    );
  }

  Widget _socialRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _circleSocialButton(
          child: const FaIcon(
            FontAwesomeIcons.google,
            color: Color(0xFF4285F4),
          ),
        ),
        const SizedBox(width: 12),
        _circleSocialButton(
          child: const Text(
            'Я',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFC3F1D),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _circleSocialButton(
          child: const FaIcon(
            FontAwesomeIcons.telegram,
            color: Color(0xFF2AABEE),
          ),
        ),
        const SizedBox(width: 12),
        _circleSocialButton(
          child: const FaIcon(
            FontAwesomeIcons.apple,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _passwordSuffix(VoidCallback onToggle, bool obscure) {
    return IconButton(
      onPressed: onToggle,
      icon: Icon(
        obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: const Color(0xFF333333),
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Введите email';
    }
    final email = value.trim();
    if (!email.contains('@') || email.split('@').length != 2) {
      return 'Некорректный email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите пароль';
    }
    if (value.length < 6) {
      return 'Минимум 6 символов';
    }
    return null;
  }

  String? _validateFullName(String? value) {
    if (_isLogin) return null;
    if (value == null || value.trim().isEmpty) {
      return 'Введите имя';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (_isLogin) return null;
    if (value == null || value.isEmpty) {
      return 'Подтвердите пароль';
    }
    if (value != _passwordController.text) {
      return 'Пароли не совпадают';
    }
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_isLogin && !_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Согласитесь с Условиями использования и Политикой конфиденциальности'),
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorText = null;
    });
    try {
      final email = _emailController.text.trim();
      final registered = !_isLogin;
      if (_isLogin) {
        await _api.login(email: email, password: _passwordController.text);
      } else {
        await _api.register(
          email: email,
          username: _usernameFromEmail(email),
          password: _passwordController.text,
        );
        await _api.login(email: email, password: _passwordController.text);
      }
      if (!mounted) return;
      if (registered) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(_kTrialWelcomeMessage),
            duration: Duration(seconds: 5),
          ),
        );
      }
      widget.onAuthenticated();
    } catch (e) {
      setState(() => _errorText = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                _logoHeader(),
                _title(_isLogin ? 'Войти' : 'Регистрация'),
                const SizedBox(height: 16),
                if (!_isLogin) ...[
                  const Text('Полное имя', style: _kFieldLabelStyle),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _fullNameController,
                    style: _kFieldInputStyle,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDecoration(),
                    validator: _validateFullName,
                  ),
                  const SizedBox(height: 16),
                ],
                const Text('Email', style: _kFieldLabelStyle),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailController,
                  style: _kFieldInputStyle,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  decoration: _inputDecoration(),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 16),
                const Text('Пароль', style: _kFieldLabelStyle),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordController,
                  style: _kFieldInputStyle,
                  obscureText: _obscurePassword,
                  textInputAction: _isLogin ? TextInputAction.done : TextInputAction.next,
                  decoration: _inputDecoration(
                    suffixIcon: _passwordSuffix(
                      () => setState(() => _obscurePassword = !_obscurePassword),
                      _obscurePassword,
                    ),
                  ),
                  validator: _validatePassword,
                ),
                if (_isLogin) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showComingSoonSnackBar,
                      style: TextButton.styleFrom(foregroundColor: _kAccent),
                      child: const Text('Забыли пароль?'),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  const Text('Подтвердите пароль', style: _kFieldLabelStyle),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _confirmPasswordController,
                    style: _kFieldInputStyle,
                    obscureText: _obscureConfirm,
                    textInputAction: TextInputAction.done,
                    decoration: _inputDecoration(
                      suffixIcon: _passwordSuffix(
                        () => setState(() => _obscureConfirm = !_obscureConfirm),
                        _obscureConfirm,
                      ),
                    ),
                    validator: _validateConfirmPassword,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _termsAccepted,
                        onChanged: (v) => setState(() => _termsAccepted = v ?? false),
                        activeColor: _kAccent,
                        side: const BorderSide(color: _kBorder),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                'Я согласен с ',
                                style: TextStyle(color: Color(0xFF333333), fontSize: 14),
                              ),
                              GestureDetector(
                                onTap: _showComingSoonSnackBar,
                                child: const Text(
                                  'Условиями использования',
                                  style: TextStyle(
                                    color: _kAccent,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const Text(
                                ' и ',
                                style: TextStyle(color: Color(0xFF333333), fontSize: 14),
                              ),
                              GestureDetector(
                                onTap: _showComingSoonSnackBar,
                                child: const Text(
                                  'Политикой конфиденциальности',
                                  style: TextStyle(
                                    color: _kAccent,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (_isLogin) const SizedBox(height: 8),
                if (_errorText != null) ...[
                  Text(
                    _errorText!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 8),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kAccent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _kAccent.withValues(alpha: 0.6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isLogin ? 'Войти' : 'Зарегистрироваться',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                _orDivider(),
                const SizedBox(height: 12),
                _socialRow(),
                const SizedBox(height: 12),
                if (_isLogin) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Нет аккаунта?',
                        style: TextStyle(color: Color(0xFF333333), fontSize: 15),
                      ),
                      TextButton(
                        onPressed: () => setState(() {
                          _isLogin = false;
                          _errorText = null;
                        }),
                        style: TextButton.styleFrom(foregroundColor: _kAccent),
                        child: const Text(
                          'Регистрация',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
                if (!_isLogin) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Уже есть аккаунт?',
                        style: TextStyle(color: Color(0xFF333333), fontSize: 15),
                      ),
                      TextButton(
                        onPressed: () => setState(() {
                          _isLogin = true;
                          _errorText = null;
                          _termsAccepted = false;
                        }),
                        style: TextButton.styleFrom(foregroundColor: _kAccent),
                        child: const Text(
                          'Войти',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
