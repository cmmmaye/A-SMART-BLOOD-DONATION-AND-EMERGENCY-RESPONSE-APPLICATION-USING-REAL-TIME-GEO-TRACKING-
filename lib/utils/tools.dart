import 'dart:math' show sqrt;

import 'package:flutter/material.dart';

class Tools {
  static bool isTablet(Size size) {
    final diagonal = sqrt(
      (size.width * size.width) + (size.height * size.height),
    );
    return diagonal > 1100.0;
  }

  static String formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }

  static String formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      // Today - show time
      final hour = date.hour;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return formatDate(date);
    }
  }

  static bool isNullOrEmpty(String? s) => s == null || s.isEmpty;
}
