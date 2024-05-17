import 'package:blog/authentication.dart';
import 'package:blog/features/screens/chat/chat.dart';
import 'package:blog/features/screens/chat/chat_service.dart';
import 'package:flutter/material.dart';

class ChatsPage extends StatefulWidget {
  final AuthenticationBloc authBloc;
  const ChatsPage({super.key, required this.authBloc});

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder(
          future: ChatService().getChatRoomsForUser(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (snapshot.data == null) {
              return const Center(
                child: Text('No chats found!'),
              );
            } else {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final user = snapshot.data![index];
                  return Column(
                    children: [
                      Card(
                        elevation: 5,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text(user['username']!),
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(user['avatar']!),
                          ),
                          onTap: () async {
                            final loggedInUserDetails =
                                await widget.authBloc.getUserDetails();
                            Navigator.push(context,
                                MaterialPageRoute(builder: (context) {
                              return ChatPage(
                                receiverUserId: user['userId']!,
                                authBloc: AuthenticationBloc(),
                                currentUserId: loggedInUserDetails['user_id'],
                              );
                            }));
                          },
                        ),
                      ),
                      if (index != snapshot.data!.length - 1) const Divider(),
                    ],
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}
