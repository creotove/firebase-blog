// import 'package:cloud_firestore/cloud_firestore.dart';

// class Messages {
//   final String message;
//   final String senderId;
//   final String receiverId;
//   final Timestamp timestamp;
//   final bool isLiked = false;
//   final bool unread = true;
//   final String? imageUrl;
//   final String? videoUrl;
//   final String? audioUrl;
//   enum type{
//     'text',
//     'image',
//     'video',
//     'audio',
//   };

//   Messages({
//     required this.message,
//     required this.senderId,
//     required this.receiverId,
//     required this.timestamp,
//     this.imageUrl,
//     this.videoUrl,
//     this.audioUrl,
//     required this.type,
//   });

//   Map<String, dynamic> toMap() {
//     return {
//       'message': message,
//       'senderId': senderId,
//       'receiverId': receiverId,
//       'timestamp': timestamp,
//       'isLiked': isLiked,
//       'unread': unread,
//       'imageUrl': imageUrl,
//       'videoUrl': videoUrl,
//       'audioUrl': audioUrl,
//       'type': type,
//     };
//   }
// }
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final bool isEncrypted;

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
      'type': type.toString().split('.').last,
      'isEncrypted': isEncrypted,
    };
  }
}
