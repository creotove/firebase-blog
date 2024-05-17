// // ignore_for_file: public_member_api_docs, sort_constructors_first
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';

// import 'package:blog/authentication.dart';
// import 'package:blog/utils/date_time_formatter.dart';

// class CommentWidget extends StatefulWidget {
//   final DocumentSnapshot comment;

//   const CommentWidget({super.key, required this.comment});

//   @override
//   _CommentWidgetState createState() => _CommentWidgetState();
// }

// class _CommentWidgetState extends State<CommentWidget> {
//   final replyController = TextEditingController();
//   final replyFocusNode = FocusNode();
//   bool isReplying = false;
//   bool showReplies = false;
//   String? replyingToCommentId;

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
//         // Row(
//         //   children: [
//         //     LikeButton(commentId: commentId, commentData: commentData),
//         //     DislikeButton(commentId: commentId, commentData: commentData),
//         //   ],
//         // ),
//         LikeDislike(commentId: commentId, commentData: commentData),
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
//         if (showReplies && replies.isNotEmpty)
//           ...replies.map((reply) => _buildReplyWidget(reply, username)),
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
//                       replyController.clear();
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
//             setState(() {
//               isReplying = !isReplying;
//               replyingToCommentId = isReplying ? commentId : null;
//               if (isReplying) {
//                 FocusScope.of(context).requestFocus(replyFocusNode);
//               } else {
//                 replyFocusNode.unfocus();
//               }
//             });
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

// class LikeDislike extends StatefulWidget {
//   final String commentId;
//   final Map<String, dynamic> commentData;
//   const LikeDislike({
//     super.key,
//     required this.commentId,
//     required this.commentData,
//   });

//   @override
//   State<LikeDislike> createState() => _LikeDislikeState();
// }

// class _LikeDislikeState extends State<LikeDislike> {
//   late bool isLiked;
//   late int likesCount;
//   late List<dynamic> likes;
//   late bool isDisliked;
//   late int dislikesCount;
//   late List<dynamic> dislikes;

//   @override
//   void initState() {
//     super.initState();
//     likes = widget.commentData['likes'] ?? [];
//     likesCount = likes.length;
//     isLiked = false;
//     _checkIfLiked();
//     dislikes = widget.commentData['dislikes'] ?? [];
//     dislikesCount = dislikes.length;
//     isDisliked = false;
//     _checkIfDisliked();
//   }

//   Future<void> _checkIfLiked() async {
//     final user = await AuthenticationBloc().getUserDetails();
//     final userId = user['user_id'];
//     setState(() {
//       isLiked = likes.contains(userId);
//     });
//   }

//   Future<void> _checkIfDisliked() async {
//     final user = await AuthenticationBloc().getUserDetails();
//     final userId = user['user_id'];
//     setState(() {
//       isDisliked = dislikes.contains(userId);
//     });
//   }

//   Future<void> _toggleLikesDislikes() async {
//     final user = await AuthenticationBloc().getUserDetails();
//     final userId = user['user_id'];
//     if (isLiked) {
//       likes.remove(userId);
//       likesCount--;
//     } else {
//       likes.add(userId);
//       likesCount++;
//     }
//     if (isDisliked) {
//       dislikes.remove(userId);
//       dislikesCount--;
//     } else {
//       dislikes.add(userId);
//       dislikesCount++;
//     }
//     await FirebaseFirestore.instance
//         .collection('comments')
//         .doc(widget.commentId)
//         .update({'likes': likes, 'dislikes': dislikes});
//     setState(() {
//       isLiked = !isLiked;
//       isDisliked = !isDisliked;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         IconButton(
//           icon: Icon(
//             Icons.thumb_up,
//             color: isLiked ? Colors.blue : null,
//           ),
//           onPressed: _toggleLikesDislikes,
//         ),
//         Text('$likesCount'),
//         const SizedBox(width: 8),
//         IconButton(
//           icon: Icon(
//             Icons.thumb_down,
//             color: isDisliked ? Colors.red : null,
//           ),
//           onPressed: _toggleLikesDislikes,
//         ),
//         Text('$dislikesCount'),
//       ],
//     );
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:blog/authentication.dart';
import 'package:blog/utils/date_time_formatter.dart';

class CommentWidget extends StatefulWidget {
  final DocumentSnapshot comment;

  const CommentWidget({super.key, required this.comment});

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
    replyController.dispose();
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
        LikeDislike(commentId: commentId, commentData: commentData),
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
            dateTimeFormatter(reply['created_at']),
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class LikeDislike extends StatefulWidget {
  final String commentId;
  final Map<String, dynamic> commentData;
  const LikeDislike({
    super.key,
    required this.commentId,
    required this.commentData,
  });

  @override
  State<LikeDislike> createState() => _LikeDislikeState();
}

class _LikeDislikeState extends State<LikeDislike> {
  late bool isLiked;
  late int likesCount;
  late List<dynamic> likes;
  late bool isDisliked;
  late int dislikesCount;
  late List<dynamic> dislikes;

  @override
  void initState() {
    super.initState();
    likes = widget.commentData['likes'] ?? [];
    likesCount = likes.length;
    isLiked = false;
    _checkIfLiked();
    dislikes = widget.commentData['dislikes'] ?? [];
    dislikesCount = dislikes.length;
    isDisliked = false;
    _checkIfDisliked();
  }

  Future<void> _checkIfLiked() async {
    final user = await AuthenticationBloc().getUserDetails();
    final userId = user['user_id'];
    setState(() {
      isLiked = likes.contains(userId);
    });
  }

  Future<void> _checkIfDisliked() async {
    final user = await AuthenticationBloc().getUserDetails();
    final userId = user['user_id'];
    setState(() {
      isDisliked = dislikes.contains(userId);
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
      if (isDisliked) {
        dislikes.remove(userId);
        dislikesCount--;
        isDisliked = false;
      }
    }
    await FirebaseFirestore.instance
        .collection('comments')
        .doc(widget.commentId)
        .update({'likes': likes, 'dislikes': dislikes});
    setState(() {
      isLiked = !isLiked;
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
      if (isLiked) {
        likes.remove(userId);
        likesCount--;
        isLiked = false;
      }
    }
    await FirebaseFirestore.instance
        .collection('comments')
        .doc(widget.commentId)
        .update({'likes': likes, 'dislikes': dislikes});
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
            Icons.thumb_up,
            color: isLiked ? Colors.blue : null,
          ),
          onPressed: _toggleLike,
        ),
        Text('$likesCount'),
        const SizedBox(width: 8),
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
