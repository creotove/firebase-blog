// ignore_for_file: avoid_print

import 'package:blog/features/screens/blog/add_blog_page.dart';
import 'package:blog/features/screens/blog/blog_edit.dart';
import 'package:blog/features/screens/blog/blog_view_page.dart';
import 'package:blog/features/screens/blog/comments/manage_comments.dart';
import 'package:blog/features/screens/blog/home_page.dart';
import 'package:blog/features/screens/auth/sign_in_page.dart';
import 'package:blog/features/screens/auth/sign_up_page.dart';
import 'package:blog/features/screens/chat/chat.dart';
import 'package:blog/features/screens/chat/chats.dart';
import 'package:blog/features/screens/chat/sendScreens/sendAudio.dart';
import 'package:blog/features/screens/chat/sendScreens/sendDocument.dart';
import 'package:blog/features/screens/chat/sendScreens/sendImage.dart';
import 'package:blog/features/screens/chat/argument_helper.dart.dart';
import 'package:blog/features/screens/chat/sendScreens/sendVideo.dart';
import 'package:blog/features/screens/chat/show_send_image.dart';
import 'package:blog/features/screens/profile/edit_profile.dart';
import 'package:blog/features/screens/profile/my_blogs.dart';
import 'package:blog/features/screens/profile/my_profile.dart';
import 'package:blog/features/screens/profile/user_profile.dart';
import 'package:blog/secrets/firebase_options.dart';
import 'package:blog/theme/theme.dart';
import 'package:blog/utils/context_utility_service.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:blog/authentication.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Initialize the Firebase app
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    final authBloc = AuthenticationBloc();
    // Run the app with the AuthenticationBloc
    runApp(MyApp(authBloc: authBloc));
  } catch (e) {
    print(e);
  }
}

class MyApp extends StatefulWidget {
  final AuthenticationBloc authBloc;

  const MyApp({super.key, required this.authBloc});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Route observer for route changes
  final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
  // Initialize the dynamic links
  void initDynamicLinks(BuildContext context) async {
    try {
      // Listen for the dynamic links
      FirebaseDynamicLinks.instance.onLink.listen((dynamicLink) {
        final Uri deepLink = dynamicLink.link;
        var isBlog = deepLink.pathSegments.contains('blog-view');
        // If the deep link is for the blog view then redirect it to the blog view page
        if (isBlog) {
          final queryParams = deepLink.queryParameters;
          if (queryParams.containsKey('blogId')) {
            final blogId = queryParams['blogId'];
            Navigator.pushNamed(ContextUtilityService.context!, '/blog-view',
                arguments: blogId);
          }
        }
      });
    } catch (e) {
      print(e);
    }
    try {
      // Get the initial link
      final PendingDynamicLinkData? data =
          await FirebaseDynamicLinks.instance.getInitialLink();
      // If the deep link is for the blog view then redirect it to the blog view page
      final Uri? deepLink = data?.link;
      if (deepLink != null) {
        var isBlog = deepLink.pathSegments.contains('blog-view');
        if (isBlog) {
          final queryParams = deepLink.queryParameters;
          if (queryParams.containsKey('blogId')) {
            final blogId = queryParams['blogId'];
            Navigator.pushNamed(ContextUtilityService.context!, '/blog-view',
                arguments: blogId);
            return;
          }
        }
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    super.initState();
    // Add a post frame callback to initialize the dynamic links
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initDynamicLinks(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Hide the debug banner
      debugShowCheckedModeBanner: false,
      title: 'Blog App',
      theme: AppTheme.darkThemeMode,
      // Set the navigator key for the context utility service
      navigatorKey: ContextUtilityService.navigatorKey,
      // Set the route observer
      navigatorObservers: [routeObserver],
      initialRoute: '/signup',
      // All the registered routes in the app
      routes: {
        '/': (context) {
          if (widget.authBloc.isAuthenticated()) {
            return HomePage(authBloc: widget.authBloc);
          } else {
            return SignInPage(authBloc: widget.authBloc);
          }
        },
        '/add-blog': (context) {
          if (widget.authBloc.isAuthenticated()) {
            return AddBlogPage(authBloc: widget.authBloc);
          } else {
            return SignInPage(authBloc: widget.authBloc);
          }
        },
        '/login': (context) => SignInPage(authBloc: widget.authBloc),
        '/chats': (context) => ChatsPage(authBloc: widget.authBloc),
        '/edit-profile': (context) =>
            EditProfilePage(authBloc: widget.authBloc),
        '/signup': (context) {
          if (widget.authBloc.isAuthenticated()) {
            return HomePage(authBloc: widget.authBloc);
          } else {
            return SignUpPage(authBloc: widget.authBloc);
          }
        },
        '/signin': (context) => SignInPage(authBloc: widget.authBloc),
        '/my-profile': (context) => MyProfilePage(authBloc: widget.authBloc),
        '/user-profile': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as String;
          if (widget.authBloc.isAuthenticated()) {
            return UserProfilePage(authBloc: widget.authBloc, userId: args);
          } else {
            return SignInPage(authBloc: widget.authBloc);
          }
        },
        '/send-image': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments as SendImageArguments;
          if (widget.authBloc.isAuthenticated()) {
            return SendImage(
              authBloc: widget.authBloc,
              image: args.image,
              currentUserId: args.currentUserId,
              receiverUserId: args.receiverUserId,
            );
          } else {
            return SignInPage(authBloc: widget.authBloc);
          }
        },
        '/send-audio': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments as SendAudioArguments;
          return SendAudio(
            authBloc: widget.authBloc,
            audio: args.audio,
            currentUserId: args.currentUserId,
            receiverUserId: args.receiverUserId,
          );
        },
        '/send-document': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as SendDocumentArguments;
          return SendDocument(
            authBloc: widget.authBloc,
            document: args.document,
            currentUserId: args.currentUserId,
            receiverUserId: args.receiverUserId,
          );
        },
        '/send-video': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments as SendVideoArguments;
          return SendVideo(
            authBloc: widget.authBloc,
            document: args.video,
            currentUserId: args.currentUserId,
            receiverUserId: args.receiverUserId,
          );
        },
        '/my-blogs': (context) => MyBlogsPage(authBloc: widget.authBloc),
        '/blog-view': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as String;
          if (widget.authBloc.isAuthenticated()) {
            return BlogView(authBloc: widget.authBloc, blogId: args);
          } else {
            return SignInPage(authBloc: widget.authBloc);
          }
        },
        '/chat': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as MessageNotificationArgs;
          if (widget.authBloc.isAuthenticated()) {
            print('receiverUserId: ${args.receiverUserId}');
            print('senderUserId: ${args.senderUserId}');
            print('route: ${args.route}');
            return ChatPage(
              authBloc: args.authBloc,
              receiverUserId: args.receiverUserId,
              currentUserId: args.senderUserId,
            );
          } else {
            return SignInPage(authBloc: widget.authBloc);
          }
        },
        '/blog-edit': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as String;
          if (widget.authBloc.isAuthenticated()) {
            return BlogEditPage(authBloc: widget.authBloc, blogId: args);
          } else {
            return SignInPage(authBloc: widget.authBloc);
          }
        },
        '/show-image': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as String;
          if (widget.authBloc.isAuthenticated()) {
            return ShowSentImage(imagePath: args);
          } else {
            return SignInPage(authBloc: widget.authBloc);
          }
        },
        '/manage-comments': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as String;
          if (widget.authBloc.isAuthenticated()) {
            return ManageCommentsPage(authBloc: widget.authBloc, blogId: args);
          } else {
            return SignInPage(authBloc: widget.authBloc);
          }
        },
      },
    );
  }
}
