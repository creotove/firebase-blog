import 'dart:io';

import 'package:blog/authentication.dart';

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

class SendVideoArguments {
  final File video;
  final String? currentUserId;
  final String? receiverUserId;

  SendVideoArguments({
    required this.video,
    this.currentUserId,
    this.receiverUserId,
  });
}

class MessageNotificationArgs {
  final String receiverUserId;
  final String senderUserId;
  final String route;
  final AuthenticationBloc authBloc;

  MessageNotificationArgs({
    required this.receiverUserId,
    required this.senderUserId,
    required this.route,
    required this.authBloc,
  });
}
