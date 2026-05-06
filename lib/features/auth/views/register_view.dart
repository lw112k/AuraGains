import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/auth_viewmodel.dart';

// =========================================================
// REGISTER VIEW
// Handles new user creation and form validation
// =========================================================
class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  bool _isButtonLoading = false;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();

  // ==========================================
  // 🎨 MASTER THEME VARIABLES (Matched to Login)
  // ==========================================
  final Color _bgColor = const Color(0xFF121212);
  final Color _fieldColor = const Color(0xFF2A2A2A);
  final Color _appBarColor = Colors.transparent;

  final Color _accentColor = const Color(0xFF00E5FF); // NEON BLUE
  final Color _errorColor = Colors.redAccent;
  final Color _logoIconColor = Colors.amber;

  final Color _textPrimary = Colors.white;
  final Color _textSecondary = Colors.grey;
  final Color _textHint = Colors.grey.shade700;
  final Color _buttonText = Colors.black;
  final Color _appBarIconColor = Colors.white;
  // ==========================================

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  // =========================================================
  // REGISTRATION LOGIC
  // =========================================================
  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      // 1. Turn ON the local button spinner
      setState(() {
        _isButtonLoading = true;
      });

      final authViewModel = context.read<AuthViewModel>();
      final success = await authViewModel.register(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        username: _usernameController.text.trim(),
      );

      // 2. Check if the screen still exists
      if (mounted) {
        // 3. Turn OFF the local button spinner
        setState(() {
          _isButtonLoading = false;
        });

        if (!success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                authViewModel.errorMessage ?? 'Registration failed',
              ),
              backgroundColor: _errorColor,
            ),
          );
        } else {
          // Success! Go back to login
          Navigator.pop(context);
        }
      }
    }
  }

  // =========================================================
  // MAIN BUILDER: REGISTER FORM UI
  // =========================================================
  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthViewModel>().isLoading;

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _appBarColor,
        elevation: 0,
        // The register screen DOES need a back button to return to login!
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _appBarIconColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo Placeholder
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

                // AURAGAINS Header
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
                  'REGISTER',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _accentColor, // Uses Neon Blue
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 40),

                // Full Name Field
                _buildLabel('FULL NAME'),
                _buildTextField(
                  controller: _usernameController,
                  hintText: 'Your name',
                  validator: (value) =>
                      value!.isEmpty ? 'Name cannot be empty' : null,
                ),
                const SizedBox(height: 20),

                // Email Field
                _buildLabel('EMAIL'),
                _buildTextField(
                  controller: _emailController,
                  hintText: 'you@email.com',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email is required';
                    }
                    if (!value.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Password Field
                _buildLabel('PASSWORD'),
                _buildTextField(
                  controller: _passwordController,
                  hintText: '••••••••',
                  obscureText: true,
                  validator: (value) => value!.length < 6
                      ? 'Must be at least 6 characters'
                      : null,
                ),
                const SizedBox(height: 20),

                // Confirm Password Field
                _buildLabel('CONFIRM PASSWORD'),
                _buildTextField(
                  controller: _confirmPasswordController,
                  hintText: '••••••••',
                  obscureText: true,
                  validator: (value) => value != _passwordController.text
                      ? 'Passwords do not match'
                      : null,
                ),
                const SizedBox(height: 40),

                // Register Button
                // Register Button
                ElevatedButton(
                  onPressed: _isButtonLoading
                      ? null
                      : _handleRegister, // CHANGED
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
                          'Register',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 20),

                // Bottom Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: TextStyle(color: _textSecondary),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context), // Goes back to login
                      child: Text(
                        "Login",
                        style: TextStyle(
                          color: _accentColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
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
