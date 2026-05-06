import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _error = '';
  bool _loading = false;
  bool _obscure = true;

  Future<void> _register() async {
    if (_nameCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _passwordCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );
      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Sign out so user logs in manually
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        _nameCtrl.clear();
        _emailCtrl.clear();
        _passwordCtrl.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle_outline,
                  color: Color(0xFF61F4A2), size: 16),
              SizedBox(width: 8),
              Text('Account created! Please sign in.',
                  style: TextStyle(fontSize: 13)),
            ]),
            backgroundColor: AppColors.navyElevated,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Registration failed.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyDeep,
      appBar: AppBar(
        backgroundColor: AppColors.navyDeep,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
        title: const Text('Create Account',
            style: TextStyle(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Icon(Icons.shield_outlined,
                  color: AppColors.amber, size: 40),
              const SizedBox(height: 8),
              const Text('Bantay Daan',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white)),
              const SizedBox(height: 4),
              const Text('Register as a citizen reporter',
                  style: TextStyle(fontSize: 12, color: AppColors.muted)),
              const SizedBox(height: 32),
              if (_error.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.3)),
                  ),
                  child: Text(_error,
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 12)),
                ),
              _buildLabel('FULL NAME'),
              const SizedBox(height: 6),
              _buildInput(_nameCtrl, 'Juan dela Cruz', false),
              const SizedBox(height: 14),
              _buildLabel('EMAIL'),
              const SizedBox(height: 6),
              _buildInput(_emailCtrl, 'juan@email.com', false),
              const SizedBox(height: 14),
              _buildLabel('PASSWORD'),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordCtrl,
                obscureText: _obscure,
                style: const TextStyle(color: AppColors.white, fontSize: 13),
                decoration: _inputDecor('••••••••').copyWith(
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => _obscure = !_obscure),
                    child: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.inactive,
                      size: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amber,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Color(0xFF1a0e00), strokeWidth: 2))
                      : const Text('Create Account',
                          style: TextStyle(
                              color: Color(0xFF1a0e00),
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: RichText(
                  text: const TextSpan(
                    text: 'Already have an account? ',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                    children: [
                      TextSpan(
                          text: 'Sign In',
                          style: TextStyle(
                              color: AppColors.amber,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Align(
        alignment: Alignment.centerLeft,
        child: Text(text,
            style: const TextStyle(
                fontSize: 10,
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
      );

  Widget _buildInput(TextEditingController ctrl, String hint, bool obscure) =>
      TextField(
        controller: ctrl,
        obscureText: obscure,
        style: const TextStyle(color: AppColors.white, fontSize: 13),
        decoration: _inputDecor(hint),
      );

  InputDecoration _inputDecor(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.inactive),
        filled: true,
        fillColor: AppColors.navySurface,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none),
        enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.navyElevated, width: 1.5)),
        focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.amber, width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      );
}
