import 'package:flutter/material.dart';
import '../../shared/widgets/app_floating_toast.dart';

extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  Size get screenSize => MediaQuery.sizeOf(this);

  void showSnackBar(
    String message, {
    Duration duration = const Duration(milliseconds: 1800),
    bool? isSuccess,
    IconData? icon,
    Color? iconColor,
    double? bottomOffset,
  }) {
    AppFloatingToast.show(
      this,
      message: message,
      isSuccess: isSuccess,
      icon: icon,
      iconColor: iconColor,
      duration: duration,
      bottomOffset: bottomOffset,
    );
  }
}
