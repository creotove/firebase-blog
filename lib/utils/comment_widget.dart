import 'package:blog/authentication.dart';
import 'package:blog/utils/date_time_formatter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CommentWidget extends StatefulWidget {
  final DocumentSnapshot comment;

  const CommentWidget({required this.comment});

  @override
  _CommentWidgetState createState() => _CommentWidgetState();
}

class _CommentWidgetState extends State<CommentWidget> {
  final replyController = TextEditingController();
  final replyFocusNode = FocusNode();
  bool isReplying = false;
  bool showReplies = false;
  String? replyingToCommentId; // Track the comment being replied to

  @override
  void dispose() {
    replyFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commentData = widget.comment.data() as Map<String, dynamic>;
    final commentId = widget.comment.id;
    final commentText = commentData['comment'];
    final createdAt = commentData['created_at'];
    final username = commentData['username'];
    final List<dynamic> replies = commentData['replies'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.account_circle),
            const SizedBox(width: 8),
            Text(
              username,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.only(left: 35.0),
          child: Text(
            commentText,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        Text(
          dateTimeFormatter(createdAt).toString(),
          style: const TextStyle(color: Colors.grey),
        ),
        // Show option to view replies
        if (replies.isNotEmpty)
          TextButton(
            onPressed: () {
              setState(() {
                showReplies = !showReplies;
              });
            },
            child: Text(showReplies
                ? 'Hide replies'
                : 'Show replies (${replies.length})'),
          ),
        // Show replies if option is enabled
        if (showReplies && replies.isNotEmpty)
          ...replies.map((reply) => _buildReplyWidget(reply, username)),
        // Add reply button

        // Show reply text field if replying to this comment
        if (isReplying && replyingToCommentId == commentId)
          Form(
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: replyController,
                    focusNode: replyFocusNode,
                    maxLines: null,
                    decoration: const InputDecoration(
                      labelText: 'Your reply',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    if (replyController.text.isNotEmpty) {
                      final user = await AuthenticationBloc().getUserDetails();
                      // Add reply to Firestore
                      final newReply = {
                        'user_id': user['user_id'],
                        'reply': replyController.text,
                        'created_at': DateTime.now(),
                      };
                      replies.add(newReply);
                      await FirebaseFirestore.instance
                          .collection('comments')
                          .doc(commentId)
                          .update({'replies': replies});
                      // Clear reply text field
                      replyController.clear();
                      // Close reply field
                      setState(() {
                        isReplying = false;
                        replyingToCommentId = null;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        TextButton(
          onPressed: () {
            if (isReplying) {
              setState(() {
                isReplying = false;
                replyingToCommentId = null; // Clear the replying comment ID
                replyFocusNode.unfocus(); // Unfocus the reply text field
              });
            } else {
              setState(() {
                isReplying = true;
                replyingToCommentId = commentId; // Set the replying comment ID
              });
              FocusScope.of(context).requestFocus(replyFocusNode);
            }
          },
          child: Text(isReplying ? 'Cancel' : 'Reply'),
        ),
      ],
    );
  }

  Widget _buildReplyWidget(reply, String username) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_circle),
              const SizedBox(width: 8),
              Text(
                username,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.only(left: 35.0),
            child: Text(
              reply['reply'],
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${dateTimeFormatter(reply['created_at'])}',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
