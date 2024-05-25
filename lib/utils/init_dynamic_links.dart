// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';

// For handling dynamic links
class FirebaseDynamicLinksService {
  // Method to create dynamic link for the blog so that it can be shared and when clicked, it will open the blog view
  static Future<String> createDynamicLink(bool short, String blogId) async {
    final dynamicLinks = FirebaseDynamicLinks.instance;
    // Create a dynamic link
    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: 'https://cleanblog.page.link/',
      link: Uri.parse('https://cleanblog.page.link/blog-view?blogId=$blogId'),
      androidParameters: const AndroidParameters(
        packageName: 'com.example.blog',
        minimumVersion: 0,
      ),
    );

    // Build the dynamic link and return
    Uri url;
    if (short) {
      final ShortDynamicLink shortLink =
          await dynamicLinks.buildShortLink(parameters);
      url = shortLink.shortUrl;
    } else {
      url = await dynamicLinks.buildLink(parameters);
    }
    return url.toString();
  }

  // Method to initialize dynamic links
  static Future<void> initDynamicLinks(BuildContext context) async {
    // Listen for incoming dynamic links
    FirebaseDynamicLinks.instance.onLink.listen((dynamicLink) {
      final Uri deepLink = dynamicLink.link;
      // Check if the deep link is for blog view
      var isBlog = deepLink.pathSegments.contains('blog-view');
      if (isBlog) {
        final queryParams = deepLink.queryParameters;
        if (queryParams.containsKey('blogId')) {
          // Open the blog view screen
          final blogId = queryParams['blogId'];
          Navigator.pushNamed(context, '/blog-view', arguments: blogId);
        }
      }
    });
    final PendingDynamicLinkData? data =
        await FirebaseDynamicLinks.instance.getInitialLink();
    final Uri? deepLink = data?.link;
    if (deepLink != null) {
      var isBlog = deepLink.pathSegments.contains('blog-view');
      if (isBlog) {
        final queryParams = deepLink.queryParameters;
        if (queryParams.containsKey('blogId')) {
          final blogId = queryParams['blogId'];
          Navigator.pushNamed(context, '/blog-view', arguments: blogId);
          return;
        }
      }
    }
  }
}
