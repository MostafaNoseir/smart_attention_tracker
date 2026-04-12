import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _orgCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _showPass = false;
  String? _error;

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService().signUp(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        orgName: _orgCtrl.text.trim(),
      );
      if (mounted) context.go('/dashboard');
    } catch (e) {
      setState(() => _error = e.toString().contains('email-already-in-use')
          ? 'This email is already registered.'
          : 'Registration failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 60),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
                  Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primaryDim,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary, width: 1.5),
                      ),
                      child: const Icon(Icons.remove_red_eye_outlined,
                        color: AppColors.primary, size: 28),
                    ),
                  ).animate().scale(delay: 100.ms),

                  const SizedBox(height: 32),

                  Row(
                    children: [
                      const SizedBox(width: 100),
                      Text('Create your organization',
                        style: Theme.of(context).textTheme.headlineLarge,
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 150.ms),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Set up an EyeFocus account for your clinic, school, or research team.',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 48),

                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Organization details',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textSecondary, fontSize: 12, letterSpacing: 0.8)),
                        const SizedBox(height: 20),

                        AppTextField(
                          label: 'ORGANIZATION NAME',
                          hint: 'e.g. Cairo Child Development Center',
                          controller: _orgCtrl,
                          prefixIcon: Icons.business_outlined,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Organization name is required';
                            if (v.length < 3) return 'Name must be at least 3 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        AppTextField(
                          label: 'WORK EMAIL',
                          hint: 'admin@organization.com',
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.mail_outline,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Email is required';
                            if (!v.contains('@')) return 'Enter a valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        AppTextField(
                          label: 'PASSWORD',
                          hint: 'Min. 8 characters',
                          controller: _passCtrl,
                          obscureText: !_showPass,
                          prefixIcon: Icons.lock_outline,
                          suffixWidget: GestureDetector(
                            onTap: () => setState(() => _showPass = !_showPass),
                            child: Icon(
                              _showPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 18, color: AppColors.textMuted),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Password is required';
                            if (v.length < 8) return 'Minimum 8 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        AppTextField(
                          label: 'CONFIRM PASSWORD',
                          hint: '••••••••',
                          controller: _confirmCtrl,
                          obscureText: true,
                          prefixIcon: Icons.lock_outline,
                          validator: (v) {
                            if (v != _passCtrl.text) return 'Passwords do not match';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 250.ms),

                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.dangerDim,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                      ),
                      child: Text(_error!,
                        style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                    ).animate().shake(),
                  ],

                  const SizedBox(height: 28),

                  PrimaryButton(
                    label: 'Create organization',
                    onPressed: _signup,
                    isLoading: _loading,
                  ).animate().fadeIn(delay: 300.ms),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account?',
                        style: Theme.of(context).textTheme.bodyMedium),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('Sign in',
                          style: TextStyle(color: AppColors.primary,
                            fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ).animate().fadeIn(delay: 350.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _orgCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }
}