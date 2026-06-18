import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucky_wheel/models/wheel_template.dart';

/// Provides the list of built-in templates.
final templatesProvider = Provider<List<WheelTemplate>>((ref) {
  return WheelTemplate.builtIn;
});
