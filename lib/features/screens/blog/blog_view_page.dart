// ignore_for_file: use_build_context_synchronously

import 'package:blog/authentication.dart';
import 'package:blog/utils/init_dynamic_links.dart';
import 'package:blog/utils/redirect_profile_service.dart';
import 'package:blog/widgets/comment_widget.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share/share.dart';

class BlogView extends StatefulWidget {
  final AuthenticationBloc authBloc;
  final String blogId;

  const BlogView({
    super.key,
    required this.blogId,
    required this.authBloc,
  });

  @override
  State<BlogView> createState() => _BlogViewState();
}

class _BlogViewState extends State<BlogView> {
  final formKey = GlobalKey<FormState>();
  final commentController = TextEditingController();
  int commentLimit = 5; // Initial limit for comments to display
  List<DocumentSnapshot> comments = []; // List to hold fetched comments
  @override
  Widget build(BuildContext context) {
    final commentController = TextEditingController(text: '');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blog Details'),
        actions: [
          IconButton(
            onPressed: () async {
              String link = await FirebaseDynamicLinksService.createDynamicLink(
                false,
                widget.blogId,
              );
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
            final username = blogData['username'];
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
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
                  Row(
                    children: [
                      const Text(
                        "Posted by: ",
                        style: TextStyle(fontSize: 16),
                      ),
                      GestureDetector(
                        onTap: () async {
                          if (await redirectProfileService(
                              blogData['user_id'])) {
                            Navigator.pushNamed(context, '/my-profile');
                            return;
                          } else {
                            Navigator.pushNamed(context, '/user-profile',
                                arguments: blogData['user_id']);
                          }
                        },
                        child: Text(': @$username',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.blue)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Add a comment form
                  Form(
                    key: formKey,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: commentController,
                            maxLines: null,
                            validator: (value) => value!.isEmpty
                                ? 'Please enter a comment'
                                : null,
                            decoration: const InputDecoration(
                              labelText: 'Add a comment',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) {
                              return;
                            }
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
                                'likes': [],
                                'dislikes': [],
                              });
                              commentController.clear();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  // Display comments
                  const Text('Comments', style: TextStyle(fontSize: 20)),
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('comments')
                        .where('blog_id', isEqualTo: widget.blogId)
                        .orderBy('created_at', descending: true)
                        .limit(commentLimit)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData ||
                          snapshot.data!.docs.isEmpty) {
                        return const Center(
                            child: Text(
                                'No comments yet. Be the first to comment!'));
                      } else {
                        comments = snapshot.data!.docs;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (int i = 0; i < comments.length; i++)
                              CommentWidget(comment: comments[i]),
                            if (comments.length >= commentLimit)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    commentLimit += 5;
                                  });
                                },
                                child: const Text('Show more replies'),
                              ),
                          ],
                        );
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
}
