import 'package:blog/features/screens/blog/add_blog_page.dart';
import 'package:blog/features/screens/blog/blog_edit.dart';
import 'package:blog/features/screens/blog/blog_view_page.dart';
import 'package:blog/features/screens/blog/comments/manage_comments.dart';
import 'package:blog/features/screens/blog/home_page.dart';
import 'package:blog/features/screens/auth/sign_in_page.dart';
import 'package:blog/features/screens/auth/sign_up_page.dart';
import 'package:blog/features/screens/chat/chat.dart';
import 'package:blog/features/screens/profile/edit_profile.dart';
import 'package:blog/features/screens/profile/my_blogs.dart';
import 'package:blog/features/screens/profile/my_profile.dart';
import 'package:blog/features/screens/profile/user_profile.dart';
import 'package:blog/theme/theme.dart';
import 'package:blog/utils/context_utility_service.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:blog/authentication.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final authBloc = AuthenticationBloc();
  runApp(MyApp(authBloc: authBloc)); // Pass the function as argument
}

class MyApp extends StatefulWidget {
  final AuthenticationBloc authBloc;

  const MyApp({required this.authBloc});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  void initDynamicLinks(BuildContext context) async {
    try {
      FirebaseDynamicLinks.instance.onLink.listen((dynamicLink) {
        final Uri deepLink = dynamicLink.link;
        var isBlog = deepLink.pathSegments.contains('blog-view');
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
      final PendingDynamicLinkData? data =
          await FirebaseDynamicLinks.instance.getInitialLink();
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initDynamicLinks(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Blog App',
      theme: AppTheme.darkThemeMode,
      navigatorKey: ContextUtilityService.navigatorKey,
      initialRoute: '/',
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
        '/edit-profile': (context) =>
            EditProfilePage(authBloc: widget.authBloc),
        '/signup': (context) => SignUpPage(authBloc: widget.authBloc),
        '/my-profile': (context) => MyProfilePage(authBloc: widget.authBloc),
        '/user-profile': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as String;
          if (widget.authBloc.isAuthenticated()) {
            return UserProfilePage(authBloc: widget.authBloc, userId: args);
          } else {
            return SignInPage(authBloc: widget.authBloc);
          }
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
          final args = ModalRoute.of(context)!.settings.arguments as String;
          if (widget.authBloc.isAuthenticated()) {
            return ChatPage(authBloc: widget.authBloc, receiverUsedId: args);
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
