import 'package:blog/authentication.dart';
import 'package:blog/features/screens/auth/sign_in_page.dart';
import 'package:blog/widgets/gradient_button.dart';
import 'package:flutter/material.dart';

class SignUpPage extends StatefulWidget {
  final AuthenticationBloc authBloc;

  const SignUpPage({super.key, required this.authBloc});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _emailController =
      TextEditingController(text: 'test@gmail.com');
  final TextEditingController _passwordController =
      TextEditingController(text: 'password');
  final TextEditingController _nameController =
      TextEditingController(text: 'Test User');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 16.0),
            GradientButton(buttonText: 'Sign Up', onPressed: _signUp),
            const SizedBox(height: 16.0),
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SignInPage(authBloc: widget.authBloc),
                  ),
                );
              },
              child: const Text(
                'Already have an account? Sign in',
                style: TextStyle(color: Colors.blue),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _signUp() {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    final String name = _nameController.text.trim();
    if (email.isNotEmpty && password.isNotEmpty) {
      widget.authBloc
          .signUpWithEmailAndPassword(email, password, name)
          .then((_) {
        // Navigate to home page if sign-up is successful
        Navigator.pushReplacementNamed(context,
            '/'); // Adjust the route name as per your app's navigation setup
      }).catchError((error) {
        // Handle sign-up error
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Sign Up Error'),
            content: Text('$error'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      });
    } else {
      // Show error if email or password is empty
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sign Up Error'),
          content: const Text('Please enter your email and password.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
