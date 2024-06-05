import 'package:blog/authentication.dart';
import 'package:blog/constants.dart';
import 'package:blog/features/screens/chat/videoCall/new_video_signaling.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

class NewVideoCallScreen extends StatefulWidget {
  final AuthenticationBloc authBloc;
  final DuringCallStatus initialCallStatus;
  final String avatar;
  final String receiverName;
  final String roomId;
  final String currentUserId;
  final String receiverUserId;

  const NewVideoCallScreen({
    super.key,
    required this.authBloc,
    required this.initialCallStatus,
    required this.avatar,
    required this.receiverName,
    required this.roomId,
    required this.currentUserId,
    required this.receiverUserId,
  });

  @override
  _NewVideoCallScreenState createState() => _NewVideoCallScreenState();
}

class _NewVideoCallScreenState extends State<NewVideoCallScreen> {
  late RTCVideoRenderer _localRenderer;
  late RTCVideoRenderer _remoteRenderer;
  late NewVideoSignaling _videoSignaling;
  late DuringCallStatus _callStatus;

  @override
  void initState() {
    super.initState();
    _localRenderer = RTCVideoRenderer();
    _remoteRenderer = RTCVideoRenderer();
    _videoSignaling = NewVideoSignaling(
      widget.roomId,
      widget.currentUserId,
      widget.receiverUserId,
    );

    setState(() {
      _callStatus = widget.initialCallStatus;
    });
    _initializeRenderers();
    _setupSignaling();
    _handleInitialCallStatus();
  }

  Future<void> _initializeRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  Future<void> _setupSignaling() async {
    _videoSignaling.onLocalStream = (stream) {
      print('==================== Local Stream ====================');
      _localRenderer.srcObject = stream;
      print('==================== Local Stream ====================');
    };
    _videoSignaling.onRemoteStream = (stream) {
      print('==================== Remote Stream ====================');
      _remoteRenderer.srcObject = stream;
      print('==================== Remote Stream ====================');
    };
    _videoSignaling.onCallStatusChanged = (status) {
      setState(() {
        _callStatus = status;
      });
    };
    await _videoSignaling.initialize();
  }

  Future<void> _handleInitialCallStatus() async {
    setState(() {
      _callStatus = widget.initialCallStatus;
    });

    if (widget.initialCallStatus == DuringCallStatus.calling) {
      await _videoSignaling.makeCall();
    } else if (widget.initialCallStatus == DuringCallStatus.ringing) {
      FlutterRingtonePlayer().playRingtone();
      _startRingingTimeout();
      setState(() {});
    }
  }

  void _startRingingTimeout() {
    Future.delayed(const Duration(seconds: 30), () {
      if (_callStatus == DuringCallStatus.ringing) {
        _videoSignaling.hangUp();
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _videoSignaling.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (_callStatus == DuringCallStatus.accepted) ...[
            RTCVideoView(_remoteRenderer),
            Positioned(
              right: 10,
              bottom: 10,
              width: 100,
              height: 150,
              child: RTCVideoView(
                _localRenderer,
              ),
            ),
          ] else ...[
            Center(
              child: RTCVideoView(_localRenderer),
            ),
          ],
          if (_callStatus == DuringCallStatus.ringing) ...[
            Positioned(
              top: 50,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  Text("Incoming call from ${widget.receiverName}"),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      await FlutterRingtonePlayer().stop();
                      print('==================== Accepted ====================');
                      await _videoSignaling.acceptCall();
                      print('==================== Accepted ====================');
                    },
                    child: const Text("Accept"),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await FlutterRingtonePlayer().stop();
                      await _videoSignaling.hangUp();
                    },
                    child: const Text("Decline"),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
