// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:blog/authentication.dart';
import 'package:blog/features/screens/chat/argument_helper.dart.dart';
import 'package:blog/utils/context_utility_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseApi {
  // Instance for the Firebase Messaging
  final _firebaseMessaging = FirebaseMessaging.instance;

  // Android channel for the local push notifications
  final _androidChannel = const AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  // Instance for the Flutter Local Notifications
  final _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Initialize the notifications
  Future<void> initNotifications() async {
    // Request permission for the notifications
    NotificationSettings settings =
        await _firebaseMessaging.requestPermission();

    // If the user has accepted the permission
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await storeToken(token);
      }
      initPushNotifications();
      initLocalPushNotifications();
    }
    // If the user has declined the permission
    else {
      print('User declined or has not accepted permission');
    }
  }

  // Store the token in the Firestore
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
      await firestore
          .collection('users')
          .where('user_id', isEqualTo: userDetails['user_id'])
          .get()
          .then((value) async {
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

  // Handle the message when it is clicked
  void handleMessage(RemoteMessage message) async {
    try {
      if (message.data.isEmpty) {
        print('No data in message');
        return;
      }
      final route = message.data['route'];
      final receiverUserId = await AuthenticationBloc().getCurrentUserId();
      final senderUserId = message.data['senderUserId'];
      final myArgs = MessageNotificationArgs(
        receiverUserId: senderUserId,
        senderUserId: receiverUserId.toString(),
        route: route,
        authBloc: AuthenticationBloc(),
      );

      if (route == '/chat' && receiverUserId != null) {
        ContextUtilityService.navigatorKey.currentState
            ?.pushNamed(route, arguments: myArgs);
      }
    } catch (e) {
      print(e);
    }
  }

  // Initialize the local push notifications when the app is opened
  Future<void> initLocalPushNotifications() async {
    const android = AndroidInitializationSettings('@drawable/ic_launcher');
    const iOS = DarwinInitializationSettings();
    const initializationSettings =
        InitializationSettings(android: android, iOS: iOS);
    // ignore: unawaited_futures
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        final message = RemoteMessage.fromMap(jsonDecode(details.payload!));
        handleMessage(message);
      },
    );
    final platform =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()!;
    await platform.createNotificationChannel(_androidChannel);
  }

  // Initialize the push notifications
  Future<void> initPushNotifications() async {
    FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    // Get the initial message when the app is opened
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        handleMessage(message);
      }
    });
    // Listen for the message when the app is opened
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      handleMessage(message);
    });
    // Listen for the message when the app is in the background
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
    // Listen for the message when the app is in the foreground
    FirebaseMessaging.onMessage.listen((message) {
      // Show the local push notification
      final notification = message.notification;
      // If there is no notification, return
      if (notification == null) return;
      // Show the notification
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

// Handle the background message Just to check if the message is received
Future<void> handleBackgroundMessage(RemoteMessage message) async {
  print('Message handled in the background!');
  print('Message data: ${message.data}');
  print('Message notification: ${message.notification}');
}
