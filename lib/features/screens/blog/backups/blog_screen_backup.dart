import 'package:blog/authentication.dart';
import 'package:blog/utils/firebase_dynamic_links.dart';
import 'package:blog/features/screens/blog/backups/reply_comments.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share/share.dart';

class BlogView extends StatefulWidget {
  final AuthenticationBloc authBloc;
  final String blogId;

  const BlogView({required this.blogId, required this.authBloc});

  @override
  State<BlogView> createState() => _BlogViewState();
}

class _BlogViewState extends State<BlogView> {
  @override
  Widget build(BuildContext context) {
    final commentController = TextEditingController(text: '');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blog Details'),
        actions: [
          IconButton(
            onPressed: () async {
              // Share the blog
              String link = await FirebaseDynamicLinkService.createDynamicLink(
                  widget.blogId);
              await Share.share(link);
            },
            icon: const Icon(
              Icons.share,
            ),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('blogs')
            .doc(widget.blogId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.hasData && snapshot.data!.exists) {
            final blogData = snapshot.data!;
            final title = blogData['title'];
            final content = blogData['content'];
            final image = blogData['image_url'];
            final commentsRef = blogData.data().toString().contains('comments')
                ? blogData['comments']
                : [];
            _fetchComments(commentsRef, widget.blogId);
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Image.network(
                    image,
                    height: 200,
                    width: double.infinity,
                    loadingBuilder: (BuildContext context, Widget child,
                        ImageChunkEvent? loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      } else {
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      }
                    },
                  ),
                  Text(
                    content,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  const Text('Comments', style: TextStyle(fontSize: 20)),
                  const SizedBox(height: 16),
                  // Comment input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentController,
                          maxLines: null,
                          decoration: const InputDecoration(
                            labelText: 'Add a comment',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () async {
                          final user = await widget.authBloc.getUserDetails();
                          if (commentController.text.isNotEmpty) {
                            await FirebaseFirestore.instance
                                .collection('comments')
                                .add({
                              'user_id': user['user_id'],
                              'blog_id': widget.blogId,
                              'comment': commentController.text,
                              'created_at': DateTime.now(),
                              'updated_at': DateTime.now(),
                              'username': user['username'],
                              'reply_to': '',
                            });
                            commentController.clear();
                            setState(() {
                              _fetchComments(commentsRef, widget.blogId);
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const SizedBox(height: 16),
                  FutureBuilder(
                    future: _fetchComments(commentsRef, widget.blogId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (snapshot.hasData) {
                        final comments =
                            snapshot.data as List<Map<String, dynamic>>;
                        return Column(
                          children: [
                            for (var comment in comments)
                              Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  child: Wrap(
                                    children: [
                                      Row(
                                        children: [
                                          _buildAvatar(comment['username'][0]),
                                          const SizedBox(width: 8),
                                          Text(comment['username'])
                                        ],
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildCommentWidget(
                                            comment, comment['user_id']),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        );
                      } else {
                        return const Center(child: Text('No comments found.'));
                      }
                    },
                  ),
                ],
              ),
            );
          } else {
            return const Center(child: Text('No blog found.'));
          }
        },
      ),
    );
  }

  Widget _buildAvatar(String firstLetter) {
    return Column(
      children: [
        CircleAvatar(
          child: Text(firstLetter),
        ),
      ],
    );
  }

  Widget _buildCommentWidget(Map<String, dynamic> comment, String repliedToId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Display comment content
        CommentWidget(
          comment: comment['comment'],
          timestamp: comment['updated_at'],
          authBloc: widget.authBloc,
          blogId: widget.blogId,
          userId: comment['user_id'],
          replyTo: repliedToId,
        ),
        // Display replies recursively
        if (comment['replies'] != null)
          for (var reply in comment['replies'])
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: _buildCommentWidget(reply, comment['user_id']),
            ),
      ],
    );
  }

  // Inside the _buildCommentWidget method in the BlogView class

  Future<List<Map<String, dynamic>>> _fetchComments(
      List<dynamic> commentsRef, String blogId,
      {int depth = 0, Set<String>? visitedIds}) async {
    visitedIds ??= {};
    try {
      final commentDocs = await FirebaseFirestore.instance
          .collection('comments')
          .where('blog_id', isEqualTo: blogId)
          .get();
      Map<String, List<Map<String, dynamic>>> commentsMap = {};
      for (var doc in commentDocs.docs) {
        final comment = doc.data();
        final replyTo = comment['reply_to'] ?? ''; // Get the reply_to field
        if (!commentsMap.containsKey(replyTo)) {
          commentsMap[replyTo] = [];
        }
        commentsMap[replyTo]!.add(comment);
      }
      List<Map<String, dynamic>> topLevelComments = commentsMap[''] ?? [];
      List<Map<String, dynamic>> buildCommentTree(String parentId,
          {int depth = 0}) {
        List<Map<String, dynamic>> comments = [];
        if (depth < 10 && commentsMap.containsKey(parentId)) {
          // Limit depth to prevent infinite recursion
          for (var comment in commentsMap[parentId]!) {
            if (!visitedIds!.contains(comment['user_id'])) {
              // Check for circular references
              visitedIds.add(comment['user_id']);
              comment['replies'] =
                  buildCommentTree(comment['user_id'], depth: depth + 1);
              comments.add(comment);
            }
          }
        }
        return comments;
      }

      topLevelComments.forEach((comment) {
        comment['replies'] =
            buildCommentTree(comment['user_id'], depth: depth + 1);
      });
      return topLevelComments;
    } catch (e) {
      throw Exception('Error fetching comments: $e');
    }
  }
}


//   Widget _buildComment(
//     String comment,
//     Timestamp timestamp,
//     String replyTo,
//     String blogId,
//     String userId,
//   ) {
//     return CommentWidget(
//       comment: comment,
//       timestamp: timestamp,
//       authBloc: widget.authBloc,
//       blogId: blogId,
//       replyTo: replyTo,
//       userId: userId,
//     );
//   }
// }

// Future<List<Map<String, dynamic>>> _fetchComments(
  //     List<dynamic> commentsRef, String blogId) async {
  //   try {
  //     final comment = await FirebaseFirestore.instance
  //         .collection('comments')
  //         .where('blog_id', isEqualTo: blogId)
  //         .get();
  //     return comment.docs.map((e) => e.data()).toList();
  //   } catch (e) {
  //     throw Exception('Error fetching comments: $e');
  //   }
  // }


// child: _buildComment(
//   comment['comment'],
//   comment['updated_at'],
//   comment['user_id'],
//   widget.blogId,
//   comments[0]['user_id'],
// ),


// [{blog_id: iVCszj7PKY9u6jegczLl,
// updated_at: Timestamp(seconds=1715667533, 
// nanoseconds=911000000), 
// reply_to: , 
// user_id: Y2qEdbBqx2WjApQNLPxAh7vGd7p1, 
// created_at: Timestamp(seconds=1715667533, 
// nanoseconds=911000000), 
// comment: hello, 
// username: Test User, 
// replies: [{blog_id: iVCszj7PKY9u6jegczLl, 
// reply_to: Y2qEdbBqx2WjApQNLPxAh7vGd7p1,
// updated_at: Timestamp(seconds=1715668101, 
// nanoseconds=868000000), 
// user_id: 9cVNnDMosDT8Xllu7C4l0LwfeUl1, 
// created_at: Timestamp(seconds=1715668101, 
// nanoseconds=868000000), 
// comment: ok, 
// username: Test User 1, 
// replies: []}]}]


