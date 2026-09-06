import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/supabase_user_repository.dart';
import '../state/app_state.dart';
import '../ui/palette.dart';
import '../widgets/back_chevron.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _loading = false;
  String? _error;

  final _users = SupabaseUserRepository();

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final nickname = _nicknameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (nickname.isEmpty) {
      setState(() => _error = 'Please enter a nickname.');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Please enter a valid email address.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _users.signUp(
        email: email,
        password: password,
        nickname: nickname,
      );
      if (!mounted) return;
      if (response.session == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Account created. Please confirm your email before logging in.',
            ),
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => const LoginPage(),
          ),
        );
      } else {
        await context.read<AppState>().accountChanged();
        if (!mounted) return;
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _error = 'Unable to create account. Please check your details.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.ground,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: BackChevron(onTap: () => Navigator.of(context).maybePop()),
            ),
            const SizedBox(height: 42),
            const Center(
              child: Text(
                'Create your account',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Palette.ink,
                ),
              ),
            ),
            const SizedBox(height: 5),
            const Center(
              child: Text(
                'Start saving your analyses',
                style: TextStyle(
                  fontSize: 12,
                  color: Palette.muted,
                ),
              ),
            ),
            const SizedBox(height: 32),
            _field(
              label: 'NICKNAME',
              controller: _nicknameController,
              hint: 'Enter your nickname',
            ),
            const SizedBox(height: 20),
            _field(
              label: 'EMAIL',
              controller: _emailController,
              hint: 'Enter your email',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            const Text(
              'PASSWORD',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: Palette.muted,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: 'Create a password',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: Palette.faint,
                ),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Palette.muted,
                    size: 20,
                  ),
                ),
                filled: true,
                fillColor: Palette.card,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Palette.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Palette.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Palette.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(
                  fontSize: 11,
                  color: Palette.riskText,
                ),
              ),
            ],
            const SizedBox(height: 28),
            GestureDetector(
              onTap: _loading ? null : _register,
              child: Container(
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: Palette.gradHero,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: const [Palette.heroShadow],
                ),
                child: Text(
                  _loading ? 'Registering...' : 'Register',
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Already have an account?',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Palette.muted,
                  ),
                ),
                TextButton(
                  onPressed: _loading
                      ? null
                      : () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => const LoginPage(),
                      ),
                    );
                  },
                  child: const Text(
                    'Log in',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Palette.periText,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: Palette.muted,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 13,
              color: Palette.faint,
            ),
            filled: true,
            fillColor: Palette.card,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Palette.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Palette.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Palette.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}