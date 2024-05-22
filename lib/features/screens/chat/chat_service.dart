// ignore_for_file: avoid_print, use_rethrow_when_possible

import 'dart:io';

import 'package:blog/authentication.dart';
import 'package:blog/features/screens/chat/message_sender_helper.dart';
import 'package:blog/utils/encryption_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void sendMessage(
    String message,
    String senderUserId,
    String receiverUserId,
  ) async {
    try {
      if (message.isNotEmpty) {
        await MessageHelper().sendMessage(
          message,
          senderUserId,
          receiverUserId,
        );
      }
    } catch (e) {
      print(e);
      throw e;
    }
  }

  Stream<QuerySnapshot> getMessages(String senderId, String receiverId) {
    List<String> ids = [senderId, receiverId];
    ids.sort();
    String chatRoomId = '${ids[0]}_${ids[1]}';

    return _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<List<String>> getAllChatRooms() async {
    try {
      final AuthenticationBloc authBloc = AuthenticationBloc();
      final userDetails = await authBloc.getUserDetails();
      String userId = userDetails['user_id'];
      QuerySnapshot querySnapshot = await _firestore
          .collection('chatRooms')
          .where('users', arrayContains: userId)
          .get();

      final List<String> chatRoomIds = [];

      for (var doc in querySnapshot.docs) {
        chatRoomIds.add(doc.id);
      }
      return chatRoomIds;
    } catch (e) {
      print(e);
      throw e;
    }
  }

  Stream<List<Map<String, dynamic>>> getChatRoomsStreamForUser() async* {
    try {
      final loggedInUser = await AuthenticationBloc().getUserDetails();
      String userLoggedIn = loggedInUser['user_id'];

      yield* _firestore
          .collection('chatRooms')
          .where('users', arrayContains: userLoggedIn)
          .snapshots()
          .asyncMap((snapshot) async {
        List<Map<String, dynamic>> chatRooms = [];
        for (var doc in snapshot.docs) {
          final chatRoom = doc.data();

          final userDoc = await AuthenticationBloc()
              .getUserDetailsById(chatRoom['senderUserId']);
          chatRooms.add({
            'chatRoomId': doc.id,
            'senderUserId': chatRoom['senderUserId'],
            'receiverId': chatRoom['receiverUserId'],
            'username': userDoc['username'],
            'avatar': userDoc['avatar'] ??
                'https://www.w3schools.com/howto/img_avatar.png',
            'lastMessage': chatRoom['type'] == 'text'
                ? EncryptionHelper.decryptMessage(chatRoom['lastMessage'])
                : 'Attachment',
            'unread': chatRoom['unread'],
            'timestamp': chatRoom['timestamp'].toDate(),
          });
        }
        return chatRooms;
      });
    } catch (e) {
      throw e;
    }
  }

  Future<bool> deleteSelectedMessages(String senderUserId,
      String receiverUserId, Set<String> selectedMessages) async {
    try {
      List<String> ids = [senderUserId, receiverUserId];
      ids.sort();
      String chatRoomId = '${ids[0]}_${ids[1]}';

      bool allDeleted = true;

      // Fetch messages to verify ownership and for updating last message
      var messagesCollection = FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages');

      var messagesSnapshot = await messagesCollection
          .where(FieldPath.documentId, whereIn: selectedMessages.toList())
          .get();

      if (messagesSnapshot.docs.any((doc) => doc['senderId'] != senderUserId)) {
        // If any message is not sent by the sender, deny deletion
        print('Error: User can only delete their own messages');
        return false;
      }

      // Delete messages in a transaction
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        for (var messageDoc in messagesSnapshot.docs) {
          transaction.delete(messageDoc.reference);
        }
      });

      // Check and update the last message in chat room
      var lastMessageSnapshot = await messagesCollection
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (lastMessageSnapshot.docs.isNotEmpty) {
        var lastMessageData = lastMessageSnapshot.docs.first.data();
        await FirebaseFirestore.instance
            .collection('chatRooms')
            .doc(chatRoomId)
            .update({
          'lastMessage': lastMessageData,
        });
      } else {
        // If no messages left, update last message field to null
        await FirebaseFirestore.instance
            .collection('chatRooms')
            .doc(chatRoomId)
            .update({
          'lastMessage': null,
        });
      }

      print('All messages deleted: $allDeleted');
      return allDeleted;
    } catch (e) {
      print('Error in deleteSelectedMessages: $e');
      return false;
    }
  }

  Future<File?> pickAudio() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  Future<File?> pickDocument() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  Future<File?> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }
}
