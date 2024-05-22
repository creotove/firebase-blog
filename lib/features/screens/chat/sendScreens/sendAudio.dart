import 'dart:io';
import 'package:blog/features/screens/chat/message_sender_helper.dart';
import 'package:flutter/material.dart';
import 'package:blog/authentication.dart';

class SendAudio extends StatefulWidget {
  final File audio;
  final AuthenticationBloc authBloc;
  final String? receiverUserId;
  final String? currentUserId;

  const SendAudio({
    super.key,
    required this.audio,
    required this.authBloc,
    this.receiverUserId,
    this.currentUserId,
  });

  @override
  _SendAudioState createState() => _SendAudioState();
}

class _SendAudioState extends State<SendAudio> {
  void _sendAudio() {
    MessageHelper().sendAudioMessage(
      widget.audio,
      widget.currentUserId!,
      widget.receiverUserId!,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Audio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendAudio,
          ),
        ],
      ),
      body: const Column(
        children: [
          SizedBox(
            height: 250,
            width: double.infinity,
            child: Icon(Icons.audiotrack, size: 100, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
