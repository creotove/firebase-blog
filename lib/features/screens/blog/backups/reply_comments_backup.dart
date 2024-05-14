import 'package:blog/authentication.dart';
import 'package:blog/utils/date_time_formatter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CommentWidget extends StatefulWidget {
  final AuthenticationBloc authBloc;
  final String comment;
  final Timestamp timestamp;
  final String blogId;
  final String userId;
  final String replyTo;

  const CommentWidget({
    Key? key,
    required this.comment,
    required this.timestamp,
    required this.authBloc,
    required this.blogId,
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
                    final user = await widget.authBloc.getUserDetails();
                    print(user['user_id']);
                    print(widget.replyTo);
                    return;
                    await FirebaseFirestore.instance
                        .collection('comments')
                        .add({
                      'user_id': user['user_id'],
                      'blog_id': widget.blogId,
                      'comment': replyController.text.trim(),
                      'created_at': DateTime.now(),
                      'updated_at': DateTime.now(),
                      'username': user['username'],
                      'reply_to': widget.replyTo,
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

// class CommentWidget extends StatefulWidget {
//   final AuthenticationBloc authBloc;
//   final String comment;
//   final Timestamp timestamp;
//   final String blogId;
//   final String userId;
//   final String replyTo;

//   const CommentWidget({
//     Key? key,
//     required this.comment,
//     required this.timestamp,
//     required this.authBloc,
//     required this.blogId,
//     required this.userId,
//     required this.replyTo,
//   }) : super(key: key);

//   @override
//   _CommentWidgetState createState() => _CommentWidgetState();
// }

// class _CommentWidgetState extends State<CommentWidget> {
//   bool showReplyInput = false;
//   TextEditingController replyController = TextEditingController();

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Text(widget.comment),
//           ],
//         ),
//         Row(
//           children: [
//             Text(
//               dateTimeFormatter(widget.timestamp),
//               style: const TextStyle(
//                 fontSize: 12,
//                 color: Colors.grey,
//               ),
//             ),
//             const Text(
//               " • ",
//               style: TextStyle(
//                 fontSize: 30,
//                 color: Colors.grey,
//               ),
//             ),
//             GestureDetector(
//               onTap: () {
//                 setState(() {
//                   showReplyInput = !showReplyInput;
//                 });
//               },
//               child: const Text(
//                 "Reply",
//                 style: TextStyle(
//                   fontSize: 12,
//                   color: Colors.grey,
//                 ),
//               ),
//             ),
//           ],
//         ),
//         if (showReplyInput)
//           Row(
//             children: [
//               Expanded(
//                 child: TextField(
//                   controller: replyController,
//                   maxLines: null,
//                   decoration: const InputDecoration(
//                     labelText: 'Reply to comment',
//                     border: OutlineInputBorder(),
//                   ),
//                 ),
//               ),
//               IconButton(
//                 icon: const Icon(Icons.send),
//                 onPressed: () async {
//                   if (replyController.text.isNotEmpty) {
//                     final user = await widget.authBloc.getUserDetails();
//                     await FirebaseFirestore.instance
//                         .collection('comments')
//                         .add({
//                       'user_id': user['user_id'],
//                       'blog_id': widget.blogId,
//                       'comment': replyController.text.trim(),
//                       'created_at': DateTime.now(),
//                       'updated_at': DateTime.now(),
//                       'username': user['username'],
//                       'reply_to': widget.replyTo,
//                     });
//                     replyController.clear();
//                   }
//                 },
//               ),
//             ],
//           ),
//         // Display replies recursively
//         FutureBuilder(
//           future: _fetchReplies(),
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return CircularProgressIndicator();
//             } else if (snapshot.hasError) {
//               return Text('Error: ${snapshot.error}');
//             } else {
//               final replies = snapshot.data as List<Map<String, dynamic>>;
//               return Column(
//                 children: [
//                   for (var reply in replies)
//                     Padding(
//                       padding: const EdgeInsets.only(left: 16.0),
//                       child: CommentWidget(
//                         comment: reply['comment'],
//                         timestamp: reply['updated_at'],
//                         authBloc: widget.authBloc,
//                         blogId: widget.blogId,
//                         userId: reply['user_id'],
//                         replyTo: reply['reply_to'],
//                       ),
//                     ),
//                 ],
//               );
//             }
//           },
//         ),
//       ],
//     );
//   }

//   Future<List<Map<String, dynamic>>> _fetchReplies() async {
//     try {
//       final repliesSnapshot = await FirebaseFirestore.instance
//           .collection('comments')
//           .where('reply_to', isEqualTo: widget.userId)
//           .get();
//       for (var doc in repliesSnapshot.docs) {
//         print(doc.data());
//       }
//       return repliesSnapshot.docs.map((doc) => doc.data()).toList();
//     } catch (e) {
//       throw Exception('Error fetching replies: $e');
//     }
//   }
// }
