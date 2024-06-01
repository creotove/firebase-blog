// ignore_for_file: library_private_types_in_public_api

import 'package:blog/authentication.dart';
import 'package:blog/constants.dart';
import 'package:blog/features/screens/blog/home_page.dart';
import 'package:blog/utils/perms_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'audio_signaling.dart'; // import your signaling class
import 'dart:async';

class CallScreen extends StatefulWidget {
  final AuthenticationBloc authBloc;
  final DuringCallStatus initialCallStatus;
  final String avatar;
  final String receiverName;
  final String roomId; // Changed to mutable
  final String currentUserId;
  final String receiverUserId;

  const CallScreen({
    super.key,
    required this.initialCallStatus,
    required this.avatar,
    required this.receiverName,
    required this.roomId,
    required this.currentUserId,
    required this.receiverUserId,
    required this.authBloc,
  });

  @override
  _CallScreenState createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late DuringCallStatus _callStatus;
  late AudioSignaling _signaling;
  final FlutterRingtonePlayer ringtonePlayer = FlutterRingtonePlayer();
  Timer? _callTimer;

  @override
  void initState() {
    super.initState();
    _callStatus = widget.initialCallStatus;
    _signaling = AudioSignaling();

    _startRinging();
    _startCallTimeout();

    // Listen for hangup from the other side
    _signaling.roomSubscription = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .snapshots()
        .listen((snapshot) {
      var data = snapshot.data() as Map<String, dynamic>;
      if (data['hangup'] == true) {
        _hangUpLocal();
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

  void _hangUp() {
    _signaling.hangUp(widget.roomId).then((_) {
      setState(() {
        _callStatus = DuringCallStatus.declined;
      });
      _stopRinging();
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (BuildContext context) {
        return HomePage(
          authBloc: widget.authBloc,
        );
      }), (r) {
        return false;
      });
    });
  }

  void _hangUpLocal() {
    setState(() {
      _callStatus = DuringCallStatus.declined;
    });
    _stopRinging();
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (BuildContext context) {
      return HomePage(
        authBloc: widget.authBloc,
      );
    }), (r) {
      return false;
    });
  }

  void _acceptCall() async {
    await _signaling.openUserMedia();
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Call with ${widget.receiverName}'),
      ),
      body: Center(
        child: _buildCallUI(),
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
              // style: ElevatedButton.styleFrom(primary: Colors.red),
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
