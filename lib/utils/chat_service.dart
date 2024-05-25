// ignore_for_file: avoid_print, use_rethrow_when_possible

import 'dart:io';

import 'package:blog/authentication.dart';
import 'package:blog/constants.dart';
import 'package:blog/utils/message_sender_helper.dart';
import 'package:blog/utils/encryption_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class ChatService {
  // Instance of Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Method to send a message
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

  // Get all message for a chat room
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

  // Get all chat rooms Ids for a LoggedIn user
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

  // Get all chat rooms for a LoggedIn user
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

          String otherUserId = chatRoom['senderUserId'] == userLoggedIn
              ? chatRoom['receiverUserId']
              : chatRoom['senderUserId'];

          final userDoc =
              await AuthenticationBloc().getUserDetailsById(otherUserId);

          chatRooms.add({
            'chatRoomId': doc.id,
            'senderUserId': chatRoom['senderUserId'],
            'receiverId': chatRoom['receiverUserId'],
            'username': userDoc['username'],
            'avatar': userDoc['avatar'] ?? ConstantsHelper.defaultAavatar,
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

  //  Deltes messsages from the chat room
  Future<bool> deleteSelectedMessages(String currentUserId,
      String receiverUserId, Set<String> selectedMessages) async {
    try {
      final List<String> users = [currentUserId, receiverUserId]..sort();
      final String chatRoomId = '${users[0]}_${users[1]}';

      final batch = FirebaseFirestore.instance.batch();

      for (final messageId in selectedMessages) {
        final messageRef = FirebaseFirestore.instance
            .collection('chatRooms')
            .doc(chatRoomId)
            .collection('messages')
            .doc(messageId);

        final messageSnapshot = await messageRef.get();
        if (messageSnapshot.exists) {
          final messageData = messageSnapshot.data() as Map<String, dynamic>;

          // Determine if the current user is the sender or receiver of the message
          final bool isSender = messageData['senderId'] == currentUserId;

          if (isSender && currentUserId == receiverUserId) {
            batch.update(messageRef, {'isDeletedBySender': true});
          } else if (!isSender && currentUserId == receiverUserId) {
            batch.update(messageRef, {'isDeletedByReceiver': true});
          } else if (isSender && currentUserId != receiverUserId) {
            batch
                .update(messageRef, {'isDeletedBySender': true, 'likedBy': []});
            print('Updatd 3');
          } else if (!isSender && currentUserId != receiverUserId) {
            final likedBy = messageData['likedBy'] as List<dynamic>;
            if (likedBy.contains(currentUserId)) {
              likedBy.remove(currentUserId);
            }
            batch.update(
                messageRef, {'isDeletedByReceiver': true, 'likedBy': likedBy});
          }
        }
      }

      await batch.commit();
      return true;
    } catch (e) {
      print('Error deleting messages: $e');
      return false;
    }
  }

  // Helper method to pick a audio file
  Future<File?> pickAudio() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  // Helper method to pick a document file that can be audio, video, pdf, etc
  Future<File?> pickDocument() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  // Helper method to pick an image file
  Future<File?> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  // Helper method to pick a video file
  Future<File?> pickVideo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null) {
      return File(result.files.single.path!);
    }
    return null;
  }
}
