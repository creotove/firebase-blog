import 'dart:io';

class SendImageArguments {
  final File image;
  final String? currentUserId;
  final String? receiverUserId;

  SendImageArguments({
    required this.image,
    this.currentUserId,
    this.receiverUserId,
  });
}

class SendAudioArguments {
  final File audio;
  final String? currentUserId;
  final String? receiverUserId;

  SendAudioArguments({
    required this.audio,
    this.currentUserId,
    this.receiverUserId,
  });
}

class SendDocumentArguments {
  final File document;
  final String? currentUserId;
  final String? receiverUserId;

  SendDocumentArguments({
    required this.document,
    this.currentUserId,
    this.receiverUserId,
  });
}
