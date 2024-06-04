// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:blog/authentication.dart';
import 'package:blog/constants.dart';
import 'package:blog/features/screens/chat/call/audio_signaling.dart';
import 'package:blog/features/screens/chat/videoCall/video_call_signaling.dart';
import 'package:blog/utils/argument_helper.dart.dart';
import 'package:blog/utils/context_utility_service.dart';
import 'package:blog/utils/perms_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
// import 'package:permission_handler/permission_handler.dart';

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;
  final _androidChannel = const AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  final _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initNotifications() async {
    await _firebaseMessaging.requestPermission();
    final token = await _firebaseMessaging.getToken();
    if (token != null) {
      await storeToken(token);
      initPushNotifications();
      initLocalPushNotifications();
    } else {
      print('User declined or has not accepted permission');
    }
  }

  Future<void> storeToken(String token) async {
    // Get the user details
    final AuthenticationBloc authenticationBloc = AuthenticationBloc();
    final userDetails = await authenticationBloc.getUserDetails();

    // If the user is not logged in, navigate to the login page
    if (userDetails.isEmpty) {
      ContextUtilityService.navigatorKey.currentState?.pushNamed('/login');
      return;
    }
    try {
      // Store the token in the Firestore for the user
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      await firestore.collection('users').where('user_id', isEqualTo: userDetails['user_id']).get().then((value) async {
        if (value.docs.isNotEmpty) {
          await firestore.collection('users').doc(value.docs.first.id).update({
            'fcmToken': token,
          });
        }
      });
    } catch (e) {
      print(e);
    }
  }

  void handleMessage(RemoteMessage message) async {
    try {
      print('Message handled in the foreground!');
      if (message.data.isEmpty) {
        print('No data in message');
        return;
      }
      final route = message.data['route'];
      final receiverUserId = await AuthenticationBloc().getCurrentUserId();
      final senderUserId = message.data['senderUserId'];

      if (receiverUserId != null) {
        if (route == '/chat') {
          final myArgs = MessageNotificationArgs(
            receiverUserId: senderUserId,
            senderUserId: receiverUserId.toString(),
            route: route,
            authBloc: AuthenticationBloc(),
          );
          ContextUtilityService.navigatorKey.currentState?.pushNamed(route, arguments: myArgs);
        } else if (route == '/call-accept-and-decline') {
          final roomId = message.data['roomId'];
          final avatar = message.data['avatar'];
          final receiverName = message.data['receiverName'];
          final localStream = await AudioSignaling().openUserMedia();
          if (await PermsHandler().microphone()) {
            final callArgs = CallArguments(
              authBloc: AuthenticationBloc(),
              avatar: avatar,
              receiverName: receiverName,
              roomId: roomId,
              currentUserId: receiverUserId.toString(),
              callStatus: DuringCallStatus.ringing,
              receiverUserId: senderUserId,
              localStream: localStream,
            );
            await ContextUtilityService.navigatorKey.currentState?.pushNamed(route, arguments: callArgs);
          }
        } else if (route == '/video-call-accept-and-decline') {
          final roomId = message.data['roomId'];
          final avatar = message.data['avatar'];
          final receiverName = message.data['receiverName'];
          final remoteStream = await VideoSignaling().openUserMedia();
          if (await PermsHandler().microphone() && await PermsHandler().camera()) {
            final callArgs = CallArguments(
              authBloc: AuthenticationBloc(),
              avatar: avatar,
              receiverName: receiverName,
              roomId: roomId,
              currentUserId: receiverUserId.toString(),
              callStatus: DuringCallStatus.ringing,
              receiverUserId: senderUserId,
              remoteStream: remoteStream,
            );
            print('Call Args: $callArgs');
            await ContextUtilityService.navigatorKey.currentState?.pushNamed(route, arguments: callArgs);
          }
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future initLocalPushNotifications() async {
    const android = AndroidInitializationSettings('@drawable/ic_launcher');
    const iOS = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(android: android, iOS: iOS);
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        final message = RemoteMessage.fromMap(jsonDecode(details.payload!));
        handleMessage(message);
      },
    );
    final platform = _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()!;
    await platform.createNotificationChannel(_androidChannel);
  }

  Future initPushNotifications() async {
    FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        handleMessage(message);
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      handleMessage(message);
    });
    FirebaseMessaging.onBackgroundMessage(handleBackgroubdNessage);
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      _flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _androidChannel.id,
              _androidChannel.name,
              channelDescription: _androidChannel.description,
              icon: '@drawable/ic_launcher',
              importance: Importance.high,
            ),
          ),
          payload: jsonEncode(message.toMap()));
    });
  }
}

Future<void> handleBackgroubdNessage(RemoteMessage message) async {
  print('Message handled in the background!');
  print('Message data: ${message.data}');
  print('Message notification: ${message.notification}');
}
