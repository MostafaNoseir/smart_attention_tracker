import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _showPass = false;
  String? _error;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService().signIn(_emailCtrl.text.trim(), _passCtrl.text);
      if (mounted) context.go('/dashboard');
    } catch (e) {
      setState(() { _error = _friendlyError(e.toString()); });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailCtrl.text.trim();
    
    // لو الإيميل فاضي، نطلب منه يكتبه
    if (email.isEmpty) {
      setState(() {
        _error = 'Please enter your email first to reset password.';
      });
      return;
    }

    // إظهار Dialog التحميل
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // استدعاء فايربيز لإرسال اللينك
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      
      if (mounted) {
        Navigator.pop(context); // قفل اللودينج
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset link sent to your email!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // قفل اللودينج
        setState(() {
          _error = 'Failed to send reset link. Please check your email.';
        });
      }
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('user-not-found') || raw.contains('wrong-password') ||
        raw.contains('invalid-credential')) {
      return 'Incorrect email or password.';
    }
    if (raw.contains('network')) return 'Check your internet connection.';
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // ── Left brand panel ──────────────────────────────────
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(right: BorderSide(color: AppColors.surfaceBorder)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(60),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.primaryDim,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary, width: 1.5),
                          ),
                          child: const Icon(Icons.remove_red_eye_outlined,
                            color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Text('EyeFocus',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            letterSpacing: -0.5,
                          )),
                      ],
                    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),

                    const Spacer(),

                    Text(
                      'Understanding\nattention,\none session\nat a time.',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        height: 1.15,
                        color: AppColors.textPrimary,
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                    const SizedBox(height: 24),

                    Text(
                      'AI-powered eye tracking for children aged 6–10. '
                      'No special hardware required.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ).animate().fadeIn(delay: 300.ms),

                    const Spacer(),

                    // Feature pills
                    // Wrap(
                    //   spacing: 10,
                    //   runSpacing: 10,
                    //   children: ['Webcam only', 'Offline model', 'Research-grade', 'GDPR ready']
                    //       .asMap()
                    //       .entries
                    //       .map((e) => Container(
                    //             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    //             decoration: BoxDecoration(
                    //               color: AppColors.surfaceElevated,
                    //               borderRadius: BorderRadius.circular(50),
                    //               border: Border.all(color: AppColors.surfaceBorder),
                    //             ),
                    //             child: Text(e.value,
                    //               style: const TextStyle(
                    //                 color: AppColors.textSecondary,
                    //                 fontSize: 12,
                    //                 fontWeight: FontWeight.w500,
                    //               )),
                    //           ).animate().fadeIn(delay: (400 + e.key * 80).ms))
                    //       .toList(),
                    // ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),

          // ── Right login panel ─────────────────────────────────
          SizedBox(
            width: 460,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome back',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ).animate().fadeIn(delay: 150.ms),
                    const SizedBox(height: 8),
                    Text('Sign in to your organization account',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 48),

                    AppTextField(
                      label: 'EMAIL',
                      hint: 'organization@email.com',
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.mail_outline,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Email is required';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ).animate().fadeIn(delay: 250.ms),

                    const SizedBox(height: 20),

                    AppTextField(
                      label: 'PASSWORD',
                      hint: '••••••••',
                      controller: _passCtrl,
                      obscureText: !_showPass,
                      prefixIcon: Icons.lock_outline,
                      suffixWidget: GestureDetector(
                        onTap: () => setState(() => _showPass = !_showPass),
                        child: Icon(
                          _showPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password is required';
                        return null;
                      },
                    ).animate().fadeIn(delay: 300.ms),

                    const SizedBox(height: 12),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                       onPressed: _resetPassword,
                        child: const Text('Forgot password?',
                          style: TextStyle(color: AppColors.primary, fontSize: 13)),
                      ),
                    ).animate().fadeIn(delay: 340.ms),

                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.dangerDim,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
                            const SizedBox(width: 10),
                            Expanded(child: Text(_error!,
                              style: const TextStyle(color: AppColors.danger, fontSize: 13))),
                          ],
                        ),
                      ).animate().shake(),
                    ],

                    const SizedBox(height: 28),

                    PrimaryButton(
                      label: 'Sign in',
                      onPressed: _login,
                      isLoading: _loading,
                    ).animate().fadeIn(delay: 350.ms),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Don't have an account?",
                          style: Theme.of(context).textTheme.bodyMedium),
                        TextButton(
                          onPressed: () => context.go('/signup'),
                          child: const Text('Create organization',
                            style: TextStyle(color: AppColors.primary, fontSize: 13,
                              fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ).animate().fadeIn(delay: 400.ms),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }
}