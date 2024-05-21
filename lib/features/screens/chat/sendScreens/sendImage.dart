import 'dart:io';

import 'package:blog/features/screens/chat/message_sender_helper.dart';
import 'package:flutter/material.dart';
import 'package:blog/authentication.dart';

class SendImage extends StatefulWidget {
  final File image;
  final AuthenticationBloc authBloc;
  final String? receiverUserId;
  final String? currentUserId;

  const SendImage({
    super.key,
    required this.image,
    required this.authBloc,
    this.receiverUserId,
    this.currentUserId,
  });

  @override
  _SendImageState createState() => _SendImageState();
}

class _SendImageState extends State<SendImage> {
  void _sendImage() {
    MessageHelper().sendImageMessage(
      widget.image,
      widget.currentUserId!,
      widget.receiverUserId!,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Image'),
        actions: [
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendImage,
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 250,
            width: double.infinity,
            child: Image.file(widget.image, fit: BoxFit.cover),
          ),
        ],
      ),
    );
  }
}
