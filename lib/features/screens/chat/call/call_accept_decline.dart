// ignore_for_file: library_private_types_in_public_api, avoid_print, use_build_context_synchronously, deprecated_member_use

import 'package:blog/authentication.dart';
import 'package:blog/constants.dart';
import 'package:blog/features/screens/blog/home_page.dart';
import 'package:blog/utils/perms_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'audio_signaling.dart';
import 'dart:async';

class CallScreen extends StatefulWidget {
  final AuthenticationBloc authBloc;
  final DuringCallStatus initialCallStatus;
  final String avatar;
  final String receiverName;
  final String roomId;
  final String currentUserId;
  final String receiverUserId;
  final MediaStream? localStream;

  const CallScreen({
    super.key,
    required this.initialCallStatus,
    required this.avatar,
    required this.receiverName,
    required this.roomId,
    required this.currentUserId,
    required this.receiverUserId,
    required this.authBloc,
    this.localStream,
  });

  @override
  _CallScreenState createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late DuringCallStatus _callStatus;
  final AudioSignaling _signaling = AudioSignaling();
  final FlutterRingtonePlayer ringtonePlayer = FlutterRingtonePlayer();
  Timer? _callTimer;

  @override
  void initState() {
    super.initState();
    _callStatus = widget.initialCallStatus;

    _startRinging();
    _startCallTimeout();

    // Listen for hangup from the other side
    _signaling.roomSubscription = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) {
        _hangUpLocal();
        _stopRinging();
        _hangUp();
        return;
      }
      var data = snapshot.data() as Map<String, dynamic>;
      if (data['hangup'] == true) {
        _hangUpLocal();
      }
      if (data['pickedUp'] == true) {
        setState(() {
          _callStatus = DuringCallStatus.accepted;
        });
      }
    });
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    ringtonePlayer.stop();
    _signaling.roomSubscription?.cancel();
    super.dispose();
  }

  void _startRinging() {
    if (_callStatus == DuringCallStatus.ringing) {
      ringtonePlayer.playRingtone();
    }
  }

  void _stopRinging() {
    ringtonePlayer.stop();
  }

  void _startCallTimeout() {
    _callTimer = Timer(const Duration(seconds: 60), () {
      if (_callStatus != DuringCallStatus.accepted) {
        _hangUp();
      }
    });
  }

  Future<void> _hangUp() async {
    await _signaling.hangUp(
      widget.roomId,
      widget.localStream!,
    );
    _stopRinging();
    await Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (BuildContext context) {
      return HomePage(
        authBloc: widget.authBloc,
      );
    }), (r) {
      return false;
    });
  }

  Future<bool> _onWillPop() async {
    return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Are you sure?'),
            content: const Text('Do you want to end call'),
            actions: <Widget>[
              TextButton(
                onPressed: () => {Navigator.of(context).pop(false)},
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () async {
                  await _hangUp();
                },
                child: const Text('Yes'),
              ),
            ],
          ),
        )) ??
        false;
  }

  void _hangUpLocal() async {
    await _signaling.hangUp(
      widget.roomId,
      widget.localStream!,
    );
    setState(() {
      _callStatus = DuringCallStatus.declined;
    });
    _stopRinging();
    await Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (BuildContext context) {
      return HomePage(
        authBloc: widget.authBloc,
      );
    }), (r) {
      return false;
    });
  }

  void _acceptCall() async {
    if (await PermsHandler().microphone()) {
      _signaling.joinRoom(widget.roomId).then((_) {
        setState(() {
          _callStatus = DuringCallStatus.accepted;
        });
      });
    }
    _stopRinging();
  }

  void _declineCall() {
    _hangUp();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Call with ${widget.receiverName}'),
        ),
        body: Center(
          child: _buildCallUI(),
        ),
      ),
    );
  }

  Widget _buildCallUI() {
    switch (_callStatus) {
      case DuringCallStatus.calling:
        return _buildCallingUI();
      case DuringCallStatus.accepted:
        return _buildAcceptedUI();
      case DuringCallStatus.ringing:
        return _buildRingingUI();
      case DuringCallStatus.declined:
        return _buildDeclinedUI();
      default:
        return _buildUnknownStateUI();
    }
  }

  Widget _buildCallingUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          backgroundImage: NetworkImage(widget.avatar),
          radius: 50,
        ),
        const SizedBox(height: 20),
        Text(
          'Calling ${widget.receiverName}...',
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(height: 20),
        const CircularProgressIndicator(),
      ],
    );
  }

  Widget _buildAcceptedUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          backgroundImage: NetworkImage(widget.avatar),
          radius: 50,
        ),
        const SizedBox(height: 20),
        Text(
          'In Call with ${widget.receiverName}',
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _hangUp,
          child: const Text('End Call'),
        ),
      ],
    );
  }

  Widget _buildRingingUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          backgroundImage: NetworkImage(widget.avatar),
          radius: 50,
        ),
        const SizedBox(height: 20),
        Text(
          '${widget.receiverName} is calling...',
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _acceptCall,
              child: const Text('Accept'),
            ),
            const SizedBox(width: 20),
            ElevatedButton(
              onPressed: _declineCall,
              child: const Text('Decline'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDeclinedUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          backgroundImage: NetworkImage(widget.avatar),
          radius: 50,
        ),
        const SizedBox(height: 20),
        Text(
          'Call with ${widget.receiverName} was declined',
          style: const TextStyle(fontSize: 24),
        ),
      ],
    );
  }

  Widget _buildUnknownStateUI() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Unknown call state',
          style: TextStyle(fontSize: 24, color: Colors.red),
        ),
      ],
    );
  }
}
