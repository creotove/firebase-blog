import 'dart:io';

import 'package:blog/authentication.dart';
import 'package:blog/constants.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

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

class CallArguments {
  final AuthenticationBloc authBloc;
  final String avatar;
  final String receiverName;
  final String roomId;
  final String currentUserId;
  final String receiverUserId;
  final DuringCallStatus callStatus;
  final MediaStream? localStream;
  final MediaStream? remoteStream;

  CallArguments({
    required this.avatar,
    required this.receiverName,
    required this.authBloc,
    required this.roomId,
    required this.currentUserId,
    required this.receiverUserId,
    required this.callStatus,
    this.localStream,
    this.remoteStream,
  });
}
