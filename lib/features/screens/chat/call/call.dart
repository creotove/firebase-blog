// import 'package:blog/features/screens/chat/call/signaling.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_webrtc/flutter_webrtc.dart';

// class CallPage extends StatefulWidget {
//   const CallPage({super.key});

//   @override
//   State<CallPage> createState() => _CallPageState();
// }

// class _CallPageState extends State<CallPage> {
//   Signaling signaling = Signaling();
//   RTCVideoRenderer localRenderer = RTCVideoRenderer();
//   RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
//   String? roomId;
//   TextEditingController textEditingController = TextEditingController();

//   @override
//   void initState() {
//     localRenderer.initialize();
//     remoteRenderer.initialize();
//     signaling.onAddRemoteStream = (stream) {
//       remoteRenderer.srcObject = stream;
//       setState(() {});
//     };
//     super.initState();
//   }

//   @override
//   void dispose() {
//     localRenderer.dispose();
//     remoteRenderer.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//         title: const Text("WebRTC Demo"),
//       ),
//       body: Column(
//         children: [
//           SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: Row(
//               children: [
//                 ElevatedButton(
//                     onPressed: () async {
//                       await signaling.openUserMedia(
//                           localRenderer, remoteRenderer);
//                       setState(() {});
//                     },
//                     child: const Text("Open Camera")),
//                 const SizedBox(width: 10),
//                 ElevatedButton(
//                   onPressed: () async {
//                     roomId = await signaling.createRoom(remoteRenderer);
//                     textEditingController.text = roomId!;
//                     setState(() {
//                       roomId = signaling.roomId;
//                     });
//                   },
//                   child: const Text('Create Room'),
//                 ),
//                 const SizedBox(width: 10),
//                 ElevatedButton(
//                   onPressed: () async {
//                     await signaling.joinRoom(textEditingController.text);
//                     setState(() {
//                       roomId = textEditingController.text;
//                     });
//                   },
//                   child: const Text('Join Room'),
//                 ),
//                 const SizedBox(width: 10),
//                 ElevatedButton(
//                   onPressed: () async {
//                     await signaling.hangUp(localRenderer);
//                     setState(() {
//                       roomId = null;
//                     });
//                   },
//                   child: const Text('Hang Up'),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 10),
//           Expanded(
//             child: Row(
//               children: [
//                 Expanded(
//                   child: RTCVideoView(localRenderer, mirror: true),
//                 ),
//                 Expanded(
//                   child: RTCVideoView(remoteRenderer),
//                 ),
//               ],
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(10),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text("Join the following room:"),
//                 Flexible(
//                   child: TextFormField(controller: textEditingController),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:blog/authentication.dart';
import 'package:blog/features/screens/chat/call/signaling.dart';
import 'package:flutter/material.dart';

class CallPage extends StatefulWidget {
  final AuthenticationBloc authBloc;
  final String currentUserId;
  final String receiverUserId;
  final String roomId;
  final String avatar;
  final String receiverName;
  const CallPage(
      {super.key,
      required this.authBloc,
      required this.currentUserId,
      required this.receiverUserId,
      required this.roomId,
      required this.avatar,
      required this.receiverName});

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  Signaling signaling = Signaling();
  String? roomId;
  TextEditingController textEditingController = TextEditingController();

  @override
  void initState() {
    signaling.onAddRemoteStream = (stream) {
      setState(() {});
    };
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("WebRTC Audio Call Demo"),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await signaling.openUserMedia();
                    setState(() {});
                  },
                  child: const Text("Open Microphone"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    roomId = await signaling.createRoom();
                    textEditingController.text = roomId!;
                    setState(() {
                      roomId = signaling.roomId;
                    });
                  },
                  child: const Text('Create Room'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    await signaling.joinRoom(textEditingController.text);
                    setState(() {
                      roomId = textEditingController.text;
                    });
                  },
                  child: const Text('Join Room'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    await signaling.hangUp();
                    setState(() {
                      roomId = null;
                    });
                  },
                  child: const Text('Hang Up'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Center(
              child: roomId == null
                  ? const Text("No active call")
                  : const Text("In a call..."),
            ),
          ),
          // Padding(
          //   padding: const EdgeInsets.all(10),
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     children: [
          //       const Text("Join the following room:"),
          //       const SizedBox(width: 10),
          //       Flexible(
          //         child: TextFormField(controller: textEditingController),
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }
}
