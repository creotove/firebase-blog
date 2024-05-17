// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:blog/theme/app_pallete.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:blog/authentication.dart';

class MyBlogsPage extends StatefulWidget {
  final AuthenticationBloc authBloc;
  const MyBlogsPage({
    super.key,
    required this.authBloc,
  });
  // const MyBlogsPage({super.key});

  @override
  State<MyBlogsPage> createState() => _MyBlogsPageState();
}

class _MyBlogsPageState extends State<MyBlogsPage> {
  late Future<List<DocumentSnapshot>> _myBlogs;

  @override
  void initState() {
    super.initState();
    _myBlogs = _fetchMyBlogs();
  }

  // Future<List<DocumentSnapshot>> _fetchMyBlogs() async {
  //   final user = await widget.authBloc.getUserDetails(); // Use widget.authBloc
  //   final userId = user['user_id'];
  //   final myBlogs = await FirebaseFirestore.instance
  //       .collection('blogs')
  //       .where('user_id', isEqualTo: userId)
  //       .get();

  //   final List<DocumentSnapshot> blogsWithIds = [];
  //   for (var doc in myBlogs.docs) {
  //     print(doc.id);
  //     blogsWithIds.add(doc);
  //   }

  //   return blogsWithIds;
  // }
  Future<List<DocumentSnapshot>> _fetchMyBlogs() async {
    final user = await widget.authBloc.getUserDetails(); // Use widget.authBloc
    final userId = user['user_id'];
    final myBlogs = await FirebaseFirestore.instance
        .collection('blogs')
        .where('user_id', isEqualTo: userId)
        .get();

    // Return the documents as is, as they already contain both data and ID
    return myBlogs.docs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Blogs'),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                  colors: [AppPallete.gradient1, AppPallete.gradient2])),
          child: const Icon(
            Icons.add,
            size: 40,
          ),
        ),
        onPressed: () {
          Navigator.pushNamed(context, '/add-blog');
        },
      ),
      body: FutureBuilder(
        future: _myBlogs,
        builder: (context, AsyncSnapshot<List<DocumentSnapshot>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final myBlogs = snapshot.data!;
          if (myBlogs.isEmpty) {
            return const Center(child: Text('No blogs found.'));
          }
          return ListView.builder(
            itemCount: myBlogs.length,
            itemBuilder: (context, index) {
              final blog = myBlogs[index].data() as Map<String, dynamic>;
              final blogId = myBlogs[index].id;
              return GestureDetector(
                onTap: () {
                  showModalBottomSheet<void>(
                    context: context,
                    builder: (BuildContext context) {
                      return SizedBox(
                        height: 400,
                        width: double.infinity,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const SizedBox(
                                height: 20,
                              ),
                              Text(
                                blog['title'],
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/blog-edit',
                                    arguments: blogId,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  width: double.infinity,
                                  margin: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    border: Border.all(
                                      color: Colors.blueAccent,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Edit"),
                                      Icon(Icons.edit),
                                    ],
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/manage-comments',
                                    arguments: blogId,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  width: double.infinity,
                                  margin: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    border: Border.all(
                                      color: Colors.blueAccent,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Comments Mgmt."),
                                      Icon(Icons.manage_accounts_outlined),
                                    ],
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {});
                                  FirebaseFirestore.instance
                                      .collection('blogs')
                                      .doc(blogId)
                                      .delete();
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  width: double.infinity,
                                  margin: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    border: Border.all(
                                      color: Colors.redAccent,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Delete"),
                                      Icon(Icons.delete),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                child: ListTile(
                    title: Text(blog['title']),
                    subtitle: Text(blog['content']),
                    trailing: const Icon(
                      Icons.more_vert,
                    )),
              );
            },
          );
        },
      ),
    );
  }
}
