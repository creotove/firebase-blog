// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:blog/constants.dart';
import 'package:blog/features/screens/chat/call/audio_signaling.dart';
import 'package:blog/features/screens/chat/videoCall/video_call_signaling.dart';
import 'package:blog/utils/argument_helper.dart.dart';
import 'package:blog/utils/chat_service.dart';
import 'package:blog/utils/encryption_helper.dart';
import 'package:blog/utils/file_picker_helper.dart';
import 'package:blog/utils/message_sender_helper.dart';
import 'package:blog/utils/perms_handler.dart';
import 'package:blog/widgets/build_message_content.dart';
import 'package:blog/widgets/chat_send_file.dart';
import 'package:blog/widgets/text_filed.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:blog/authentication.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatPage extends StatefulWidget {
  final AuthenticationBloc authBloc;
  final String receiverUserId;
  final String currentUserId;

  const ChatPage({
    super.key,
    required this.authBloc,
    required this.receiverUserId,
    required this.currentUserId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final ValueNotifier<Set<String>> _selectedMessages = ValueNotifier<Set<String>>({});
  bool _selectionMode = false;
  late String receiverAvatar;
  late String receiverUserName;
  AudioSignaling audioSignaling = AudioSignaling();
  VideoSignaling videoSignaling = VideoSignaling();

  void _onMessageLongPress(
    String messageId,
    bool isDeletedByReceiver,
    bool isDeletedBySender,
    bool isMe,
  ) {
    // If the message is deleted by the sender, the receiver can't select it and also sender can't select it
    if (isDeletedBySender) {
      return;
    }
    // If the message is deleted by the receiver, the receiver can't select it but the sender can select it
    if (isDeletedByReceiver && !isMe) {
      return;
    }

    final currentSelection = _selectedMessages.value;
    // If the message is already selected, remove it from the selected messages
    if (currentSelection.contains(messageId)) {
      // If the message is the only selected message, disable the selection mode
      if (currentSelection.length == 1) {
        _selectionMode = false;
        _selectedMessages.value = {};
        return;
      }
      // Otherwise, remove the message from the selected messages
      _selectedMessages.value = Set.from(currentSelection)..remove(messageId);
    } else {
      // If the message is not selected, add it to the selected messages
      _selectedMessages.value = Set.from(currentSelection)..add(messageId);
      // If it's the first message to be selected, enable the selection mode
      _selectionMode = true;
    }
  }

  // Method to toggle like on a message
  Future<void> toggleLike(
    String messageId,
    bool isDeletedByReceiver,
    bool isDeletedBySender,
    bool isMe,
  ) async {
    // If the message is deleted by the sender, the receiver can't like it and also sender can't like it
    if (isDeletedBySender) {
      return;
    }
    // If the message is deleted by the receiver, the receiver can't like it but the sender can like it
    if (isDeletedByReceiver) {
      return;
    }

    final currentUserId = widget.currentUserId;
    final List users = [
      widget.currentUserId,
      widget.receiverUserId
    ];
    users.sort();
    // Update the message with the new likedBy list
    final messageRef = FirebaseFirestore.instance.collection('chatRooms').doc(users[0] + '_' + users[1]).collection('messages').doc(messageId);
    final messageDoc = await messageRef.get();
    if (messageDoc.exists) {
      List<dynamic> likedBy = messageDoc['likedBy'] ?? [];
      if (likedBy.contains(currentUserId)) {
        likedBy.remove(currentUserId);
      } else {
        likedBy.add(currentUserId);
      }
      await messageRef.update({
        'likedBy': likedBy
      });
    }
  }

  // Method to check if a message is liked if the message is liked then show the like icon
  bool isMessageLiked(Map<String, dynamic> message) {
    List<dynamic> likedBy = message['likedBy'] ?? [];
    if (likedBy.isNotEmpty) {
      return true;
    } else {
      return false;
    }
  }

  // Getting the receiver user details for displaying their name and avatar
  Future<Map<String, dynamic>> fetchReceiverDetails() async {
    final userDetails = await widget.authBloc.getUserDetailsById(widget.receiverUserId);
    return userDetails;
  }

  // Getting the current user id
  Future<String> getCurrentUser() async {
    final userDetails = await widget.authBloc.getUserDetails();
    if (userDetails.isEmpty) {
      Navigator.pushNamed(context, '/login');
      return '';
    }
    final currentUserId = userDetails['user_id'];
    return currentUserId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<Map<String, dynamic>>(
          future: fetchReceiverDetails(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Loading...', style: TextStyle(fontSize: 16));
            } else if (snapshot.hasError) {
              return const Text('Error');
            } else {
              final receiverDetails = snapshot.data!;
              final receiverName = receiverDetails['username'];
              receiverAvatar = receiverDetails['avatar'] ?? ConstantsHelper.defaultAavatar;
              receiverUserName = receiverDetails['username'];
              return GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/user-profile',
                    arguments: receiverDetails['user_id'],
                  );
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(receiverDetails['avatar'] ?? ConstantsHelper.defaultAavatar),
                    ),
                    const SizedBox(width: 8.0),
                    Text(receiverName),
                  ],
                ),
              );
            }
          },
        ),
        actions: [
          ValueListenableBuilder<Set<String>>(
            valueListenable: _selectedMessages,
            builder: (context, selectedMessages, child) {
              if (selectedMessages.isEmpty) {
                return Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.videocam),
                      onPressed: () async {
                        try {
                          final localStream = await videoSignaling.openUserMedia();
                          if (await PermsHandler().microphone() && await PermsHandler().camera()) {
                            final roomId = await videoSignaling.createRoom();
                            print('==========================');
                            print("created a room");
                            print('==========================');
                            await MessageHelper().sendVideoCallNotification(widget.receiverUserId, roomId);
                            final arguments = CallArguments(
                              authBloc: widget.authBloc,
                              avatar: receiverAvatar,
                              receiverName: receiverUserName,
                              roomId: roomId,
                              currentUserId: widget.currentUserId,
                              callStatus: DuringCallStatus.calling,
                              receiverUserId: widget.receiverUserId,
                              localStream: localStream,
                            );
                            if (roomId.isNotEmpty) {
                              await Navigator.pushNamed(
                                context,
                                '/video-call-accept-and-decline',
                                arguments: arguments,
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Permission denied'),
                              ),
                            );
                          }
                        } catch (e) {
                          print(e);
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.call),
                      onPressed: () async {
                        try {
                          final localStream = await audioSignaling.openUserMedia();
                          if (await PermsHandler().microphone()) {
                            final roomId = await audioSignaling.createRoom();
                            print("created a room");
                            final arguments = CallArguments(
                              authBloc: widget.authBloc,
                              avatar: receiverAvatar,
                              receiverName: receiverUserName,
                              roomId: roomId,
                              currentUserId: widget.currentUserId,
                              callStatus: DuringCallStatus.calling,
                              receiverUserId: widget.receiverUserId,
                              localStream: localStream,
                            );
                            await MessageHelper().sendCallNotification(widget.receiverUserId, roomId);
                            print("Sent noti redirecting to the call page");
                            if (roomId.isNotEmpty) {
                              await Navigator.pushNamed(
                                context,
                                '/call-accept-and-decline',
                                arguments: arguments,
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Permission denied'),
                              ),
                            );
                          }
                        } catch (e) {
                          print(e);
                        }
                      },
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.cancel),
                    onPressed: () {
                      _selectionMode = false;
                      _selectedMessages.value = {};
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.red,
                    ),
                    onPressed: () async {
                      final deleted = await _chatService.deleteSelectedMessages(widget.currentUserId, widget.receiverUserId, selectedMessages);
                      if (deleted) {
                        _selectionMode = false;
                        _selectedMessages.value = {};
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to delete messages'),
                          ),
                        );
                      }
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessagesList(),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: BlogEditor(
                    controller: _messageController,
                    hintText: 'Type a message...',
                    labelText: 'Message',
                  ),
                ),
                const SizedBox(width: 8.0),
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      builder: (BuildContext context) {
                        return SizedBox(
                          width: double.infinity,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 16.0,
                              runSpacing: 16.0,
                              children: <Widget>[
                                ChatSendFile(
                                  icon: Icons.image_sharp,
                                  text: "Gallery",
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    FilePickerHelper().pickImage(
                                      widget.currentUserId,
                                      widget.receiverUserId,
                                    );
                                  },
                                ),
                                ChatSendFile(
                                  icon: Icons.headphones,
                                  text: "Audio",
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    FilePickerHelper().pickAudio(
                                      widget.currentUserId,
                                      widget.receiverUserId,
                                    );
                                  },
                                ),
                                ChatSendFile(
                                  icon: Icons.insert_drive_file,
                                  text: "Document",
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    FilePickerHelper().pickDocument(
                                      widget.currentUserId,
                                      widget.receiverUserId,
                                    );
                                  },
                                ),
                                ChatSendFile(
                                  icon: Icons.video_library,
                                  text: "Video",
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    FilePickerHelper().pickVideo(
                                      widget.currentUserId,
                                      widget.receiverUserId,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    final message = _messageController.text.trim();
                    if (message.isNotEmpty) {
                      _chatService.sendMessage(
                        message,
                        widget.currentUserId,
                        widget.receiverUserId,
                      );
                      _messageController.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.getMessages(widget.currentUserId, widget.receiverUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No messages'));
        } else {
          final messages = snapshot.data!.docs;
          return Padding(
            padding: const EdgeInsets.all(5.0),
            child: ListView.builder(
              reverse: true,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return ValueListenableBuilder<Set<String>>(
                  valueListenable: _selectedMessages,
                  builder: (context, selectedMessages, child) {
                    return _buildMessageItem(messages[index], selectedMessages);
                  },
                );
              },
            ),
          );
        }
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot document, Set<String> selectedMessages) {
    Map<String, dynamic> message = document.data() as Map<String, dynamic>;
    final messageId = document.id;
    final isMe = message['senderId'] == widget.currentUserId;
    final decryptedMessage = message['isEncrypted'] ? EncryptionHelper.decryptMessage(message['message']) : message['message'];
    final messageType = message['type'];
    final likesCount = message['likedBy']?.length ?? 0;
    final isMessageSelected = selectedMessages.contains(messageId);

    return GestureDetector(
      onTap: () async {
        if (_selectionMode) {
          _onMessageLongPress(document.id, message['isDeletedByReceiver'], message['isDeletedBySender'], isMe);
        } else if (messageType == "image") {
          Navigator.pushNamed(
            context,
            '/show-image',
            arguments: message['imageUrl'],
          );
        } else if (messageType == 'document') {
          final documentUrl = message['documentUrl'];
          if (documentUrl != null) {
            try {
              if (await canLaunchUrl(Uri.parse(documentUrl))) {
                await launchUrl(Uri.parse(documentUrl));
              } else {
                throw 'Could not launch $documentUrl';
              }
            } catch (e) {
              print('Error opening document: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to open document'),
                ),
              );
            }
          }
        }
      },
      onDoubleTap: () async {
        await toggleLike(document.id, message['isDeletedByReceiver'], message['isDeletedBySender'], isMe);
      },
      onLongPress: () {
        _onMessageLongPress(
          document.id,
          message['isDeletedByReceiver'],
          message['isDeletedBySender'],
          isMe,
        );
      },
      child: Container(
        width: double.infinity,
        decoration: isMessageSelected
            ? BoxDecoration(
                color: Colors.blue.withOpacity(0.5),
              )
            : null,
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                BuildMessageContent(
                  isMe: isMe,
                  messageType: messageType,
                  decryptedMessage: decryptedMessage,
                  message: message,
                  isDeletedBySender: message['isDeletedBySender'],
                  isDeletedByReceiver: message['isDeletedByReceiver'],
                ),
                if (likesCount == 0) const SizedBox(height: 0.0),
                if (likesCount == 1)
                  Container(
                      padding: const EdgeInsets.all(5.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50.0),
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 15.0,
                      )),
                if (likesCount > 1)
                  Stack(
                    children: [
                      Container(
                          padding: const EdgeInsets.all(5.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(50.0),
                          ),
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 15.0,
                          )),
                      Container(
                        margin: const EdgeInsets.only(left: 10.0),
                        padding: const EdgeInsets.all(5.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(50.0),
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.red,
                          size: 15.0,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
