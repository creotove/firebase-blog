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
    Message newMessage = Message(
      message: message,
      senderId: senderId,
      receiverId: receiverId,
      timestamp: Timestamp.now(),
    );

    List<String> ids = [senderId, receiverId];
    ids.sort();
    String chatRoomId = '${ids[0]}_${ids[1]}';
    await _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .add(newMessage.toMap());
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
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(receiverId).get();
      String? token = userDoc['fcmToken'];

      if (token != null) {
        await FirebaseMessaging.instance.sendMessage(
          to: token,
          data: {
            'type': 'chat',
            'message': message,
          },
        );
      }
    } catch (e) {
      print("User does not have an FCM token set.");
      print(e);
    }
  }
}

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';

// class ChatService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   Future<void> sendMessage(
//       String message, String senderId, String receiverId) async {
//     await _firestore.collection('messages').add({
//       'message': message,
//       'senderId': senderId,
//       'receiverId': receiverId,
//       'timestamp': FieldValue.serverTimestamp(),
//     });

//     // Send notification to the receiver
//     await _sendNotification(receiverId, message);
//   }

//   Stream<QuerySnapshot> getMessages(String currentUserId, String receiverId) {
//     return _firestore
//         .collection('messages')
//         .where('senderId', isEqualTo: currentUserId)
//         .where('receiverId', isEqualTo: receiverId)
//         .orderBy('timestamp', descending: true)
//         .snapshots();
//   }

  // Future<void> _sendNotification(String receiverId, String message) async {
  //   try {
  //     DocumentSnapshot userDoc =
  //         await _firestore.collection('users').doc(receiverId).get();
  //     String? token = userDoc['fcmToken'];

  //     if (token != null) {
  //       await FirebaseMessaging.instance.sendMessage(
  //         to: token,
  //         data: {
  //           'type': 'chat',
  //           'message': message,
  //         },
         
  //       );
  //     }
  //   } catch (e) {
  //     print("User does not have an FCM token set.");
  //     print(e);
  //   }
  // }
// }
