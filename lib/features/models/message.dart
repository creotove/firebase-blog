import 'package:cloud_firestore/cloud_firestore.dart';

// Model for the messages
enum MessageType {
  text,
  image,
  video,
  audio,
  document,
}

class Messages {
  final String message;
  final String senderId;
  final String receiverId;
  final Timestamp timestamp;
  final bool isLiked = false;
  final bool unread = true;
  final String? imageUrl;
  final String? videoUrl;
  final String? audioUrl;
  final String? documentUrl;
  final MessageType type;
  final likedBy = [];
  final bool isEncrypted;
  final bool isDeltedBySender = false;
  final bool isDeltedByReceiver = false;

  Messages({
    required this.message,
    required this.senderId,
    required this.receiverId,
    required this.timestamp,
    this.imageUrl,
    this.videoUrl,
    this.audioUrl,
    this.documentUrl,
    required this.type,
    this.isEncrypted = false,
  });

  // Convert the message to a map. This will be used to store the message in the Firestore
  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'senderId': senderId,
      'receiverId': receiverId,
      'timestamp': timestamp,
      'isLiked': isLiked,
      'unread': unread,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'audioUrl': audioUrl,
      'documentUrl': documentUrl,
      'likedBy': likedBy,
      'type': type.toString().split('.').last,
      'isEncrypted': isEncrypted,
      'isDeletedBySender': isDeltedBySender,
      'isDeletedByReceiver': isDeltedByReceiver,
    };
  }
}
