import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../repositories/app_repository.dart';
import '../../widgets/glass_container.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.api, required this.repository});
  final ApiClient api;
  final AppRepository repository;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final phone = TextEditingController();
  final otp = TextEditingController();
  final name = TextEditingController();
  bool otpSent = false;
  bool loading = false;
  bool isSignUp = false;
  String? error;

  /// Supabase phone auth requires E.164 (e.g. +201287772237). People type
  /// local numbers like "01287772237", so normalize before sending —
  /// otherwise Supabase rejects it before it even gets to the SMS provider.
  String _normalizePhone(String raw) {
    var digits = raw.trim();
    if (digits.startsWith('+')) return digits.replaceAll(' ', '');
    digits = digits.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('0')) digits = digits.substring(1);
    if (!digits.startsWith('20')) digits = '20$digits';
    return '+$digits';
  }

  Future<void> _sendOtp() async {
    if (phone.text.trim().length < 8) {
      setState(() => error = 'Enter a valid phone number.');
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await widget.repository.sendOtp(
        _normalizePhone(phone.text),
        fullName: isSignUp ? name.text : null,
      );
      if (mounted) setState(() => otpSent = true);
    } on AuthException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _google() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await widget.repository.signInWithGoogle();
      // The browser redirect flow completes asynchronously; the reactive
      // session gate in main.dart routes to the right screen once the
      // auth state actually changes.
    } on AuthException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _verify() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await widget.repository.verifyOtp(_normalizePhone(phone.text), otp.text.trim());
      // No manual navigation here on purpose: verifying the OTP updates the
      // Supabase auth state, and the reactive session gate in main.dart
      // picks that up and swaps to the right dashboard automatically.
    } on AuthException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    phone.dispose();
    otp.dispose();
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GlassBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.bolt_rounded, color: AppColors.orange, size: 32),
                  ),
                ),
                const SizedBox(height: 28),
                GlassContainer(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _modeToggle(),
                      const SizedBox(height: 22),
                      Text(
                        isSignUp ? 'Create your account' : 'Welcome back',
                        style: const TextStyle(color: AppColors.ink, fontSize: 30, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isSignUp
                            ? 'Set up an account to start booking.'
                            : 'Book trusted services around you in a few taps.',
                        style: const TextStyle(color: AppColors.ink, fontSize: 15),
                      ),
                      const SizedBox(height: 26),
                      if (!otpSent) ...[
                        if (isSignUp) ...[
                          const Text('Full name', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 10),
                          TextField(
                            controller: name,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.person_outline),
                              hintText: 'Your name',
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        const Text('Phone number', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 10),
                        TextField(
                          controller: phone,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.phone_outlined),
                            hintText: '01xxxxxxxxx or +20 1xxxxxxxxx',
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: loading ? null : _sendOtp,
                          child: loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(isSignUp ? 'Create account' : 'Continue with phone'),
                        ),
                      ] else ...[
                        Text(
                          'Code sent to ${_normalizePhone(phone.text)}',
                          style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: otp,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: const InputDecoration(hintText: '••••••'),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: loading ? null : _verify,
                          child: loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Verify & continue'),
                        ),
                        TextButton(
                          onPressed: loading ? null : () => setState(() => otpSent = false),
                          child: const Text('Change phone'),
                        ),
                      ],
                      if (error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Text(
                            error!,
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
                          ),
                        ),
                      const SizedBox(height: 20),
                      const Row(
                        children: [
                          Expanded(child: Divider(color: Colors.black26)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text('OR', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700)),
                          ),
                          Expanded(child: Divider(color: Colors.black26)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: loading ? null : _google,
                        icon: const Icon(Icons.g_mobiledata, color: AppColors.ink),
                        label: const Text('Continue with Google', style: TextStyle(color: AppColors.ink)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                    child: const Text('Browse as guest', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _modeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(child: _modeTab('Sign in', !isSignUp, () => setState(() => isSignUp = false))),
          Expanded(child: _modeTab('Sign up', isSignUp, () => setState(() => isSignUp = true))),
        ],
      ),
    );
  }

  Widget _modeTab(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
