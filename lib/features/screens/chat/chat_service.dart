import 'package:blog/authentication.dart';
import 'package:blog/features/models/message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> sendMessage(
    String message,
    String senderId,
    String receiverId,
  ) async {
    try {
      Message newMessage = Message(
        message: message,
        senderId: senderId,
        receiverId: receiverId,
        timestamp: Timestamp.now(),
      );

      List<String> ids = [senderId, receiverId];
      ids.sort();
      String chatRoomId = '${ids[0]}_${ids[1]}';
      final senderDetails = await AuthenticationBloc().getUserDetailsById(
        senderId,
      );
      final receiverDetails = await AuthenticationBloc().getUserDetailsById(
        receiverId,
      );
      await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .add(newMessage.toMap());
      await _firestore.collection('chatRooms').doc(chatRoomId).set({
        'lastMessage': message,
        'timestamp': Timestamp.now(),
        'users': [senderId, receiverId],
        'senderName': senderDetails['username'],
        'receiverName': receiverDetails['username'],
      });
      await _sendNotification(receiverId, message);
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

  Future<void> _sendNotification(String receiverId, String message) async {
    try {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .where('user_id', isEqualTo: receiverId)
          .get()
          .then((value) => value.docs.first);
      print(userDoc.data());
      final userdata = userDoc.data();
      String token = (userdata as Map<String, dynamic>)['fcmToken'];
      print(token);

      if (token != null && token.isNotEmpty) {
        await FirebaseMessaging.instance.sendMessage(
          to: token,
          data: {
            'type': 'chat',
            'message': message,
          },
        );
        print('Notification sent to $receiverId');
        print('==================Yes=====================');
      }
    } catch (e) {
      print('==================No=====================');
      print(e);
    }
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

  Future<List<Map<String, String>>> getChatRoomsForUser() async {
    try {
      final chatRoomIds = await getAllChatRooms();
      final loggedInUser = await AuthenticationBloc().getUserDetails();
      String senderId = loggedInUser['user_id'];
      List<String> receiverIds = [];
      for (var chatRoomId in chatRoomIds) {
        DocumentSnapshot chatRoomDoc =
            await _firestore.collection('chatRooms').doc(chatRoomId).get();
        List<dynamic> users = chatRoomDoc['users'];

        String receiverUserId = users[0] == senderId ? users[1] : users[0];
        receiverIds.add(receiverUserId);
      }
      List<Map<String, String>> chatRooms = [];
      for (var receiverId in receiverIds) {
        final userDoc =
            await AuthenticationBloc().getUserDetailsById(receiverId);
        chatRooms.add({
          'userId': receiverId,
          'username': userDoc['username'],
          'avatar': userDoc['avatar'] ??
              'https://www.w3schools.com/howto/img_avatar.png',
        });
      }
      return chatRooms;
    } catch (e) {
      print(e);
      throw e;
    }
  }
}
