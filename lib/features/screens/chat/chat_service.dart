import 'package:blog/features/models/message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
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

    print('=======================Sending messages=======================');
    print('chatRoomId: $chatRoomId');
    print('message sent to: $receiverId');
    print('message sent by: $senderId');

    await FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .add(newMessage.toMap());
  }

  Stream<QuerySnapshot> getMessages(String senderId, String receiverId) {
    List<String> ids = [senderId, receiverId];
    ids.sort();
    String chatRoomId = '${ids[0]}_${ids[1]}';
    print('=======================Fetching messages=======================');
    print('chatRoomId: $chatRoomId');
    print('message sent to: $receiverId');
    print('message sent by: $senderId');

    return FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
