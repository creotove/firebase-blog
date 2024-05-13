import 'package:blog/authentication.dart';
import 'package:blog/utils/firebase_dynamic_links.dart';
import 'package:blog/utils/reply_comments.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart'; // Import flutter services for Share
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
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
        title: Text('Blog Details'),
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
                  // Display comments
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
                                        child: _buildComment(comment['comment'],
                                            comment['updated_at']),
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

  Widget _buildComment(
    String comment,
    Timestamp timestamp,
    String? replyTo,
    String? username,
    String? blogId,
  ) {
    return CommentWidget(
      comment: comment,
      timestamp: timestamp,
      blogId: blogId,
    );
  }
}

Future<List<Map<String, dynamic>>> _fetchComments(
    List<dynamic> commentsRef, String blogId) async {
  try {
    final comment = await FirebaseFirestore.instance
        .collection('comments')
        .where('blog_id', isEqualTo: blogId)
        .get();
    return comment.docs.map((e) => e.data()).toList();
  } catch (e) {
    throw Exception('Error fetching comments: $e');
  }
}
