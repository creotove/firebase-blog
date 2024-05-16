import 'package:blog/utils/date_time_formatter.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:blog/authentication.dart';

class ManageCommentsPage extends StatefulWidget {
  final AuthenticationBloc authBloc;
  final String blogId;

  const ManageCommentsPage({
    required this.authBloc,
    required this.blogId,
    super.key,
  });

  @override
  State<ManageCommentsPage> createState() => _ManageCommentsPageState();
}

class _ManageCommentsPageState extends State<ManageCommentsPage> {
  late Stream<QuerySnapshot> _commentsStream;

  @override
  void initState() {
    super.initState();
    _commentsStream = FirebaseFirestore.instance
        .collection('comments')
        .where('blog_id', isEqualTo: widget.blogId)
        .snapshots();
  }

  void _deleteComment(String commentId) async {
    await FirebaseFirestore.instance
        .collection('comments')
        .doc(commentId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Comments'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _commentsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No comments found for this blog.'),
            );
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final comment = snapshot.data!.docs[index];
                return ListTile(
                  title: Text('Comment : ${comment['comment']}'),
                  subtitle: Text('By - @${comment["username"]}'
                      ' ${dateTimeFormatter(comment["created_at"])}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteComment(comment.id),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
