// ignore_for_file: avoid_print

import 'package:blog/authentication.dart';
import 'package:blog/features/models/message.dart';
import 'package:blog/utils/encryption_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:blog/secrets/fcm_server_key.dart';

class MessageHelper {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Future<void> _sendNotification(String receiverId, String message) async {
    try {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .where('user_id', isEqualTo: receiverId)
          .get()
          .then((value) => value.docs.first);
      final userdata = userDoc.data();
      String receiverToken = (userdata as Map<String, dynamic>)['fcmToken'];
      final senderDetails = await AuthenticationBloc().getUserDetails();
      final senderName = senderDetails['username'];
      if (receiverToken.isNotEmpty) {
        await http.post(Uri.parse('https://fcm.googleapis.com/fcm/send'),
            headers: {
              HttpHeaders.contentTypeHeader: 'application/json',
              HttpHeaders.authorizationHeader: FcmSecrets.serverKey,
            },
            body: jsonEncode({
              'to': receiverToken,
              'notification': {
                'title': "Message from $senderName",
                'body': message,
              },
            }));
      }
    } catch (e) {
      print(e);
      throw e;
    }
  }

  Future<void> sendMessage(
    String message,
    String senderId,
    String receiverId,
  ) async {
    try {
      final encrptedMessage = EncryptionHelper.encryptMessage(message);
      const type = MessageType.text;
      Messages newMsg = Messages(
        message: encrptedMessage,
        senderId: senderId,
        receiverId: receiverId,
        type: type,
        timestamp: Timestamp.now(),
        isEncrypted: true,
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
          .add(newMsg.toMap());
      await _firestore.collection('chatRooms').doc(chatRoomId).set({
        'lastMessage': encrptedMessage,
        'timestamp': Timestamp.now(),
        'unread': true,
        'type': 'text',
        'users': [senderId, receiverId],
        'senderName': senderDetails['username'],
        'senderUserId': senderDetails['user_id'],
        'receiverName': receiverDetails['username'],
        'receiverUserId': receiverDetails['user_id'],
      });
      await _sendNotification(receiverId, message);
    } catch (e) {
      print(e);
    }
  }

  Future<void> sendImageMessage(
    File? _image,
    String senderId,
    String receiverId,
  ) async {
    try {
      Reference ref = FirebaseStorage.instance
          .ref()
          .child('chat_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      UploadTask uploadTask = ref.putFile(_image!);
      TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
      String imageUrl = await taskSnapshot.ref.getDownloadURL();
      Messages newMsg = Messages(
        message: imageUrl,
        imageUrl: imageUrl,
        senderId: senderId,
        receiverId: receiverId,
        type: MessageType.image,
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
          .add(newMsg.toMap());
      await _firestore.collection('chatRooms').doc(chatRoomId).set({
        'lastMessage': imageUrl,
        'timestamp': Timestamp.now(),
        'users': [senderId, receiverId],
        'unread': true,
        'type': "image",
        'senderName': senderDetails['username'],
        'senderUserId': senderDetails['user_id'],
        'receiverName': receiverDetails['username'],
        'receiverUserId': receiverDetails['user_id'],
      });
      await _sendNotification(receiverId, 'Image');
    } catch (e) {
      print(e);
      throw e;
    }
  }

  Future<void> sendAudioMessage(
    File? _audio,
    String senderId,
    String receiverId,
  ) async {
    try {
      Reference ref = FirebaseStorage.instance
          .ref()
          .child('chat_audios/${DateTime.now().millisecondsSinceEpoch}.mp3');
      UploadTask uploadTask = ref.putFile(_audio!);
      TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
      String audioUrl = await taskSnapshot.ref.getDownloadURL();
      Messages newMsg = Messages(
        message: audioUrl,
        audioUrl: audioUrl,
        senderId: senderId,
        receiverId: receiverId,
        type: MessageType.audio,
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
          .add(newMsg.toMap());
      await _firestore.collection('chatRooms').doc(chatRoomId).set({
        'lastMessage': audioUrl,
        'timestamp': Timestamp.now(),
        'users': [senderId, receiverId],
        'unread': true,
        'type': 'audio',
        'senderName': senderDetails['username'],
        'senderUserId': senderDetails['user_id'],
        'receiverName': receiverDetails['username'],
        'receiverUserId': receiverDetails['user_id'],
      });
      await _sendNotification(receiverId, 'Audio');
    } catch (e) {
      print(e);
      throw e;
    }
  }

  Future<void> sendVideoMessage(
    File? _video,
    String senderId,
    String receiverId,
  ) async {
    try {
      Reference ref = FirebaseStorage.instance
          .ref()
          .child('chat_videos/${DateTime.now().millisecondsSinceEpoch}.mp4');
      UploadTask uploadTask = ref.putFile(_video!);
      TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
      String videoUrl = await taskSnapshot.ref.getDownloadURL();
      Messages newMsg = Messages(
        message: videoUrl,
        videoUrl: videoUrl,
        senderId: senderId,
        receiverId: receiverId,
        type: MessageType.video,
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
          .add(newMsg.toMap());
      await _firestore.collection('chatRooms').doc(chatRoomId).set({
        'lastMessage': videoUrl,
        'timestamp': Timestamp.now(),
        'users': [senderId, receiverId],
        'unread': true,
        'type': 'video',
        'senderName': senderDetails['username'],
        'senderUserId': senderDetails['user_id'],
        'receiverName': receiverDetails['username'],
        'receiverUserId': receiverDetails['user_id'],
      });
      await _sendNotification(receiverId, 'Video');
    } catch (e) {
      print(e);
      throw e;
    }
  }

  Future<void> sendDocumentMessage(
    File? _document,
    String senderId,
    String receiverId,
  ) async {
    try {
      Reference ref = FirebaseStorage.instance
          .ref()
          .child('chat_documents/${DateTime.now().millisecondsSinceEpoch}.pdf');
      UploadTask uploadTask = ref.putFile(_document!);
      TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
      String documentUrl = await taskSnapshot.ref.getDownloadURL();
      Messages newMsg = Messages(
        message: documentUrl,
        documentUrl: documentUrl,
        senderId: senderId,
        receiverId: receiverId,
        type: MessageType.document,
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
          .add(newMsg.toMap());
      await _firestore.collection('chatRooms').doc(chatRoomId).set({
        'lastMessage': documentUrl,
        'timestamp': Timestamp.now(),
        'users': [senderId, receiverId],
        'unread': true,
        'type': 'document',
        'senderName': senderDetails['username'],
        'senderUserId': senderDetails['user_id'],
        'receiverName': receiverDetails['username'],
        'receiverUserId': receiverDetails['user_id'],
      });
      await _sendNotification(receiverId, 'Document');
    } catch (e) {
      print(e);
      throw e;
    }
  }
}
