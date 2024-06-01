import 'package:blog/features/screens/chat/videoCall/video_call_signaling.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class VideoCall extends StatefulWidget {
  const VideoCall({super.key});

  @override
  State<VideoCall> createState() => _VideoCallState();
}

class _VideoCallState extends State<VideoCall> {
  Signaling signaling = Signaling();
  RTCVideoRenderer localRenderer = RTCVideoRenderer();
  RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  String? roomId;
  TextEditingController textEditingController = TextEditingController();

  @override
  void initState() {
    localRenderer.initialize();
    remoteRenderer.initialize();
    signaling.onAddRemoteStream = (stream) {
      remoteRenderer.srcObject = stream;
      setState(() {});
    };
    super.initState();
  }

  @override
  void dispose() {
    localRenderer.dispose();
    remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("WebRTC Demo"),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                    onPressed: () async {
                      await signaling.openUserMedia(
                          localRenderer, remoteRenderer);
                      setState(() {});
                    },
                    child: const Text("Open Camera")),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    final roomId = await signaling.createRoom(remoteRenderer);
                    textEditingController.text = roomId;
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
                    await signaling.hangUp(localRenderer);
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
            child: Row(
              children: [
                Expanded(
                  child: RTCVideoView(localRenderer, mirror: true),
                ),
                Expanded(
                  child: RTCVideoView(remoteRenderer),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Join the following room:"),
                Flexible(
                  child: TextFormField(controller: textEditingController),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 50,
            child: Center(
              child: Text("Room ID: $roomId"),
            ),
          ),
        ],
      ),
    );
  }
}
