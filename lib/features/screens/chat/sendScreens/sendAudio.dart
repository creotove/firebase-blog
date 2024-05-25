// ignore_for_file: file_names, library_private_types_in_public_api
import 'dart:io';
import 'package:blog/utils/message_sender_helper.dart';
import 'package:blog/utils/show_snackbar.dart';
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
  bool isSending = false;
  void _sendAudio() async {
    try {
      MessageHelper().sendAudioMessage(
        widget.audio,
        widget.currentUserId!,
        widget.receiverUserId!,
      );
      Navigator.pop(context);
      setState(() {
        showSnackBar(context, 'Audio sent successfully!');
      });
    } catch (e) {
      setState(() {
        showSnackBar(context, 'Failed to send audio');
      });
    } finally {
      setState(() {
        isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Audio'),
        actions: [
          if (isSending)
            const Center(
              child: CircularProgressIndicator(),
            )
          else
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
