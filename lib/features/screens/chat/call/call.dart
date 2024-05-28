import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class CallPage extends StatefulWidget {
  final String roomId;
  final bool isCaller;

  CallPage({required this.roomId, required this.isCaller});

  @override
  _CallPageState createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  late IO.Socket socket;
  late RTCPeerConnection peerConnection;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  @override
  void initState() {
    super.initState();
    _localRenderer.initialize();
    _remoteRenderer.initialize();
    _connectToSignalingServer();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    socket.dispose();
    super.dispose();
  }

  void _connectToSignalingServer() {
    socket = IO.io('http://localhost:3000', <String, dynamic>{
      'transports': ['websocket'],
    });

    socket.on('connect', (_) {
      socket.emit('join', widget.roomId);
      if (widget.isCaller) {
        _createOffer();
      }
    });

    socket.on('signal', (data) async {
      if (data['type'] == 'offer') {
        await _createAnswer(data['offer']);
      } else if (data['type'] == 'answer') {
        await _setRemoteDescription(data['answer']);
      } else if (data['type'] == 'candidate') {
        await _addCandidate(data['candidate']);
      }
    });
  }

  Future<void> _createOffer() async {
    final configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'}
      ]
    };
    peerConnection = await createPeerConnection(configuration);
    peerConnection.onIceCandidate = (candidate) {
      socket.emit('signal', {
        'type': 'candidate',
        'candidate': candidate.toMap(),
        'room': widget.roomId
      });
    };
    peerConnection.onAddStream = (stream) {
      _remoteRenderer.srcObject = stream;
    };
    final localStream = await navigator.mediaDevices
        .getUserMedia({'video': true, 'audio': true});
    _localRenderer.srcObject = localStream;
    peerConnection.addStream(localStream);
    final offer = await peerConnection.createOffer();
    await peerConnection.setLocalDescription(offer);
    socket.emit('signal',
        {'type': 'offer', 'offer': offer.toMap(), 'room': widget.roomId});
  }

  Future<void> _createAnswer(offer) async {
    await peerConnection.setRemoteDescription(RTCSessionDescription(
      offer['sdp'],
      offer['type'],
    ));
    final answer = await peerConnection.createAnswer();
    await peerConnection.setLocalDescription(answer);
    socket.emit('signal',
        {'type': 'answer', 'answer': answer.toMap(), 'room': widget.roomId});
  }

  Future<void> _setRemoteDescription(answer) async {
    await peerConnection.setRemoteDescription(RTCSessionDescription(
      answer['sdp'],
      answer['type'],
    ));
  }

  Future<void> _addCandidate(candidate) async {
    await peerConnection.addCandidate(RTCIceCandidate(
      candidate['candidate'],
      candidate['sdpMid'],
      candidate['sdpMLineIndex'],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Call with ${widget.roomId}'),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: RTCVideoView(_remoteRenderer),
          ),
          Positioned(
            left: 20,
            top: 20,
            child: SizedBox(
              width: 100,
              height: 150,
              child: RTCVideoView(_localRenderer, mirror: true),
            ),
          ),
        ],
      ),
    );
  }
}
