import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';

class FirebaseDynamicLinkService {
  static Future<String> createDynamicLink(String id) async {
    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: 'https://cleanblog.page.link',
      link: Uri.parse('https://cleanblog.page.link/blog?blogId=$id'),
      androidParameters: const AndroidParameters(
        packageName: 'com.example.blog',
        minimumVersion: 125,
      ),
      iosParameters: const IOSParameters(
        bundleId: 'com.example.ios',
        minimumVersion: '1.0.1',
        appStoreId: '123456789',
      ),
    );

    final Uri shortLink = parameters.link;

    return shortLink.toString();
  }
}
