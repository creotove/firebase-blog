import 'package:blog/authentication.dart';
import 'package:blog/theme/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final AuthenticationBloc authBloc;

  const HomePage({required this.authBloc});

  @override
  Widget build(BuildContext context) {
    void handleClick(String value) async {
      switch (value) {
        case 'Logout':
          await authBloc.signOut();
          Navigator.popAndPushNamed(context, '/login');
          break;
        case 'Profile':
          Navigator.pushNamed(context, '/profile');
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
              return {'Profile', 'Logout'}.map((String choice) {
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
        child: const Icon(Icons.add),
        backgroundColor: Colors.redAccent,
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
                child: ListTile(
                  tileColor: Colors.grey[800],
                  title: Text(blog['title']),
                  subtitle: Text(blog['content']),
                  // You can add more details like date, author, etc. here
                ),
              );
            },
          );
        }
        return const Center(child: Text('No blogs found.'));
      },
    );
  }
}
