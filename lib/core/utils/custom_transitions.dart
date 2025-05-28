// Crear un archivo custom_transitions.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomTransitions {
  static GetPageRoute slideTransition({
    required Widget page,
    RouteSettings? settings,
    bool opaque = true,
  }) {
    return GetPageRoute(
      page: () => page,
      settings: settings,
      opaque: opaque,
      transition: Transition.rightToLeft,
      curve: Curves.easeInOut,
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  static GetPageRoute fadeTransition({
    required Widget page,
    RouteSettings? settings,
    bool opaque = true,
  }) {
    return GetPageRoute(
      page: () => page,
      settings: settings,
      opaque: opaque,
      transition: Transition.fade,
      curve: Curves.easeInOut,
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  static GetPageRoute zoomTransition({
    required Widget page,
    RouteSettings? settings,
    bool opaque = true,
  }) {
    return GetPageRoute(
      page: () => page,
      settings: settings,
      opaque: opaque,
      transition: Transition.zoom,
      curve: Curves.easeInOut,
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
