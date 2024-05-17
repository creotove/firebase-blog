import 'package:blog/api/firebase_api.dart';
import 'package:blog/authentication.dart';
import 'package:blog/features/screens/chat/chats.dart';
import 'package:blog/features/screens/profile/my_blogs.dart';
import 'package:blog/features/screens/profile/my_profile.dart';
import 'package:blog/theme/app_pallete.dart';
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
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    BlogListPage(),
    MyBlogsPage(authBloc: AuthenticationBloc()),
    ChatsPage(authBloc: AuthenticationBloc()),
    MyProfilePage(authBloc: AuthenticationBloc()),
  ];

  void _onItemTapped(int index) async {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
    });
    if (index == 2) {
      await FirebaseApi().initNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Blogs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article),
            label: 'My Blogs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppPallete.gradient2,
        onTap: _onItemTapped,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
    );
  }
}

class BlogListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blog'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
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
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            GestureDetector(
                              onTap: () async {
                                if (await redirectProfileService(
                                    blog['user_id'])) {
                                  Navigator.pushNamed(context, '/my-profile');
                                } else {
                                  Navigator.pushNamed(
                                    context,
                                    '/user-profile',
                                    arguments: blog['user_id'],
                                  );
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
        ),
      ),
    );
  }

  String _truncateContent(String content) {
    return content.length > 50 ? content.substring(0, 50) + '...' : content;
  }
}
