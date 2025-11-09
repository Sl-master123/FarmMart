import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  String _role = 'Farmer';
  bool _obscure1 = true, _obscure2 = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = FirebaseAuth.instance;
      final cred = await auth.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );
      final uid = cred.user!.uid;

      // store profile
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'user_type': _role.toLowerCase(),
        'created_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // ✅ send verification email
      try {
        await cred.user!.sendEmailVerification();
      } catch (_) {}

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Account created. Please verify your email before logging in.',
          ),
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Sign up failed');
    } catch (_) {
      setState(() => _error = 'Something went wrong');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            children: [
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Image.asset(
                                    'assets/farmmart.png', // ✅ Ensure this exists
                                    width: 200,
                                    height: 200,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 20),

                          TextFormField(
                            controller: _name,
                            decoration: _inputDecoration(
                              label: 'Full Name',
                              hint: 'Your name ',
                              icon: Icons.person_outline,
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Enter your name'
                                : null,
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _email,
                            decoration: _inputDecoration(
                              label: 'Email',
                              hint: 'you@example.com',
                              icon: Icons.mail_outline,
                            ),
                            validator: (v) => (v == null || !v.contains('@'))
                                ? 'Enter a valid email'
                                : null,
                          ),
                          const SizedBox(height: 12),

                          DropdownButtonFormField<String>(
                            value: _role,
                            decoration: _inputDecoration(
                              label: 'User Type',
                              hint: 'Choose role',
                              icon: Icons.account_circle_outlined,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'Farmer',
                                child: Text('Farmer'),
                              ),
                              DropdownMenuItem(
                                value: 'Buyer',
                                child: Text('Buyer'),
                              ),
                              DropdownMenuItem(
                                value: 'Seller',
                                child: Text('Seller'),
                              ),
                              // DropdownMenuItem(
                              //   value: 'Admin',
                              //   child: Text('Admin'),
                              // ),
                            ],
                            onChanged: (v) =>
                                setState(() => _role = v ?? 'Farmer'),
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _password,
                            obscureText: _obscure1,
                            decoration: _inputDecoration(
                              label: 'Password',
                              hint: 'At least 6 chars',
                              icon: Icons.lock_outline,
                              suffix: IconButton(
                                icon: Icon(
                                  _obscure1
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () =>
                                    setState(() => _obscure1 = !_obscure1),
                              ),
                            ),
                            validator: (v) => (v == null || v.length < 6)
                                ? 'Use at least 6 characters'
                                : null,
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _confirm,
                            obscureText: _obscure2,
                            decoration: _inputDecoration(
                              label: 'Confirm Password',
                              hint: 'Re-enter password',
                              icon: Icons.lock_person_outlined,
                              suffix: IconButton(
                                icon: Icon(
                                  _obscure2
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () =>
                                    setState(() => _obscure2 = !_obscure2),
                              ),
                            ),
                            validator: (v) => (v != _password.text)
                                ? 'Passwords do not match'
                                : null,
                          ),

                          if (_error != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],

                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _signup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _loading
                                  ? const CircularProgressIndicator(
                                      strokeWidth: 2,
                                    )
                                  : const Text('Create Account'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Already have an account? '),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LoginPage(),
                                    ),
                                  );
                                },
                                child: const Text('Log in'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.green),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.green[50],
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
