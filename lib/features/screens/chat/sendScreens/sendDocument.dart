// import 'dart:io';

// import 'package:blog/authentication.dart';
// import 'package:flutter/material.dart';

// class SendDocument extends StatelessWidget {
//   final File document;
//   final AuthenticationBloc authBloc;
//   final String? receiverUserId;
//   final String? currentUserId;

//   const SendDocument({
//     super.key,
//     required this.document,
//     required this.authBloc,
//     this.receiverUserId,
//     this.currentUserId,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return const Placeholder();
//   }
// }
import 'dart:io';

import 'package:blog/features/screens/chat/message_sender_helper.dart';
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
  void _sendDocument() async {
    print('Sending document');
    await MessageHelper().sendDocumentMessage(
      widget.document,
      widget.currentUserId!,
      widget.receiverUserId!,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Document'),
        actions: [
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendDocument,
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 250,
            width: double.infinity,
            child: Icon(Icons.insert_drive_file, size: 100, color: Colors.grey),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              widget.document.path.split('/').last,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
