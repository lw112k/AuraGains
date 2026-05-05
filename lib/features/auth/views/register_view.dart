import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/auth_viewmodel.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();

  // Colors based on your mockup
  final Color _bgColor = const Color(0xFF121212); // Deep dark background
  final Color _fieldColor = const Color(0xFF2A2A2A); // Dark grey input fields
  final Color _neonLime = const Color(
    0xFFD4FF00,
  ); // The neon green/yellow accent

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      final authViewModel = context.read<AuthViewModel>();
      final success = await authViewModel.register(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        username: _usernameController.text.trim(),
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authViewModel.errorMessage ?? 'Registration failed'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthViewModel>().isLoading;

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo Placeholder (Keeping the Flutter icon as requested)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _fieldColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.fitness_center,
                    size: 40,
                    color: Colors.amber,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // AURAGAINS Header
              const Text(
                'AURAGAINS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                'REGISTER',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _neonLime,
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
                hintText: 'you@gmail.com',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Email is required';
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
                validator: (value) =>
                    value!.length < 6 ? 'Must be at least 6 characters' : null,
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
              ElevatedButton(
                onPressed: isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _neonLime,
                  foregroundColor: Colors.black, // Black text on neon button
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.black,
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
                  const Text(
                    "Already have an account? ",
                    style: TextStyle(color: Colors.grey),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context), // Goes back to login
                    child: Text(
                      "Login",
                      style: TextStyle(
                        color: _neonLime,
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
    );
  }

  // --- UI Helper Methods to match the mockup ---

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.grey,
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
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade700),
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
          borderSide: BorderSide(color: _neonLime, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
      ),
    );
  }
}
