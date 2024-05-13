// ignore_for_file: avoid_print

import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';

void initDynamicLinks(BuildContext context) async {
  FirebaseDynamicLinks.instance.onLink;

  final data = await FirebaseDynamicLinks.instance.getInitialLink();
  print("data : $data");
  final deepLink = await data?.link;
  if (deepLink != null) {
    final queryParams = deepLink.queryParameters;
    print('queryParams : $queryParams');
    if (queryParams.containsKey('blogId')) {
      final blogId = queryParams['blogId'];
      print('blogid : $blogId');

      Navigator.pushNamed(context, '/blog-view', arguments: blogId);
      print("Navigated to blog view page");
    }
  }
}
