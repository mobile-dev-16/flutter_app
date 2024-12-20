import 'package:eco_bites/core/utils/analytics_service.dart';
import 'package:eco_bites/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:eco_bites/features/auth/presentation/bloc/auth_event.dart';
import 'package:eco_bites/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sign_button/sign_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final DateTime loginStartTime = DateTime.now();
      // Trigger the sign-in event if form is valid
      context.read<AuthBloc>().add(
        SignInRequested(
          email: _emailController.text,
          password: _passwordController.text,
        ),
      );
      final DateTime loginEndTime = DateTime.now();
      final Duration loginTime = loginEndTime.difference(loginStartTime);
      logLoginTime(loginTime.inMilliseconds); // Log login time
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EDDF),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,  // Form key for validation
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.only(bottom: 32.0),
                  child: Image(
                    image: AssetImage('assets/logo.png'),
                    height: 180,
                  ),
                ),
                const SizedBox(height: 16),
                // Google Sign In Button (Using SignInButton)
                _buildGoogleSignInButton(context),
                const SizedBox(height: 16),
                const Text('OR'),
                const SizedBox(height: 16),
                // Email TextFormField
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.75,
                  child: TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                          .hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // Password TextFormField
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.75,
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 32),
                // Sign In Button
                BlocListener<AuthBloc, AuthState>(
                  listener: (BuildContext context, AuthState state) {
                    if (state is AuthLoading) {
                      _showLoadingDialog(context);
                    } else if (state is AuthAuthenticated) {
                      Navigator.pop(context);
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/main',
                        (Route<dynamic> route) => false,
                      );
                    } else if (state is AuthError) {
                      Navigator.pop(context); // Close loading dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(state.errorMessage)),
                      );
                    }
                  },
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.5,
                    child: ElevatedButton(
                      onPressed: _submitForm,  // Validate form and submit
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF725C0C),
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Navigate to Register Screen
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
                  },
                  child: const Text("Don't have an account? Register here"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Google Sign In Button using the SignInButton package
  Widget _buildGoogleSignInButton(BuildContext context) {
    return SignInButton(
      buttonType: ButtonType.google,
      width: 195,
      btnColor: Colors.white,
      elevation: 0,
      onPressed: () {
        context.read<AuthBloc>().add(SignInWithGoogleRequested());
      },
    );
  }

  // Loading dialog
  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
