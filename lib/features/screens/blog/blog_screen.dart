import 'package:blog/authentication.dart';
import 'package:blog/utils/date_time_formatter.dart';
import 'package:blog/utils/firebase_dynamic_links.dart';
import 'package:flutter/services.dart'; // Import flutter services for Share
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:share/share.dart';

class BlogView extends StatelessWidget {
  final AuthenticationBloc authBloc;
  final String blogId;

  const BlogView({required this.blogId, required this.authBloc});

  @override
  Widget build(BuildContext context) {
    final _commentController = TextEditingController(
        text:
            ' sample comment sample comment sample comment sample comment sample comment sample comment sample comment sample comment sample comment sample comment sample comment sample comment sample comment sample comment sample comment sample comment sample comment sample comment sample comment sample comment sample comment sample comment sample comment sample comment sample comment sample comment');
    return Scaffold(
      appBar: AppBar(
        title: Text('Blog Details'),
        actions: [
          IconButton(
            onPressed: () async {
              // Share the blog
              String link =
                  await FirebaseDynamicLinkService.createDynamicLink(blogId);
              await Share.share(link);
              print(await authBloc.getUserDetails());
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
            .doc(blogId)
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
            final comments = blogData.data().toString().contains('comments')
                ? blogData['comments']
                : [];
            return SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
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
                          controller: _commentController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Add a comment',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () async {
                          final user = await authBloc.getUserDetails();
                          if (_commentController.text.isNotEmpty) {
                            await FirebaseFirestore.instance
                                .collection('blogs')
                                .doc(blogId)
                                .update({
                              'comments': FieldValue.arrayUnion([
                                {
                                  'comment': _commentController.text,
                                  'timestamp': DateTime.now(),
                                  'username': user['username'],
                                  'user_id': user['user_id']
                                }
                              ])
                            });
                            _commentController.clear();
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Display comments
                  Column(
                    children: [
                      for (var comment in comments)
                        Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Container(
                            child: Row(
                              children: [
                                Column(
                                  children: [
                                    CircleAvatar(
                                      child: Text(comment['username'][0]),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      comment['username'],
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                    Text(comment['comment']),
                                    Text(
                                      dateTimeFormatter(comment['timestamp']),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  )
                ],
              ),
            );
          } else {
            return Center(child: Text('No blog found.'));
          }
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchComments(
      List<dynamic> commentsRef) async {
    try {
      print("================");
      List<Map<String, dynamic>> comments = [];
      for (var commentRef in commentsRef) {
        DocumentSnapshot commentSnapshot = await commentRef.get();
        if (commentSnapshot.exists) {
          Map<String, dynamic> commentData =
              commentSnapshot.data() as Map<String, dynamic>;
          comments.add(commentData);
        }
      }
      return comments;
    } catch (e) {
      throw e;
    }
  }
}
