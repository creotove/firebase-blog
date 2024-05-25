// ignore_for_file: file_names, library_private_types_in_public_api, use_build_context_synchronously

import 'dart:io';

import 'package:blog/utils/message_sender_helper.dart';
import 'package:blog/utils/show_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:blog/authentication.dart';

class SendDocument extends StatefulWidget {
  final File document;
  final AuthenticationBloc authBloc;
  final String? receiverUserId;
  final String? currentUserId;

  const SendDocument({
    super.key,
    required this.document,
    required this.authBloc,
    this.receiverUserId,
    this.currentUserId,
  });

  @override
  _SendDocumentState createState() => _SendDocumentState();
}

class _SendDocumentState extends State<SendDocument> {
  bool isSending = false;
  void _sendDocument() async {
    try {
      setState(() {
        isSending = true;
      });
      await MessageHelper().sendDocumentMessage(
        widget.document,
        widget.currentUserId!,
        widget.receiverUserId!,
      );

      Navigator.pop(context);
      setState(() {
        showSnackBar(context, 'Document sent successfully!');
      });
    } catch (e) {
      showSnackBar(context, 'Failed to send document');
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
        title: const Text('Send Document'),
        actions: [
          if (isSending)
            const Center(
              child: CircularProgressIndicator(),
            )
          else
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _sendDocument,
            ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(
            height: 250,
            width: double.infinity,
            child: Icon(Icons.insert_drive_file, size: 100, color: Colors.grey),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              widget.document.path.split('/').last,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
