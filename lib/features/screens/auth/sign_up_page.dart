import 'package:blog/authentication.dart';
import 'package:blog/features/screens/auth/sign_in_page.dart';
import 'package:flutter/material.dart';

class SignUpPage extends StatefulWidget {
  final AuthenticationBloc authBloc;

  const SignUpPage({required this.authBloc});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _signUp,
              child: Text('Sign Up'),
            ),
            SizedBox(height: 16.0),
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SignInPage(authBloc: widget.authBloc),
                  ),
                );
              },
              child: Text(
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
    if (email.isNotEmpty && password.isNotEmpty) {
      widget.authBloc.signUpWithEmailAndPassword(email, password).then((_) {
        // Navigate to home page if sign-up is successful
        Navigator.pushReplacementNamed(context,
            '/'); // Adjust the route name as per your app's navigation setup
      }).catchError((error) {
        // Handle sign-up error
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Sign Up Error'),
            content: Text('$error'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
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
          title: Text('Sign Up Error'),
          content: Text('Please enter your email and password.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
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
