// ignore_for_file: avoid_print, avoid_function_literals_in_foreach_calls

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

typedef StreamStateCallback = void Function(MediaStream stream);

class Signaling {
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
  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;
  String? roomId;
  String? currentRoomText;
  StreamStateCallback? onAddRemoteStream;

  Future<void> openUserMedia(
      RTCVideoRenderer localVideo, RTCVideoRenderer remoteVideo) async {
    var stream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {
        'facingMode': 'user',
      }
    });
    localStream = stream;
    localVideo.srcObject = stream;

    remoteVideo.srcObject = await createLocalMediaStream('key');
  }

  Future<void> hangUp(RTCVideoRenderer localVideo) async {
    List<MediaStreamTrack> tracks = localVideo.srcObject!.getTracks();
    for (var track in tracks) {
      track.stop();
    }

    if (remoteStream != null) {
      remoteStream!.getTracks().forEach((track) {
        track.stop();
      });
    }

    if (peerConnection != null) {
      await peerConnection!.close();
    }
    if (roomId != null) {
      FirebaseFirestore db = FirebaseFirestore.instance;
      DocumentReference roomRef = db.collection('rooms').doc(roomId);
      var calleeCandidates = await roomRef.collection('calleeCandidates').get();
      calleeCandidates.docs.forEach((candidate) async {
        await candidate.reference.delete();
      });
      var callerCandidates = await roomRef.collection('callerCandidates').get();
      callerCandidates.docs.forEach((candidate) async {
        await candidate.reference.delete();
      });
      await roomRef.delete();
    }

    localStream!.dispose();
    remoteStream!.dispose();
  }

  Future<String> createRoom(RTCVideoRenderer remoteRenderer) async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentReference roomRef = db.collection('rooms').doc();

    print('Create PeerConnection with configuration: $_configuration');

    peerConnection = await createPeerConnection(_configuration);

    registerPeerConnectionListeners();

    localStream?.getTracks().forEach((track) {
      peerConnection?.addTrack(track, localStream!);
    });

    var callerCandidatesCollection = roomRef.collection('callerCandidates');
    peerConnection?.onIceCandidate = (candidate) {
      print('New ICE candidate: $candidate');
      callerCandidatesCollection.add(candidate.toMap());
    };

    RTCSessionDescription offer = await peerConnection!.createOffer();
    await peerConnection!.setLocalDescription(offer);

    Map<String, dynamic> roomWithOffer = {'offer': offer.toMap()};
    await roomRef.set(roomWithOffer);

    peerConnection?.onTrack = (event) {
      print('Received remote track: ${event.track.id}');
      remoteStream?.addTrack(event.track);
    };

    roomRef.snapshots().listen((snapshots) async {
      Map<String, dynamic> data = snapshots.data() as Map<String, dynamic>;
      if (peerConnection?.getRemoteDescription() != null &&
          data.containsKey('answer')) {
        print('Got an answer: ${data['answer']}');
        RTCSessionDescription answer = RTCSessionDescription(
            data['answer']['sdp'], data['answer']['type']);
        await peerConnection!.setRemoteDescription(answer);
      }
    });

    roomRef.collection('calleeCandidates').snapshots().listen((snapshots) {
      for (var change in snapshots.docChanges) {
        if (change.type == DocumentChangeType.added) {
          Map<String, dynamic> data = change.doc.data() as Map<String, dynamic>;
          print('Got new remote ICE candidate: $data');
          peerConnection?.addCandidate(RTCIceCandidate(
            data['candidate'],
            data['sdpMid'],
            data['sdpMLineIndex'],
          ));
        }
      }
    });

    return roomRef.id;
  }

  Future<void> joinRoom(String roomId) async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentReference roomRef = db.collection('rooms').doc(roomId);
    DocumentSnapshot roomSnapshot = await roomRef.get();

    print('Create PeerConnection with configuration: $_configuration');
    if (roomSnapshot.exists) {
      peerConnection = await createPeerConnection(_configuration);

      registerPeerConnectionListeners();

      localStream?.getTracks().forEach((track) {
        peerConnection?.addTrack(track, localStream!);
      });

      var calleeCandidatesCollection = roomRef.collection('calleeCandidates');
      peerConnection?.onIceCandidate = (candidate) {
        print('New ICE candidate: $candidate');
        calleeCandidatesCollection.add(candidate.toMap());
      };

      peerConnection?.onTrack = (RTCTrackEvent event) {
        print('Received remote track: ${event.track.id}');
        event.streams[0].getTracks().forEach((track) {
          print('Add a track to the remoteStream: $track');
          remoteStream?.addTrack(track);
        });
      };

      var data = roomSnapshot.data() as Map<String, dynamic>;
      var offer = data['offer'];
      print('Got offer: $offer');
      await peerConnection!.setRemoteDescription(
        RTCSessionDescription(
          offer['sdp'],
          offer['type'],
        ),
      );
      var answer = await peerConnection!.createAnswer();
      await peerConnection!.setLocalDescription(answer);

      Map<String, dynamic> roomWithAnswer = {
        'answer': {'sdp': answer.sdp, 'type': answer.type}
      };

      await roomRef.update(roomWithAnswer);

      roomRef.collection('callerCandidates').snapshots().listen(
        (snapshots) {
          for (var change in snapshots.docChanges) {
            if (change.type == DocumentChangeType.added) {
              Map<String, dynamic> data =
                  change.doc.data() as Map<String, dynamic>;
              print('Got new remote ICE candidate: $data');
              peerConnection?.addCandidate(RTCIceCandidate(
                data['candidate'],
                data['sdpMid'],
                data['sdpMLineIndex'],
              ));
            }
          }
        },
      );
    }
  }

  void registerPeerConnectionListeners() {
    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      print('ICE gathering state changed: $state');
    };

    peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      print('Connection state change: $state');
    };

    peerConnection?.onSignalingState = (RTCSignalingState state) {
      print('Signaling state change: $state');
    };

    peerConnection?.onIceConnectionState = (RTCIceConnectionState state) {
      print('ICE connection state change: $state');
    };

    peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      print('ICE candidate: $candidate');
    };

    peerConnection?.onAddStream = (MediaStream stream) {
      print('Add remote stream: $stream');
      onAddRemoteStream?.call(stream);
      remoteStream = stream;
    };
  }
}
