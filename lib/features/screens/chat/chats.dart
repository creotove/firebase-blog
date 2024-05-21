// ignore_for_file: use_build_context_synchronously

import 'package:blog/authentication.dart';
import 'package:blog/features/screens/chat/chat.dart';
import 'package:blog/features/screens/chat/chat_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatsPage extends StatefulWidget {
  final AuthenticationBloc authBloc;

  const ChatsPage({Key? key, required this.authBloc}) : super(key: key);

  @override
  _ChatsPageState createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  late Stream<List<Map<String, dynamic>>> _chatRoomsStream;

  @override
  void initState() {
    super.initState();
    _chatRoomsStream = ChatService().getChatRoomsStreamForUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _chatRoomsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (snapshot.data?.isEmpty ?? true) {
              return const Center(
                child: Text('No chats found!'),
              );
            } else {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final chatRoom = snapshot.data![index];
                  final String lastMessage = chatRoom['lastMessage'];
                  final bool unread = chatRoom['unread'];
                  final DateTime timestamp = chatRoom['timestamp'];

                  final Duration difference =
                      DateTime.now().difference(timestamp);
                  final bool isRecent = difference.inDays < 1;
                  final String timeDisplay = isRecent
                      ? timeago.format(timestamp)
                      : '${timestamp.month}/${timestamp.day}/${timestamp.year}';
                  final receiverUserId = chatRoom['receiverId'];
                  return Column(
                    children: [
                      Card(
                        elevation: 5,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text(chatRoom['username']!),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Last message: $timeDisplay',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(chatRoom['avatar']!),
                          ),
                          trailing: unread
                              ? const Icon(
                                  Icons.mark_chat_unread,
                                  color: Colors.red,
                                )
                              : const Icon(
                                  Icons.mark_chat_read,
                                  color: Colors.green,
                                ),
                          onTap: () async {
                            final loggedInUserDetails =
                                await widget.authBloc.getUserDetails();
                            final loggedInUserId =
                                loggedInUserDetails['user_id'];
                            if (receiverUserId == loggedInUserId) {
                              await FirebaseFirestore.instance
                                  .collection('chatRooms')
                                  .doc(chatRoom['chatRoomId'])
                                  .update({
                                'unread': false,
                              });
                            }
                            if (receiverUserId == loggedInUserId) {
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (context) {
                                return ChatPage(
                                  receiverUserId: chatRoom['senderUserId'],
                                  authBloc: widget.authBloc,
                                  currentUserId: loggedInUserDetails['user_id'],
                                );
                              }));
                            } else {
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (context) {
                                return ChatPage(
                                  receiverUserId: chatRoom['receiverId'],
                                  authBloc: widget.authBloc,
                                  currentUserId: loggedInUserDetails['user_id'],
                                );
                              }));
                            }
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
