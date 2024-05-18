// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:blog/authentication.dart';
import 'package:blog/utils/context_utility_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
    NotificationSettings settings =
        await _firebaseMessaging.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await storeToken(token);
      }
      initPushNotifications();
      initLocalPushNotifications();
    } else {
      print('User declined or has not accepted permission');
    }
  }

  Future<void> storeToken(String token) async {
    final AuthenticationBloc authenticationBloc = AuthenticationBloc();
    final userDetails = await authenticationBloc.getUserDetails();
    if (userDetails.isEmpty) {
      ContextUtilityService.navigatorKey.currentState?.pushNamed('/login');
      return;
    }
    try {
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

  void handleMessage(RemoteMessage message) {
    if (message.notification == null) return;
    ContextUtilityService.navigatorKey.currentState
        ?.pushNamed('/profile', arguments: message);
  }

  Future<void> initLocalPushNotifications() async {
    const android = AndroidInitializationSettings('@drawable/ic_launcher');
    const iOS = DarwinInitializationSettings();
    const initializationSettings =
        InitializationSettings(android: android, iOS: iOS);
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

  Future<void> initPushNotifications() async {
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
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
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

Future<void> handleBackgroundMessage(RemoteMessage message) async {
  print('Message handled in the background!');
  print('Message data: ${message.data}');
  print('Message notification: ${message.notification}');
}
