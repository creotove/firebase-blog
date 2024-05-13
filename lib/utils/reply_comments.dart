import 'package:blog/utils/date_time_formatter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CommentWidget extends StatefulWidget {
  final String comment;
  final Timestamp timestamp;
  final String blogId;
  final String username;
  final String userId;
  final String replyTo;


  const CommentWidget({
    Key? key,
    required this.comment,
    required this.timestamp,
    required this.blogId,
    required this.username,
    required this.userId,
    required this.replyTo,
  }) : super(key: key);
  @override
  _CommentWidgetState createState() => _CommentWidgetState();
}

class _CommentWidgetState extends State<CommentWidget> {
  bool showReplyInput = false;
  TextEditingController replyController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.comment),
        Row(
          children: [
            Text(
              dateTimeFormatter(widget.timestamp),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const Text(
              " • ",
              style: TextStyle(
                fontSize: 30,
                color: Colors.grey,
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  showReplyInput = !showReplyInput;
                });
              },
              child: const Text(
                "Reply",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
        if (showReplyInput)
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: replyController,
                  maxLines: null,
                  decoration: const InputDecoration(
                    labelText: 'Reply to comment',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () async {
                  if (replyController.text.isNotEmpty) {
                    await FirebaseFirestore.instance
                        .collection('comments')
                        .add({
                      'user_id': ,
                      'blog_id': widget.blogId,
                      'comment': replyController.text,
                      'created_at': DateTime.now(),
                      'updated_at': DateTime.now(),
                      'username': user['username'],
                      'reply_to': '',
                    });
                    replyController.clear();
                  }
                },
              ),
            ],
          ),
      ],
    );
  }
}
