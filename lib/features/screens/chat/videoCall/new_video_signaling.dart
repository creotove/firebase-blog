// ignore_for_file: avoid_print

import 'dart:async';
import 'package:blog/constants.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NewVideoSignaling {
  final String roomId;
  final String currentUserId;
  final String receiverUserId;
  late RTCPeerConnection _peerConnection;
  late MediaStream _localStream;
  late MediaStream _remoteStream;
  final _firestore = FirebaseFirestore.instance;
  final Map<String, dynamic> _configuration = {
    'iceServers': [
      {
        'urls': [
          'stun:stun.l.google.com:19302',
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302',
          'stun:stun3.l.google.com:19302',
          'stun:stun4.l.google.com:19302',
        ]
      }
    ]
  };

  Function(MediaStream)? onLocalStream;
  Function(MediaStream)? onRemoteStream;
  Function(DuringCallStatus)? onCallStatusChanged;

  NewVideoSignaling(this.roomId, this.currentUserId, this.receiverUserId);

  Future<void> initialize() async {
    try {
      await _createPeerConnection(_configuration);
      await _listenForRoomUpdates();
    } catch (e) {
      print('Error in initialize: $e');
    }
  }

  Future<void> _openUserMedia() async {
    try {
      final Map<String, dynamic> mediaConstraints = {
        'audio': true,
        'video': true,
      };
      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      onLocalStream?.call(_localStream);
      print('Local stream obtained');
    } catch (e) {
      print('Error in openUserMedia: $e');
    }
  }

  Future<void> _createPeerConnection(configuration) async {
    try {
      _peerConnection = await createPeerConnection(configuration);

      _peerConnection.onIceCandidate = (candidate) async {
        print('ICE Candidate: ${candidate.candidate}');
        final candidateCollection = currentUserId == receiverUserId ? 'callerCandidates' : 'calleeCandidates';
        await _firestore.collection('rooms').doc(roomId).collection(candidateCollection).add({
          'candidate': candidate.toMap(),
          'userId': currentUserId,
        });
      };

      _peerConnection.onTrack = (RTCTrackEvent event) {
        event.streams[0].getTracks().forEach((track) {
          _remoteStream.addTrack(track);
        });
        if (onRemoteStream != null) {
          onRemoteStream!(_remoteStream);
        }
      };

      _remoteStream = await createLocalMediaStream('key');

      await _openUserMedia();

      _localStream.getTracks().forEach((track) {
        _peerConnection.addTrack(track, _localStream);
      });

      await _listenForRemoteIceCandidates();
    } catch (e) {
      print('Error in createPeerConnection: $e');
    }
  }

  Future<void> _listenForRemoteIceCandidates() async {
    try {
      final remoteCandidateCollection = currentUserId == receiverUserId ? 'calleeCandidates' : 'callerCandidates';
      await _firestore.collection('rooms').doc(roomId).collection(remoteCandidateCollection).snapshots().listen((snapshot) {
        for (var document in snapshot.docs) {
          var candidate = document.data()['candidate'];
          _peerConnection.addCandidate(RTCIceCandidate(
            candidate['candidate'],
            candidate['sdpMid'],
            candidate['sdpMLineIndex'],
          ));
          print('=================1=======================');
          print('=================2=======================');
          print('=================3=======================');
          print('=================4=======================');
          print('=================5=======================');
          print('Remote ICE candidate added: $candidate');
        }
      });
    } catch (e) {
      print('Error in listenForRemoteIceCandidates: $e');
    }
  }

  Future<void> _listenForRoomUpdates() async {
    try {
      _firestore.collection('rooms').doc(roomId).snapshots().listen((snapshot) {
        final data = snapshot.data();
        if (data != null) {
          if (data['pickedUp'] == true) {
            onCallStatusChanged?.call(DuringCallStatus.accepted);
            print('Call picked up');
          }
          if (data['hungUp'] == true) {
            onCallStatusChanged?.call(DuringCallStatus.declined);
            print('Call hung up');
          }
        }
      });
    } catch (e) {
      print('Error in listenForRoomUpdates: $e');
    }
  }

  Future<void> makeCall() async {
    try {
      await _ensurePeerConnectionInitialized();
      RTCSessionDescription offer = await _peerConnection.createOffer();
      await _peerConnection.setLocalDescription(offer);

      await _firestore.collection('rooms').doc(roomId).set({
        'offer': offer.toMap(),
        'callerId': currentUserId,
        'callerAccepted': false,
      });

      onCallStatusChanged?.call(DuringCallStatus.calling);
      print('Call made with offer: ${offer.sdp}');
    } catch (e) {
      print('Error in makeCall: $e');
    }
  }

  Future<void> acceptCall() async {
    try {
      await _ensurePeerConnectionInitialized();

      final offerSnapshot = await _firestore.collection('rooms').doc(roomId).get();
      if (!offerSnapshot.exists) {
        print('Offer not found');
        return;
      }
      final offer = RTCSessionDescription(offerSnapshot['offer']['sdp'], offerSnapshot['offer']['type']);
      await _peerConnection.setRemoteDescription(offer);

      final answer = await _peerConnection.createAnswer();
      await _peerConnection.setLocalDescription(answer);
      await _firestore.collection('rooms').doc(roomId).update({
        'answer': answer.toMap(),
        'calleeId': currentUserId,
        'callerAccepted': true,
        'pickedUp': true,
      });

      onCallStatusChanged?.call(DuringCallStatus.accepted);
      print('Call accepted with answer: ${answer.sdp}');
    } catch (e) {
      print('Error in acceptCall: $e');
    }
  }

  Future<void> hangUp() async {
    try {
      await _peerConnection.close();
      _firestore.collection('rooms').doc(roomId).update({
        'hungUp': true,
      });
      onCallStatusChanged?.call(DuringCallStatus.declined);
      print('Call hung up');
    } catch (e) {
      print('Error in hangUp: $e');
    } finally {
      _localStream.dispose();
      _peerConnection.dispose();
    }
  }

  Future<void> _ensurePeerConnectionInitialized() async {
    try {
      await _createPeerConnection(_configuration);
    } catch (e) {
      print('Error in ensurePeerConnectionInitialized: $e');
    }
  }

  void dispose() {
    _localStream.dispose();
    _peerConnection.dispose();
  }
}
