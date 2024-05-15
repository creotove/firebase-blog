// import 'package:blog/authentication.dart';
// import 'package:blog/utils/date_time_formatter.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';

// class CommentWidget extends StatefulWidget {
//   final DocumentSnapshot comment;

//   const CommentWidget({required this.comment});

//   @override
//   _CommentWidgetState createState() => _CommentWidgetState();
// }

// class _CommentWidgetState extends State<CommentWidget> {
//   final replyController = TextEditingController();
//   final replyFocusNode = FocusNode();
//   bool isReplying = false;
//   bool showReplies = false;
//   String? replyingToCommentId; // Track the comment being replied to

//   @override
//   void dispose() {
//     replyFocusNode.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final commentData = widget.comment.data() as Map<String, dynamic>;
//     final commentId = widget.comment.id;
//     final commentText = commentData['comment'];
//     final createdAt = commentData['created_at'];
//     final username = commentData['username'];
//     final List<dynamic> replies = commentData['replies'] ?? [];

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             const Icon(Icons.account_circle),
//             const SizedBox(width: 8),
//             Text(
//               username,
//               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//           ],
//         ),
//         Container(
//           padding: const EdgeInsets.only(left: 35.0),
//           child: Text(
//             commentText,
//             style: const TextStyle(fontSize: 16),
//           ),
//         ),
//         Text(
//           dateTimeFormatter(createdAt).toString(),
//           style: const TextStyle(color: Colors.grey),
//         ),
//         // Show likes and dislikes
//         Row(
//           children: [
//             FutureBuilder(
//               future: AuthenticationBloc().getUserDetails(),
//               builder: (context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Row(
//                     children: [
//                       IconButton(
//                         icon: Icon(Icons.thumb_up),
//                         onPressed: null,
//                       ),
//                       Text('0'),
//                       IconButton(
//                         icon: Icon(Icons.thumb_down),
//                         onPressed: null,
//                       ),
//                       Text('0'),
//                     ],
//                   );
//                 }

//                 final user = snapshot.data!;
//                 final userId = user['user_id'];
//                 final likes = commentData['likes'] ?? [];
//                 final dislikes = commentData['dislikes'] ?? [];
//                 final isLiked = likes.contains(userId);
//                 final isDisliked = dislikes.contains(userId);

//                 return Row(
//                   children: [
//                     IconButton(
//                       icon: Icon(
//                         Icons.thumb_up,
//                         color: isLiked ? Colors.blue : null,
//                       ),
//                       onPressed: () async {
//                         if (isLiked) {
//                           likes.remove(userId);
//                         } else {
//                           likes.add(userId);
//                           dislikes.remove(userId);
//                         }
//                         await FirebaseFirestore.instance
//                             .collection('comments')
//                             .doc(commentId)
//                             .update({
//                           'likes': likes,
//                           'dislikes': dislikes,
//                         });
//                         setState(() {});
//                       },
//                     ),
//                     Text('${likes.length}'),
//                     IconButton(
//                       icon: Icon(
//                         Icons.thumb_down,
//                         color: isDisliked ? Colors.red : null,
//                       ),
//                       onPressed: () async {
//                         if (isDisliked) {
//                           dislikes.remove(userId);
//                         } else {
//                           dislikes.add(userId);
//                           likes.remove(userId);
//                         }
//                         await FirebaseFirestore.instance
//                             .collection('comments')
//                             .doc(commentId)
//                             .update({
//                           'likes': likes,
//                           'dislikes': dislikes,
//                         });
//                         setState(() {});
//                       },
//                     ),
//                     Text('${dislikes.length}'),
//                   ],
//                 );
//               },
//             ),
//           ],
//         ),
//         // Show option to view replies
//         if (replies.isNotEmpty)
//           TextButton(
//             onPressed: () {
//               setState(() {
//                 showReplies = !showReplies;
//               });
//             },
//             child: Text(showReplies
//                 ? 'Hide replies'
//                 : 'Show replies (${replies.length})'),
//           ),
//         // Show replies if option is enabled
//         if (showReplies && replies.isNotEmpty)
//           ...replies.map((reply) => _buildReplyWidget(reply, username)),
//         // Add reply button

//         // Show reply text field if replying to this comment
//         if (isReplying && replyingToCommentId == commentId)
//           Form(
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextFormField(
//                     controller: replyController,
//                     focusNode: replyFocusNode,
//                     maxLines: null,
//                     decoration: const InputDecoration(
//                       labelText: 'Your reply',
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.send),
//                   onPressed: () async {
//                     if (replyController.text.isNotEmpty) {
//                       final user = await AuthenticationBloc().getUserDetails();
//                       // Add reply to Firestore
//                       final newReply = {
//                         'user_id': user['user_id'],
//                         'reply': replyController.text,
//                         'created_at': DateTime.now(),
//                       };
//                       replies.add(newReply);
//                       await FirebaseFirestore.instance
//                           .collection('comments')
//                           .doc(commentId)
//                           .update({'replies': replies});
//                       // Clear reply text field
//                       replyController.clear();
//                       // Close reply field
//                       setState(() {
//                         isReplying = false;
//                         replyingToCommentId = null;
//                       });
//                     }
//                   },
//                 ),
//               ],
//             ),
//           ),
//         TextButton(
//           onPressed: () {
//             if (isReplying) {
//               setState(() {
//                 isReplying = false;
//                 replyingToCommentId = null; // Clear the replying comment ID
//                 replyFocusNode.unfocus(); // Unfocus the reply text field
//               });
//             } else {
//               setState(() {
//                 isReplying = true;
//                 replyingToCommentId = commentId; // Set the replying comment ID
//               });
//               FocusScope.of(context).requestFocus(replyFocusNode);
//             }
//           },
//           child: Text(isReplying ? 'Cancel' : 'Reply'),
//         ),
//       ],
//     );
//   }

//   Widget _buildReplyWidget(reply, String username) {
//     return Padding(
//       padding: const EdgeInsets.only(left: 16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               const Icon(Icons.account_circle),
//               // const SizedBox(width: 8),
//               Text(
//                 username,
//                 style:
//                     const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//               ),
//             ],
//           ),
//           Container(
//             padding: const EdgeInsets.only(left: 35.0),
//             child: Text(
//               reply['reply'],
//               style: const TextStyle(fontSize: 14),
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             '${dateTimeFormatter(reply['created_at'])}',
//             style: const TextStyle(color: Colors.grey, fontSize: 12),
//           ),
//         ],
//       ),
//     );
//   }
// }

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
  String? replyingToCommentId;

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
        Row(
          children: [
            LikeButton(commentId: commentId, commentData: commentData),
            DislikeButton(commentId: commentId, commentData: commentData),
          ],
        ),
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
        if (showReplies && replies.isNotEmpty)
          ...replies.map((reply) => _buildReplyWidget(reply, username)),
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
                      replyController.clear();
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
            setState(() {
              isReplying = !isReplying;
              replyingToCommentId = isReplying ? commentId : null;
              if (isReplying) {
                FocusScope.of(context).requestFocus(replyFocusNode);
              } else {
                replyFocusNode.unfocus();
              }
            });
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

class LikeButton extends StatefulWidget {
  final String commentId;
  final Map<String, dynamic> commentData;

  const LikeButton({required this.commentId, required this.commentData});

  @override
  _LikeButtonState createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> {
  late bool isLiked;
  late int likesCount;
  late List<dynamic> likes;

  @override
  void initState() {
    super.initState();
    likes = widget.commentData['likes'] ?? [];
    likesCount = likes.length;
    isLiked = false;
    _checkIfLiked();
  }

  Future<void> _checkIfLiked() async {
    final user = await AuthenticationBloc().getUserDetails();
    final userId = user['user_id'];
    setState(() {
      isLiked = likes.contains(userId);
    });
  }

  Future<void> _toggleLike() async {
    final user = await AuthenticationBloc().getUserDetails();
    final userId = user['user_id'];
    if (isLiked) {
      likes.remove(userId);
      likesCount--;
    } else {
      likes.add(userId);
      likesCount++;
    }
    await FirebaseFirestore.instance
        .collection('comments')
        .doc(widget.commentId)
        .update({'likes': likes});
    setState(() {
      isLiked = !isLiked;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            Icons.thumb_up,
            color: isLiked ? Colors.blue : null,
          ),
          onPressed: _toggleLike,
        ),
        Text('$likesCount'),
      ],
    );
  }
}

class DislikeButton extends StatefulWidget {
  final String commentId;
  final Map<String, dynamic> commentData;

  const DislikeButton({required this.commentId, required this.commentData});

  @override
  _DislikeButtonState createState() => _DislikeButtonState();
}

class _DislikeButtonState extends State<DislikeButton> {
  late bool isDisliked;
  late int dislikesCount;
  late List<dynamic> dislikes;

  @override
  void initState() {
    super.initState();
    dislikes = widget.commentData['dislikes'] ?? [];
    dislikesCount = dislikes.length;
    isDisliked = false;
    _checkIfDisliked();
  }

  Future<void> _checkIfDisliked() async {
    final user = await AuthenticationBloc().getUserDetails();
    final userId = user['user_id'];
    setState(() {
      isDisliked = dislikes.contains(userId);
    });
  }

  Future<void> _toggleDislike() async {
    final user = await AuthenticationBloc().getUserDetails();
    final userId = user['user_id'];
    if (isDisliked) {
      dislikes.remove(userId);
      dislikesCount--;
    } else {
      dislikes.add(userId);
      dislikesCount++;
    }
    await FirebaseFirestore.instance
        .collection('comments')
        .doc(widget.commentId)
        .update({'dislikes': dislikes});
    setState(() {
      isDisliked = !isDisliked;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            Icons.thumb_down,
            color: isDisliked ? Colors.red : null,
          ),
          onPressed: _toggleDislike,
        ),
        Text('$dislikesCount'),
      ],
    );
  }
}
