import 'dart:math';

import 'package:blog/authentication.dart';
import 'package:blog/utils/date_time_formatter.dart';
import 'package:blog/utils/redirect_profile_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  final AuthenticationBloc authBloc;

  const HomePage({super.key, required this.authBloc});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    void handleClick(String value) async {
      switch (value) {
        case 'My Blogs':
          Navigator.pushNamed(context, '/my-blogs');
          break;
        case 'Logout':
          await widget.authBloc.signOut();
          Navigator.popAndPushNamed(context, '/login');
          break;
        case 'Profile':
          Navigator.pushNamed(context, '/my-profile');
          break;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blog'),
        actions: [
          PopupMenuButton<String>(
            onSelected: handleClick,
            itemBuilder: (BuildContext context) {
              return {'My Blogs', 'Profile', 'Logout'}.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add-blog');
        },
        backgroundColor: Colors.redAccent,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildBlogList(),
      ),
    );
  }

  Widget _buildBlogList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('blogs').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.hasData) {
          final blogs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: blogs.length,
            itemBuilder: (context, index) {
              final blog = blogs[index];
              return GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/blog-view',
                    arguments: blog.id,
                  );
                },
                child: Card(
                  elevation: 5,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      blog['title'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      _truncateContent(blog['content']),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    // Add more details such as date and author if available
                    trailing: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            if (await redirectProfileService(blog['user_id'])) {
                              Navigator.pushNamed(context, '/my-profile');
                              return;
                            } else {
                              Navigator.pushNamed(context, '/user-profile',
                                  arguments: blog['user_id']);
                            }
                          },
                          child: RichText(
                            text: TextSpan(text: 'by: ', children: [
                              TextSpan(
                                text: '@${blog['username']}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.blue,
                                ),
                              ),
                            ]),
                          ),
                        ),
                        Text(
                          dateTimeFormatter(blog['created_at']),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }
        return const Center(child: Text('No blogs found.'));
      },
    );
  }

  String _truncateContent(String content) {
    if (content.length > 50) {
      return content.substring(0, 50) + '...';
    } else {
      return content;
    }
  }
}
