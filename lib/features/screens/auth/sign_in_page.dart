// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:blog/authentication.dart';
import 'package:blog/features/screens/auth/sign_up_page.dart';
import 'package:blog/widgets/gradient_button.dart';
import 'package:flutter/material.dart';

class SignInPage extends StatefulWidget {
  final AuthenticationBloc authBloc;

  const SignInPage({super.key, required this.authBloc});

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController =
      TextEditingController(text: '');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            GradientButton(buttonText: 'Sign In', onPressed: _signIn),
            const SizedBox(height: 16.0),
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SignUpPage(authBloc: widget.authBloc),
                  ),
                );
              },
              child: const Text(
                'Don\'t have an account? Sign up',
                style: TextStyle(color: Colors.blue),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _signIn() async {
    try {
      await widget.authBloc.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      await Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sign In Error'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}
