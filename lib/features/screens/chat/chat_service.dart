// ignore_for_file: avoid_print, use_rethrow_when_possible

import 'package:blog/authentication.dart';
import 'package:blog/utils/encryption_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
              .getUserDetailsById(chatRoom['receiverUserId']);

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
        print(chatRooms);
        return chatRooms;
      });
    } catch (e) {
      print(e);
      throw e;
    }
  }
}
