// // ignore_for_file: avoid_print, use_rethrow_when_possible

// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_webrtc/flutter_webrtc.dart';

// typedef StreamStateCallback = void Function(MediaStream stream);

// class VideoSignaling {
//   final Map<String, dynamic> _configuration = {
//     'iceServers': [
//       {
//         'urls': [
//           'stun:stun.l.google.com:19302',
//           'stun:stun1.l.google.com:19302',
//           'stun:stun2.l.google.com:19302',
//           'stun:stun3.l.google.com:19302',
//           'stun:stun4.l.google.com:19302',
//         ]
//       }
//     ]
//   };
//   MediaStream? localStream;

//   RTCPeerConnection? peerConnection;
//   RTCVideoRenderer? localVideo;
//   MediaStream? remoteStream;
//   RTCVideoRenderer? remoteRender;
//   String? roomId;
//   StreamStateCallback? onAddRemoteStream;
//   StreamSubscription<DocumentSnapshot>? roomSubscription;
//   StreamSubscription<QuerySnapshot>? calleeCandidatesSubscription;
//   StreamSubscription<QuerySnapshot>? callerCandidatesSubscription;
//   bool isConnectionClosed = false;
//   Future<MediaStream> openUserMedia() async {
//     try {
//       final stream = await navigator.mediaDevices.getUserMedia({
//         'video': true,
//         'audio': true
//       });
//       return stream;
//     } catch (e) {
//       print('==========================================e=================================================');
//       print(e.toString());
//       print('==========================================e=================================================');
//       throw e;
//     }
//   }

//   Future<void> hangUp(
//     String roomId,
//     MediaStream localStream,
//     // RTCVideoRenderer? localVideo,
//   ) async {
//     try {
//       isConnectionClosed = true;

//       localStream.getTracks().forEach((track) {
//         track.stop();
//       });

//       remoteStream?.getTracks().forEach((track) {
//         track.stop();
//       });

//       await peerConnection?.close();
//       peerConnection = null;

//       if (roomSubscription != null) await roomSubscription!.cancel();
//       if (calleeCandidatesSubscription != null) {
//         await calleeCandidatesSubscription!.cancel();
//       }
//       if (callerCandidatesSubscription != null) {
//         await callerCandidatesSubscription!.cancel();
//       }

//       if (roomId.isNotEmpty) {
//         FirebaseFirestore db = FirebaseFirestore.instance;
//         DocumentReference roomRef = db.collection('rooms').doc(roomId);

//         var calleeCandidates = await roomRef.collection('calleeCandidates').get();
//         for (var candidate in calleeCandidates.docs) {
//           await candidate.reference.delete();
//         }

//         var callerCandidates = await roomRef.collection('callerCandidates').get();
//         for (var candidate in callerCandidates.docs) {
//           await candidate.reference.delete();
//         }

//         await roomRef.delete();
//       }

//       await localStream.dispose();
//       await localVideo?.dispose();
//       await remoteRender?.dispose();
//       await remoteStream?.dispose();

//       remoteStream = null; // Make sure to set remoteStream to null
//     } catch (e) {
//       print('==========================================e=================================================');
//       print(e.toString());
//       print('==========================================e=================================================');
//       throw e;
//     }
//   }

//   Future<String> createRoom() async {
//     try {
//       FirebaseFirestore db = FirebaseFirestore.instance;
//       DocumentReference roomRef = db.collection('rooms').doc();

//       peerConnection = await createPeerConnection(_configuration);
//       isConnectionClosed = false;

//       registerPeerConnectionListeners();

//       localStream?.getTracks().forEach((track) {
//         peerConnection?.addTrack(track, localStream!);
//       });

//       var callerCandidatesCollection = roomRef.collection('callerCandidates');
//       peerConnection?.onIceCandidate = (candidate) {
//         callerCandidatesCollection.add(candidate.toMap());
//       };

//       RTCSessionDescription offer = await peerConnection!.createOffer();
//       await peerConnection!.setLocalDescription(offer);

//       await roomRef.set({
//         'offer': offer.toMap(),
//         'hangup': false,
//         'pickedUp': false,
//       });

//       roomId = roomRef.id;
//       print('Room ID set: $roomId');

//       roomSubscription = roomRef.snapshots().listen((snapshot) async {
//         if (snapshot.data() == null) return;
//         var data = snapshot.data() as Map<String, dynamic>;
//         if (data['hangup'] == true) {
//           await hangUp(
//             roomRef.id,
//             localStream!,
//           );
//         }
//       });

//       roomSubscription = roomRef.snapshots().listen((snapshot) async {
//         if (snapshot.data() == null) return;
//         var data = snapshot.data() as Map<String, dynamic>;
//         if (!isConnectionClosed && data.containsKey('answer')) {
//           RTCSessionDescription answer = RTCSessionDescription(
//             data['answer']['sdp'],
//             data['answer']['type'],
//           );
//           if (answer.sdp != '' && answer.sdp != null) {
//             await peerConnection!.setRemoteDescription(answer);
//           } else {
//             print('Answer is null');
//           }
//         }
//       });

//       calleeCandidatesSubscription = roomRef.collection('calleeCandidates').snapshots().listen((snapshots) {
//         for (var change in snapshots.docChanges) {
//           if (change.type == DocumentChangeType.added) {
//             if (change.doc.data() == null) return;
//             var data = change.doc.data() as Map<String, dynamic>;
//             if (!isConnectionClosed) {
//               peerConnection?.addCandidate(RTCIceCandidate(
//                 data['candidate'],
//                 data['sdpMid'],
//                 data['sdpMLineIndex'],
//               ));
//             }
//           }
//         }
//       });

//       peerConnection?.onTrack = (RTCTrackEvent event) async {
//         event.streams[0].getTracks().forEach((track) {
//           remoteStream?.addTrack(track);
//         });
//         if (onAddRemoteStream != null) {
//           print(remoteStream);
//           onAddRemoteStream!(remoteStream!);
//         }
//       };
//       return roomId!;
//     } catch (e) {
//       print('==========================================e=================================================');
//       print(e.toString());
//       print('==========================================e=================================================');
//       throw e;
//     }
//   }

//   Future<void> joinRoom(
//     String roomId,
//     // RTCVideoRenderer remoteRender,
//   ) async {
//     try {
//       this.roomId = roomId; // Set roomId here
//       this.remoteStream = remoteStream;
//       this.remoteRender = remoteRender;

//       // remoteRender.srcObject = await createLocalMediaStream('key');

//       FirebaseFirestore db = FirebaseFirestore.instance;
//       DocumentReference roomRef = db.collection('rooms').doc(roomId);
//       DocumentSnapshot roomSnapshot = await roomRef.get();

//       if (roomSnapshot.exists) {
//         peerConnection = await createPeerConnection(_configuration);
//         isConnectionClosed = false;

//         registerPeerConnectionListeners();

//         // Ensure localStream is available
//         if (localStream == null) {
//           await openUserMedia();
//         }

//         if (localStream != null) {
//           localStream!.getTracks().forEach((track) {
//             peerConnection?.addTrack(track, localStream!);
//           });
//         }

//         var calleeCandidatesCollection = roomRef.collection('calleeCandidates');
//         peerConnection?.onIceCandidate = (candidate) {
//           calleeCandidatesCollection.add(candidate.toMap());
//         };

//         peerConnection?.onTrack = (RTCTrackEvent event) {
//           event.streams[0].getTracks().forEach((track) {
//             remoteStream?.addTrack(track);
//           });
//           if (onAddRemoteStream != null) {
//             onAddRemoteStream!(remoteStream!);
//           }
//         };
//         if (roomSnapshot.data() == null) return;
//         var data = roomSnapshot.data() as Map<String, dynamic>;
//         var offer = data['offer'];
//         await peerConnection!.setRemoteDescription(
//           RTCSessionDescription(offer['sdp'], offer['type']),
//         );
//         var answer = await peerConnection!.createAnswer();
//         await peerConnection!.setLocalDescription(answer);

//         await roomRef.update({
//           'answer': {
//             'sdp': answer.sdp,
//             'type': answer.type
//           },
//           'pickedUp': true,
//         });

//         // Listen for hangup
//         roomSubscription = roomRef.snapshots().listen((snapshot) async {
//           if (snapshot.data() == null) return;
//           var data = snapshot.data() as Map<String, dynamic>;
//           if (data['hangup'] == true) {
//             await hangUp(
//               roomRef.id,
//               localStream!,
//             );
//           }
//         });

//         peerConnection?.onIceConnectionState = (RTCIceConnectionState state) {
//           print('ICE connection state change: $state');
//           if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
//             hangUp(
//               roomId,
//               localStream!,
//             );
//           }
//         };

//         callerCandidatesSubscription = roomRef.collection('callerCandidates').snapshots().listen((snapshots) {
//           for (var change in snapshots.docChanges) {
//             if (change.type == DocumentChangeType.added) {
//               if (change.doc.data() == null) return;
//               var data = change.doc.data() as Map<String, dynamic>;
//               if (!isConnectionClosed) {
//                 peerConnection?.addCandidate(RTCIceCandidate(
//                   data['candidate'],
//                   data['sdpMid'],
//                   data['sdpMLineIndex'],
//                 ));
//               }
//             }
//           }
//         });

//         peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
//           print('Connection state change: $state');
//         };
//       }
//     } catch (e) {
//       print('==========================================e=================================================');
//       print(e.toString());
//       print('==========================================e=================================================');
//       throw e;
//     }
//   }

//   void registerPeerConnectionListeners() {
//     peerConnection?.onIceGatheringState = (state) {
//       print('============Room ID1===============');
//       print(roomId); // Debug print
//       print('===========================');
//       print('ICE gathering state changed: $state');
//     };

//     peerConnection?.onConnectionState = (state) {
//       print('============Room ID2===============');
//       print(roomId); // Debug print
//       print('===========================');
//       print('Connection state change: $state');
//     };

//     peerConnection?.onSignalingState = (state) {
//       print('============Room ID3===============');
//       print(roomId); // Debug print
//       print('===========================');
//       print('Signaling state change: $state');
//     };

//     peerConnection?.onIceConnectionState = (state) {
//       print('============Room ID4===============');
//       print(roomId); // Debug print
//       print('===========================');
//       print('ICE connection state change: $state');
//     };

//     peerConnection?.onIceCandidate = (candidate) {
//       print('============Room ID5===============');
//       print(roomId); // Debug print
//       print('===========================');
//       print('ICE candidate: $candidate');
//     };

//     peerConnection?.onAddStream = (stream) {
//       print('============Room ID6===============');
//       print(roomId); // Debug print
//       print('===========================');
//       onAddRemoteStream?.call(stream);
//       remoteStream = stream;
//     };

//     peerConnection?.onTrack = (event) {
//       print('============Room ID7===============');
//       print(roomId); // Debug print
//       print('===========================');
//       if (event.streams.isNotEmpty) {
//         remoteStream = event.streams[0];
//         onAddRemoteStream?.call(remoteStream!);
//       }
//     };
//   }
// }

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

typedef StreamStateCallback = void Function(MediaStream stream);

class VideoSignaling {
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
  MediaStream? localStream;
  RTCPeerConnection? peerConnection;
  MediaStream? remoteStream;
  StreamStateCallback? onAddRemoteStream;
  StreamSubscription<DocumentSnapshot>? roomSubscription;
  StreamSubscription<QuerySnapshot>? calleeCandidatesSubscription;
  StreamSubscription<QuerySnapshot>? callerCandidatesSubscription;
  bool isConnectionClosed = false;
  String? roomId;

  Future<MediaStream> openUserMedia() async {
    try {
      final stream = await navigator.mediaDevices.getUserMedia({
        'video': true,
        'audio': true
      });
      return stream;
    } catch (e) {
      print('Error in openUserMedia: $e');
      throw e;
    }
  }

  Future<void> hangUp(
    String roomId,
    MediaStream localStream,
    // MediaStream? remoteStream,
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

      await roomSubscription?.cancel();
      await calleeCandidatesSubscription?.cancel();
      await callerCandidatesSubscription?.cancel();

      if (roomId.isNotEmpty) {
        FirebaseFirestore db = FirebaseFirestore.instance;
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

      remoteStream = null;
    } catch (e) {
      print('Error in hangUp: $e');
      throw e;
    }
  }

  Future<String> createRoom() async {
    try {
      FirebaseFirestore db = FirebaseFirestore.instance;
      DocumentReference roomRef = db.collection('rooms').doc();

      peerConnection = await createPeerConnection(_configuration);
      isConnectionClosed = false;

      registerPeerConnectionListeners();

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
        'hangup': false,
        'pickedUp': false,
      });

      roomId = roomRef.id;

      roomSubscription = roomRef.snapshots().listen((snapshot) async {
        if (snapshot.data() == null) return;
        var data = snapshot.data() as Map<String, dynamic>;
        if (data['hangup'] == true) {
          await hangUp(
            roomRef.id,
            localStream!,
            // remoteStream,
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

      peerConnection?.onTrack = (RTCTrackEvent event) async {
        print(" ============= remoteStream ============= ");
        if (event.streams.isNotEmpty) {
          remoteStream = event.streams[0];
          if (onAddRemoteStream != null) {
            print(remoteStream);
            onAddRemoteStream!(remoteStream!);
          }
        }
        print(" ============= remoteStream ============= ");
      };

      return roomId!;
    } catch (e) {
      print('Error in createRoom: $e');
      throw e;
    }
  }

  Future<void> joinRoom(String roomId) async {
    try {
      this.roomId = roomId;
      FirebaseFirestore db = FirebaseFirestore.instance;
      DocumentReference roomRef = db.collection('rooms').doc(roomId);
      DocumentSnapshot roomSnapshot = await roomRef.get();

      if (roomSnapshot.exists) {
        peerConnection = await createPeerConnection(_configuration);
        isConnectionClosed = false;

        registerPeerConnectionListeners();

        if (remoteStream == null) {
          remoteStream = await openUserMedia();
        }

        if (localStream != null) {
          remoteStream!.getTracks().forEach((track) {
            peerConnection?.addTrack(track, localStream!);
          });
        }

        var calleeCandidatesCollection = roomRef.collection('calleeCandidates');
        peerConnection?.onIceCandidate = (candidate) {
          calleeCandidatesCollection.add(candidate.toMap());
        };

        peerConnection?.onTrack = (RTCTrackEvent event) {
          if (event.streams.isNotEmpty) {
            remoteStream = event.streams[0];
            if (onAddRemoteStream != null) {
              onAddRemoteStream!(remoteStream!);
            }
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

        roomSubscription = roomRef.snapshots().listen((snapshot) async {
          if (snapshot.data() == null) return;
          var data = snapshot.data() as Map<String, dynamic>;
          if (data['hangup'] == true) {
            await hangUp(
              roomRef.id,
              localStream!,
              // remoteStream,
            );
          }
        });

        peerConnection?.onIceConnectionState = (RTCIceConnectionState state) {
          if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
            hangUp(
              roomId,
              localStream!,
              // remoteStream,
            );
          }
        };

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
      }
    } catch (e) {
      print('Error in joinRoom: $e');
      throw e;
    }
  }

  void registerPeerConnectionListeners() {
    peerConnection?.onIceGatheringState = (state) {
      print('ICE gathering state changed: $state');
    };

    peerConnection?.onConnectionState = (state) {
      print('Connection state change: $state');
    };

    peerConnection?.onSignalingState = (state) {
      print('Signaling state change: $state');
    };

    peerConnection?.onIceConnectionState = (state) {
      print('ICE connection state change: $state');
    };

    peerConnection?.onIceCandidate = (candidate) {
      print('ICE candidate: $candidate');
    };

    peerConnection?.onAddStream = (stream) {
      remoteStream = stream;
      onAddRemoteStream?.call(stream);
    };

    peerConnection?.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        remoteStream = event.streams[0];
        onAddRemoteStream?.call(remoteStream!);
      }
    };
  }
}
