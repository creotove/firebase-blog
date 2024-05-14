import 'package:blog/features/screens/blog/add_blog_page.dart';
import 'package:blog/features/screens/blog/blog_screen.dart';
import 'package:blog/features/screens/blog/home_page.dart';
import 'package:blog/features/screens/auth/sign_in_page.dart';
import 'package:blog/features/screens/auth/sign_up_page.dart';
import 'package:blog/features/screens/profile/edit_profile.dart';
import 'package:blog/features/screens/profile/profile_page.dart';
import 'package:blog/theme/theme.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:blog/authentication.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp();
//   final authBloc = AuthenticationBloc();

//   void initDynamicLinks() async {
//     FirebaseDynamicLinks.instance.onLink;

//     final data = await FirebaseDynamicLinks.instance.getInitialLink();
//     final deepLink = data?.link;
//     if (deepLink != null) {
//       final queryParams = deepLink.queryParameters;
//       if (queryParams.containsKey('blogId')) {
//         final blogId = queryParams['blogId'];
//         Navigator.pushNamed(context, '/blog-view', arguments: blogId);
//       }
//     }
//   }

//   initDynamicLinks();
//   runApp(MyApp(authBloc: authBloc));
// }

// class MyApp extends StatefulWidget {
//   final AuthenticationBloc authBloc;

//   const MyApp({required this.authBloc});

//   @override
//   State<MyApp> createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//   @override
//   void initState() {
//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Blog App',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//         visualDensity: VisualDensity.adaptivePlatformDensity,
//       ),
//       initialRoute: '/',
//       routes: {
//         '/': (context) {
//           if (widget.authBloc.isAuthenticated()) {
//             return HomePage(authBloc: widget.authBloc);
//           } else {
//             return SignInPage(authBloc: widget.authBloc);
//           }
//         },
//         '/add-blog': (context) {
//           if (widget.authBloc.isAuthenticated()) {
//             return AddBlogPage(authBloc: widget.authBloc);
//           } else {
//             return SignInPage(authBloc: widget.authBloc);
//           }
//         },
//         '/login': (context) => SignInPage(authBloc: widget.authBloc),
//         '/signup': (context) => SignUpPage(authBloc: widget.authBloc),
//         '/blog-view': (context) {
//           final args = ModalRoute.of(context)!.settings.arguments as String;
//           if (widget.authBloc.isAuthenticated()) {
//             return BlogView(authBloc: widget.authBloc, blogId: args);
//           } else {
//             return SignInPage(authBloc: widget.authBloc);
//           }
//         },
//       },
//     );
//   }
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final authBloc = AuthenticationBloc();

  void initDynamicLinks(BuildContext context) async {
    FirebaseDynamicLinks.instance.onLink;
    FirebaseAnalytics analytics = FirebaseAnalytics.instance;
    print(analytics.appInstanceId);

    final data = await FirebaseDynamicLinks.instance.getInitialLink();
    final deepLink = data?.link;
    if (deepLink != null) {
      final queryParams = deepLink.queryParameters;
      if (queryParams.containsKey('blogId')) {
        final blogId = queryParams['blogId'];
        Navigator.pushNamed(context, '/blog-view', arguments: blogId);
      }
    }
  }

  runApp(MyApp(
      authBloc: authBloc,
      initDynamicLinks: initDynamicLinks)); // Pass the function as argument
}

class MyApp extends StatefulWidget {
  final AuthenticationBloc authBloc;
  final Function(BuildContext) initDynamicLinks; // Define the function here

  const MyApp({required this.authBloc, required this.initDynamicLinks});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    widget.initDynamicLinks(context);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Blog App',
      theme: AppTheme.darkThemeMode,
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
        '/profile': (context) => ProfilePage(authBloc: widget.authBloc),
        '/blog-view': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as String;
          if (widget.authBloc.isAuthenticated()) {
            return BlogView(authBloc: widget.authBloc, blogId: args);
          } else {
            return SignInPage(authBloc: widget.authBloc);
          }
        },
      },
    );
  }
}
