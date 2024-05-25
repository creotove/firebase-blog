import 'package:flutter/material.dart';

// Utility class to get the context and navigator key
class ContextUtilityService {
  static final GlobalKey<NavigatorState> _navigatorKey =
      GlobalKey<NavigatorState>();
  // Getter for navigator key
  static GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  // Getter for navigator state
  static NavigatorState? get navigator => navigatorKey.currentState;
  // Getter for context
  static BuildContext? get context => navigator?.overlay?.context;
}
