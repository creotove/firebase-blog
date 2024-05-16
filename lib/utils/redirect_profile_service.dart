import 'package:blog/authentication.dart';

Future<bool> redirectProfileService(String blogOwnerId) async {
  try {
    final AuthenticationBloc authBloc = AuthenticationBloc();
    final loggedInUserId = await authBloc.getCurrentUserId();
    if (loggedInUserId == blogOwnerId) {
      return true;
    } else {
      return false;
    }
  } catch (e) {
    print(e);
    throw e;
  }
}
