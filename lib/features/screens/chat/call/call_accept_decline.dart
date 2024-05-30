import 'dart:ui';
import 'package:blog/authentication.dart';
import 'package:blog/constants.dart';
import 'package:blog/theme/app_pallete.dart';
import 'package:blog/utils/webrtc_manager.dart';
import 'package:blog/widgets/count_down_dialer.dart';
import 'package:blog/widgets/custom_cricular_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class CallAcceptDeclinePage extends StatefulWidget {
  final DuringCallStatus? callStatus;
  final String? roomId;
  final AuthenticationBloc authBloc;

  const CallAcceptDeclinePage(
      {super.key, required this.authBloc, this.callStatus, this.roomId});

  @override
  _CallAcceptDeclinePageState createState() => _CallAcceptDeclinePageState();
}

class _CallAcceptDeclinePageState extends State<CallAcceptDeclinePage> {
  late DuringCallStatus callStatus;

  List<IconData> bottomSheetIcons = [
    Icons.speaker_phone,
    Icons.bluetooth,
    Icons.video_call,
    Icons.mic_off_sharp,
    Icons.call_end,
  ];
  WebRtcManager webrtcService = WebRtcManager();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  String? roomId;

  initializeWebRTC() async {
    _localRenderer.initialize();
    _remoteRenderer.initialize();

    webrtcService.onAddRemoteStream = ((stream) {
      _remoteRenderer.srcObject = stream;
      setState(() {});
    });

    webrtcService.openUserMedia(_localRenderer, _remoteRenderer);
    if (callStatus == DuringCallStatus.calling) {
      roomId = await webrtcService.createRoom(_remoteRenderer);
      debugPrint("roomID: $roomId");
      // Api.sendNotificationRequestToFriendToAcceptCall(roomId!, widget.user);
    } else {
      roomId = widget.roomId;
      webrtcService.joinRoom(
        roomId!,
        _remoteRenderer,
      );
    }

    if (kDebugMode) {
      print("connected successfully");
    }
  }

  @override
  void initState() {
    callStatus = widget.callStatus ?? DuringCallStatus.calling;
    initializeWebRTC();
    super.initState();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    webrtcService.hangUp(_localRenderer);
    super.dispose();
  }

  Widget getBody() {
    switch (callStatus) {
      case DuringCallStatus.calling:
        return Center(
          child: Column(
            children: [
              const SizedBox(
                height: 100,
              ),
              Column(
                children: [
                  const CustomCircularImage(
                    size: 150,
                    avatar: "",
                    userName: "",
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  Text(
                    widget.authBloc.getCurrentUserName().toString(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  const Text(
                    "Calling...",
                    style: TextStyle(
                        color: Colors.white,
                        shadows: [
                          BoxShadow(color: Colors.black, blurRadius: 3)
                        ],
                        fontSize: 16),
                  )
                ],
              ),
            ],
          ),
        );
      case DuringCallStatus.accepted:
        return Center(
          child: Column(
            children: [
              const SizedBox(
                height: 100,
              ),
              Column(
                children: [
                  const CustomCircularImage(
                    size: 150,
                    avatar: "",
                    userName: "",
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  Text(
                    widget.authBloc.getCurrentUserName().toString(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  const CountDownDialer(
                    style: TextStyle(
                        color: Colors.white,
                        shadows: [
                          BoxShadow(color: Colors.black, blurRadius: 3)
                        ],
                        fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
        );
      case DuringCallStatus.ringing:
        return Column(
          children: [
            const Spacer(),
            Column(
              children: [
                const CustomCircularImage(
                  size: 150,
                  avatar: "",
                  userName: "",
                ),
                const SizedBox(
                  height: 16,
                ),
                Text(
                  widget.authBloc.getCurrentUserName().toString(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(
                  height: 8,
                ),
                const Text(
                  "Calling...",
                  style: TextStyle(
                      color: Colors.white,
                      shadows: [BoxShadow(color: Colors.black, blurRadius: 3)],
                      fontSize: 16),
                )
              ],
            ),
            const SizedBox(
              height: 60,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: const BoxDecoration(
                          color: AppPallete.gradient2, shape: BoxShape.circle),
                      child: const Icon(Icons.phone, color: Colors.white),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    const Text(
                      "Accept",
                      style: TextStyle(color: Colors.white),
                    )
                  ],
                ),
                Column(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: const BoxDecoration(
                          color: Colors.redAccent, shape: BoxShape.circle),
                      child: const Icon(Icons.phone_callback_sharp,
                          color: Colors.white),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    const Text(
                      "Decline",
                      style: TextStyle(color: Colors.white),
                    )
                  ],
                ),
              ],
            ),
            const SizedBox(
              height: 60,
            ),
            const Text(
              "Decline & Send Message",
              style: TextStyle(color: Colors.white60, fontSize: 14),
            ),
            const SizedBox(
              height: 10,
            ),
            ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.75,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade200.withOpacity(0.2),
                      borderRadius:
                          const BorderRadius.all(Radius.circular(20))),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: const [
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          "I'll call you back",
                          style: TextStyle(color: Colors.white54),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          "Sorry, I can't talk right now",
                          style: TextStyle(color: Colors.white54),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 80,
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
                image: 'a' == null
                    ? null
                    : DecorationImage(
                        image: NetworkImage('widget.user.picture'!),
                        fit: BoxFit.cover)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
              child: Container(
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.0)),
              ),
            ),
          ),
          getBody(),
          SlidingUpPanel(
            panel: Container(
              color: Colors.black87,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                    bottomSheetIcons.length,
                    (index) => Icon(
                          bottomSheetIcons[index],
                          color: index == 4 ? Colors.redAccent : Colors.white,
                        )),
              ),
            ),
            minHeight: 90,
            maxHeight: 200,
            collapsed: Container(
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12.0),
                  topRight: Radius.circular(12.0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                    bottomSheetIcons.length,
                    (index) => Icon(
                          bottomSheetIcons[index],
                          color: index == 4 ? Colors.redAccent : Colors.white,
                        )),
              ),
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12.0),
              topRight: Radius.circular(12.0),
            ),
          )
        ],
      ),
    );
  }
}
