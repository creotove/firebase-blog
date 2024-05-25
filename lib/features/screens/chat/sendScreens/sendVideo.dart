// ignore_for_file: file_names, avoid_print, use_build_context_synchronously

import 'dart:io';
import 'package:blog/authentication.dart';
import 'package:blog/features/screens/chat/message_sender_helper.dart';
import 'package:flutter/material.dart';

class SendVideo extends StatefulWidget {
  final File document;
  final AuthenticationBloc authBloc;
  final String? receiverUserId;
  final String? currentUserId;

  const SendVideo({
    super.key,
    required this.document,
    required this.authBloc,
    this.receiverUserId,
    this.currentUserId,
  });

  @override
  State<SendVideo> createState() => _SendVideoState();
}

class _SendVideoState extends State<SendVideo> {
  bool isLoaded = false;
  void _sendVideo() async {
    try {
      setState(() {
        isLoaded = true;
      });
      await MessageHelper().sendVideoMessage(
        widget.document,
        widget.currentUserId!,
        widget.receiverUserId!,
      );
      Navigator.pop(context);
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        isLoaded = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Send Video'),
          actions: [
            isLoaded
                ? const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  )
                : IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendVideo,
                  ),
          ],
        ),
        body: Column(
          children: [
            const SizedBox(
              height: 250,
              width: double.infinity,
              child: Icon(Icons.video_library, size: 100, color: Colors.grey),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                widget.document.path.split('/').last,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ));
  }
}
