import 'package:blog/features/screens/chat/chat.dart';
import 'package:blog/widgets/gradient_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:blog/authentication.dart';
import 'package:flutter/material.dart';

class UserProfilePage extends StatefulWidget {
  final AuthenticationBloc authBloc;
  final String userId;

  const UserProfilePage({
    required this.authBloc,
    required this.userId,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  late Stream<QuerySnapshot> _userBlogsStream;
  late Future<DocumentSnapshot> _userDetailsFuture;

  @override
  void initState() {
    super.initState();
    _userBlogsStream = FirebaseFirestore.instance
        .collection('blogs')
        .where('user_id', isEqualTo: widget.userId)
        .snapshots();
    _userDetailsFuture = _getUserDetails();
  }

  Future<DocumentSnapshot> _getUserDetails() async {
    return await FirebaseFirestore.instance
        .collection('users')
        .where('user_id', isEqualTo: widget.userId)
        .get()
        .then((QuerySnapshot querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first;
      } else {
        throw 'User not found';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _userDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('User not found.'));
          } else {
            final user = snapshot.data!;
            final username = user['username'];
            final email = user['email'];
            final avatar = user.toString().contains('avatar')
                ? user['avatar']
                : 'https://www.w3schools.com/howto/img_avatar.png';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 16.0),
                        height: 100,
                        width: 100,
                        child: CircleAvatar(
                          backgroundImage: NetworkImage(avatar),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Username: $username',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Email: $email',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Container(
                            alignment: Alignment.center,
                            margin: const EdgeInsets.only(top: 16.0),
                            child: GradientButton(
                                varient: 'small',
                                buttonText: 'Message',
                                onPressed: () async {
                                  final currentUser =
                                      await widget.authBloc.getUserDetails();
                                  final userId = currentUser['user_id'];

                                  Navigator.push(context,
                                      MaterialPageRoute(builder: (context) {
                                    return ChatPage(
                                      receiverUserId: widget.userId,
                                      currentUserId: userId,
                                      authBloc: AuthenticationBloc(),
                                    );
                                  }));
                                }),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _userBlogsStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData ||
                          snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text('This user has no blogs.'),
                        );
                      } else {
                        return ListView.builder(
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            final blog = snapshot.data!.docs[index];
                            return ListTile(
                              title: Text(blog['title']),
                              subtitle: Text(blog['content']),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/blog-view',
                                  arguments: blog.id,
                                );
                              },
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
