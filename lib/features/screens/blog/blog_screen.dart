import 'package:blog/authentication.dart';
import 'package:blog/utils/firebase_dynamic_links.dart';
import 'package:flutter/services.dart'; // Import flutter services for Share
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share/share.dart';

class BlogView extends StatelessWidget {
  final AuthenticationBloc authBloc;
  final String blogId;

  const BlogView({required this.blogId, required this.authBloc});

  @override
  Widget build(BuildContext context) {
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
            // Access other fields as needed
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
                  // Display more details if needed
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
}
