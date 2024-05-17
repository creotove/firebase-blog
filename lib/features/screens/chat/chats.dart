import 'package:blog/authentication.dart';
import 'package:flutter/material.dart';

class ChatsPage extends StatefulWidget {
  final AuthenticationBloc authBloc;
  const ChatsPage({super.key, required this.authBloc});

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chats'),
      ),
      body: Center(
        child: Text('Chats Page'),
      ),
    );
  }
}
