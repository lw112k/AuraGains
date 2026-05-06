import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/auth_viewmodel.dart';
import 'register_view.dart';

// =========================================================
// LOGIN VIEW (Handles both Splash & Login States)
// =========================================================
class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  // --- UI STATE ---
  bool _showWelcome = true;
  bool _isButtonLoading = false;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // ==========================================
  // 🎨 MASTER THEME VARIABLES
  // ==========================================
  final Color _bgColor = const Color(0xFF121212);
  final Color _boxColor = const Color(0xFF1E1E1E);
  final Color _fieldColor = const Color(0xFF2A2A2A);
  final Color _appBarColor = Colors.transparent;

  final Color _accentColor = const Color(0xFF00E5FF); // NEON BLUE
  final Color _errorColor = Colors.redAccent;
  final Color _logoIconColor = Colors.amber;

  final Color _textPrimary = Colors.white;
  final Color _textSecondary = Colors.grey;
  final Color _textHint = Colors.grey.shade700;
  final Color _textLink = Colors.grey.shade400;
  final Color _buttonText = Colors.black;
  final Color _appBarIconColor = Colors.white;
  // ==========================================

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _showWelcome = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      // 1. Turn on the local button spinner
      setState(() {
        _isButtonLoading = true;
      });

      final authViewModel = context.read<AuthViewModel>();
      final success = await authViewModel.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2. Check if the screen still exists before updating the UI
      if (mounted) {
        // 3. Turn off the local button spinner
        setState(() {
          _isButtonLoading = false;
        });

        // 4. Show the error if it failed!
        if (!success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authViewModel.errorMessage ?? 'Login failed'),
              backgroundColor: _errorColor,
            ),
          );
        }
      }
    }
  }

  // =========================================================
  // WELCOME / SPLASH SCREEN UI
  // Shows immediately on app launch while checking environment
  // =========================================================
  Widget _buildWelcomeScreen() {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(),

            // The Icon Box
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _boxColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _accentColor.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.fitness_center,
                size: 48,
                color: _logoIconColor,
              ),
            ),
            const SizedBox(height: 32),

            // The AURA GAINS Text
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
                children: [
                  TextSpan(
                    text: 'AURA',
                    style: TextStyle(color: _textPrimary),
                  ),
                  TextSpan(
                    text: 'GAINS',
                    style: TextStyle(color: _accentColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Subtitle
            Text(
              'N E X T - G E N  S O C I A L  F I T N E S S',
              style: TextStyle(
                color: _textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 3.0,
              ),
            ),
            const SizedBox(height: 40),

            // Welcome Text
            Text(
              'Loading Environment...',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),

            const Spacer(),

            // Loading Spinner
            CircularProgressIndicator(color: _accentColor, strokeWidth: 3),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // LOGIN FORM UI
  // Shows after the Welcome Screen finishes loading
  // =========================================================
  Widget _buildLoginForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _fieldColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.fitness_center,
                  size: 40,
                  color: _logoIconColor,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Text(
              'AURAGAINS',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              'LOGIN',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _accentColor,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 40),

            // Email
            _buildLabel('EMAIL'),
            _buildTextField(
              controller: _emailController,
              hintText: 'you@email.com',
              keyboardType: TextInputType.emailAddress,
              validator: (value) => value!.isEmpty ? 'Email required' : null,
            ),
            const SizedBox(height: 20),

            // Password
            _buildLabel('PASSWORD'),
            _buildTextField(
              controller: _passwordController,
              hintText: '••••••••',
              obscureText: true,
              validator: (value) => value!.isEmpty ? 'Password required' : null,
            ),
            const SizedBox(height: 40),

            // Login Button
            ElevatedButton(
              onPressed: _isButtonLoading ? null : _handleLogin, // CHANGED
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: _buttonText,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child:
                  _isButtonLoading // CHANGED
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: _buttonText,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 20),

            // Links
            Center(
              child: Text(
                "Forget Password?",
                style: TextStyle(color: _textLink),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Register New Account. ",
                  style: TextStyle(color: _textSecondary),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterView()),
                  ),
                  child: Text(
                    "Sign Up",
                    style: TextStyle(
                      color: _accentColor,
                      fontWeight: FontWeight.bold,
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

  // =========================================================
  // MAIN BUILDER
  // Controls the switching between Welcome and Login
  // =========================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: _showWelcome
          ? null
          : AppBar(
              backgroundColor: _appBarColor,
              elevation: 0,
              automaticallyImplyLeading: false,
            ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _showWelcome
              ? Container(key: const ValueKey(1), child: _buildWelcomeScreen())
              : Container(key: const ValueKey(2), child: _buildLoginForm()),
        ),
      ),
    );
  }

  // =========================================================
  // HELPER WIDGETS
  // Reusable components for the text fields
  // =========================================================
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        text,
        style: TextStyle(
          color: _textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(color: _textPrimary),
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: _textHint),
        filled: true,
        fillColor: _fieldColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _accentColor, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _errorColor, width: 1),
        ),
      ),
    );
  }
}
