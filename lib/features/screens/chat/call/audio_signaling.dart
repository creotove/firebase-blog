// ignore_for_file: avoid_print, use_rethrow_when_possible

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

typedef StreamStateCallback = void Function(MediaStream stream);

class AudioSignaling {
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
  StreamStateCallback? onAddRemoteStream;
  StreamSubscription<DocumentSnapshot>? roomSubscription;
  StreamSubscription<QuerySnapshot>? calleeCandidatesSubscription;
  StreamSubscription<QuerySnapshot>? callerCandidatesSubscription;
  bool isConnectionClosed = false;

  Future<MediaStream> openUserMedia() async {
    try {
      localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true
      });
      return localStream!;
    } catch (e) {
      print(e.toString());
      throw e;
    }
  }

  Future<void> hangUp(
    String roomId,
    MediaStream localStream,
  ) async {
    try {
      isConnectionClosed = true;

      localStream.getTracks().forEach((track) {
        track.stop();
      });

      remoteStream?.getTracks().forEach((track) {
        track.stop();
      });

      await peerConnection?.close();
      peerConnection = null;

      if (roomSubscription != null) await roomSubscription!.cancel();
      if (calleeCandidatesSubscription != null) {
        await calleeCandidatesSubscription!.cancel();
      }
      if (callerCandidatesSubscription != null) {
        await callerCandidatesSubscription!.cancel();
      }

      if (roomId.isNotEmpty) {
        FirebaseFirestore db = FirebaseFirestore.instance;
        Future<DocumentSnapshot<Map<String, dynamic>>> roomExists = db.collection('rooms').doc(roomId).get();
        if (await roomExists == null) return;
        DocumentReference roomRef = db.collection('rooms').doc(roomId);

        var calleeCandidates = await roomRef.collection('calleeCandidates').get();
        for (var candidate in calleeCandidates.docs) {
          await candidate.reference.delete();
        }

        var callerCandidates = await roomRef.collection('callerCandidates').get();
        for (var candidate in callerCandidates.docs) {
          await candidate.reference.delete();
        }

        await roomRef.delete();
      }

      await localStream.dispose();
      await remoteStream?.dispose();

      remoteStream = null; // Make sure to set remoteStream to null
    } catch (e) {
      print(e.toString());
      throw e;
    }
  }

  Future<String> createRoom() async {
    try {
      FirebaseFirestore db = FirebaseFirestore.instance;
      DocumentReference roomRef = db.collection('rooms').doc();

      peerConnection = await createPeerConnection(_configuration);
      isConnectionClosed = false;

      // registerPeerConnectionListeners();

      localStream?.getTracks().forEach((track) {
        peerConnection?.addTrack(track, localStream!);
      });

      var callerCandidatesCollection = roomRef.collection('callerCandidates');
      peerConnection?.onIceCandidate = (candidate) {
        callerCandidatesCollection.add(candidate.toMap());
      };

      RTCSessionDescription offer = await peerConnection!.createOffer();
      await peerConnection!.setLocalDescription(offer);

      await roomRef.set({
        'offer': offer.toMap(),
        'hangup': false, // Initialize hangup field
        'pickedUp': false, // Initialize pickedUp field
      });

      peerConnection?.onTrack = (event) {
        remoteStream?.addTrack(event.track);
      };

      roomId = roomRef.id; // Ensure roomId is set here
      print('========================================'); // Debug print
      print('Room ID set: $roomId'); // Debug print
      print('========================================'); // Debug print

      // Listen for hangup
      roomSubscription = roomRef.snapshots().listen((snapshot) async {
        if (snapshot.data() == null) return;
        var data = snapshot.data() as Map<String, dynamic>;
        if (data['hangup'] == true) {
          print('Hangup received');
          print('Room ID: ${roomRef.id}');
          await hangUp(
            roomRef.id,
            localStream!,
          );
        }
      });

      roomSubscription = roomRef.snapshots().listen((snapshot) async {
        if (snapshot.data() == null) return;
        var data = snapshot.data() as Map<String, dynamic>;
        if (!isConnectionClosed && data.containsKey('answer')) {
          RTCSessionDescription answer = RTCSessionDescription(
            data['answer']['sdp'],
            data['answer']['type'],
          );
          if (answer.sdp != '' && answer.sdp != null) {
            await peerConnection!.setRemoteDescription(answer);
          } else {
            print('Answer is null');
          }
        }
      });

      calleeCandidatesSubscription = roomRef.collection('calleeCandidates').snapshots().listen((snapshots) {
        for (var change in snapshots.docChanges) {
          if (change.type == DocumentChangeType.added) {
            if (change.doc.data() == null) return;
            var data = change.doc.data() as Map<String, dynamic>;
            if (!isConnectionClosed) {
              peerConnection?.addCandidate(RTCIceCandidate(
                data['candidate'],
                data['sdpMid'],
                data['sdpMLineIndex'],
              ));
            }
          }
        }
      });
      return roomId!;
    } catch (e) {
      print(e.toString());
      throw e;
    }
  }

  Future<void> joinRoom(
    String roomId,
  ) async {
    try {
      this.roomId = roomId; // Set roomId here
      this.remoteStream = remoteStream;

      FirebaseFirestore db = FirebaseFirestore.instance;
      DocumentReference roomRef = db.collection('rooms').doc(roomId);
      DocumentSnapshot roomSnapshot = await roomRef.get();

      if (roomSnapshot.exists) {
        peerConnection = await createPeerConnection(_configuration);
        isConnectionClosed = false;

        // registerPeerConnectionListeners();

        // Ensure localStream is available
        if (localStream == null) {
          await openUserMedia();
        }

        // Add local tracks to peer connection
        localStream?.getTracks().forEach((track) {
          peerConnection?.addTrack(track, localStream!);
        });

        var calleeCandidatesCollection = roomRef.collection('calleeCandidates');
        peerConnection?.onIceCandidate = (candidate) {
          calleeCandidatesCollection.add(candidate.toMap());
        };

        peerConnection?.onTrack = (RTCTrackEvent event) {
          event.streams[0].getTracks().forEach((track) {
            remoteStream?.addTrack(track);
          });
          if (onAddRemoteStream != null) {
            onAddRemoteStream!(remoteStream!);
          }
        };
        if (roomSnapshot.data() == null) return;
        var data = roomSnapshot.data() as Map<String, dynamic>;
        var offer = data['offer'];
        await peerConnection!.setRemoteDescription(
          RTCSessionDescription(offer['sdp'], offer['type']),
        );
        var answer = await peerConnection!.createAnswer();
        await peerConnection!.setLocalDescription(answer);

        await roomRef.update({
          'answer': {
            'sdp': answer.sdp,
            'type': answer.type
          },
          'pickedUp': true,
        });

        // Listen for hangup
        roomSubscription = roomRef.snapshots().listen((snapshot) async {
          if (snapshot.data() == null) return;
          var data = snapshot.data() as Map<String, dynamic>;
          if (data['hangup'] == true) {
            await hangUp(
              roomRef.id,
              localStream!,
            );
          }
        });

        callerCandidatesSubscription = roomRef.collection('callerCandidates').snapshots().listen((snapshots) {
          for (var change in snapshots.docChanges) {
            if (change.type == DocumentChangeType.added) {
              if (change.doc.data() == null) return;
              var data = change.doc.data() as Map<String, dynamic>;
              if (!isConnectionClosed) {
                peerConnection?.addCandidate(RTCIceCandidate(
                  data['candidate'],
                  data['sdpMid'],
                  data['sdpMLineIndex'],
                ));
              }
            }
          }
        });

        peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
          print('Connection state change: $state');
        };
      }
    } catch (e) {
      print(e.toString());
      throw e;
    }
  }

  // void registerPeerConnectionListeners() {
  //   peerConnection?.onIceGatheringState = (state) {
  //     print('============Room ID1===============');
  //     print(roomId); // Debug print
  //     print('===========================');
  //     print('ICE gathering state changed: $state');
  //   };

  //   peerConnection?.onConnectionState = (state) {
  //     print('============Room ID2===============');
  //     print(roomId); // Debug print
  //     print('===========================');
  //     print('Connection state change: $state');
  //   };

  //   peerConnection?.onSignalingState = (state) {
  //     print('============Room ID3===============');
  //     print(roomId); // Debug print
  //     print('===========================');
  //     print('Signaling state change: $state');
  //   };

  //   peerConnection?.onIceConnectionState = (state) {
  //     print('============Room ID4===============');
  //     print(roomId); // Debug print
  //     print('===========================');
  //     print('ICE connection state change: $state');
  //   };

  //   peerConnection?.onIceCandidate = (candidate) {
  //     print('============Room ID5===============');
  //     print(roomId); // Debug print
  //     print('===========================');
  //     print('ICE candidate: $candidate');
  //   };

  //   peerConnection?.onAddStream = (stream) {
  //     print('============Room ID6===============');
  //     print(roomId); // Debug print
  //     print('===========================');
  //     onAddRemoteStream?.call(stream);
  //     remoteStream = stream;
  //   };

  //   peerConnection?.onTrack = (event) {
  //     print('============Room ID7===============');
  //     print(roomId); // Debug print
  //     print('===========================');
  //     if (event.streams.isNotEmpty) {
  //       remoteStream = event.streams[0];
  //       onAddRemoteStream?.call(remoteStream!);
  //     }
  //   };
  // }
}
