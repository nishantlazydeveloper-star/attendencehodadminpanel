import 'package:adminpanel/core/const/colours.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void successSnackbar(String message, {String title = 'Success'}) {
  _showSnackbar(
    title: title,
    message: message,
    backgroundColor: AppColors.colour3F,
  );
}

void errorSnackbar(String message, {String title = 'Error'}) {
  _showSnackbar(
    title: title,
    message: message,
    backgroundColor: const Color(0xffD93025),
  );
}

void _showSnackbar({
  required String title,
  required String message,
  required Color backgroundColor,
}) {
  final messenger = rootScaffoldMessengerKey.currentState;
  if (messenger == null) {
    debugPrint('Snackbar blocked: ScaffoldMessenger unavailable');
    return;
  }

  if (Get.isDialogOpen ?? false) {
    debugPrint('Snackbar blocked: dialog still open');
    return;
  }

  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text('$title: $message'),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
}
