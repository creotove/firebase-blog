// ignore_for_file: use_build_context_synchronously, avoid_print, library_private_types_in_public_api, file_names

import 'dart:io';

import 'package:blog/utils/message_sender_helper.dart';
import 'package:blog/utils/show_snackbar.dart';
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
  bool isSending = false;
  void _sendImage() async {
    try {
      setState(() {
        isSending = true;
      });
      await MessageHelper().sendImageMessage(
        widget.image,
        widget.currentUserId!,
        widget.receiverUserId!,
      );
      Navigator.pop(context);
      setState(() {
        showSnackBar(context, 'Image sent successfully!');
      });
    } catch (e) {
      print(e);
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
        title: const Text('Send Image'),
        actions: [
          if (isSending)
            const Center(
              child: CircularProgressIndicator(),
            )
          else
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
