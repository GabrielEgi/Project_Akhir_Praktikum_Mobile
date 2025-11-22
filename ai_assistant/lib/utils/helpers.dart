import 'dart:async';
import 'package:intl/intl.dart';

/// Helper class untuk format tanggal dan waktu
class DateTimeHelper {
  /// Format datetime menjadi string relatif (contoh: "2 jam yang lalu")
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit yang lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inDays == 1) {
      return 'Kemarin';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari yang lalu';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks minggu yang lalu';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months bulan yang lalu';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years tahun yang lalu';
    }
  }

  /// Format datetime menjadi string dengan format tertentu
  static String formatDateTime(
    DateTime dateTime, {
    String format = 'dd/MM/yyyy HH:mm',
  }) {
    return DateFormat(format).format(dateTime);
  }

  /// Format jam saja
  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  /// Format tanggal saja
  static String formatDate(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }

  /// Check apakah hari ini
  static bool isToday(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  /// Check apakah kemarin
  static bool isYesterday(DateTime dateTime) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return dateTime.year == yesterday.year &&
        dateTime.month == yesterday.month &&
        dateTime.day == yesterday.day;
  }
}

/// Helper class untuk validasi
class ValidationHelper {
  /// Validasi email
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Validasi nomor telepon Indonesia
  static bool isValidPhoneNumber(String phone) {
    final phoneRegex = RegExp(r'^(\+62|62|0)[0-9]{9,12}$');
    return phoneRegex.hasMatch(phone);
  }

  /// Validasi tidak kosong
  static bool isNotEmpty(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  /// Validasi panjang minimum
  static bool hasMinLength(String value, int minLength) {
    return value.length >= minLength;
  }

  /// Validasi panjang maksimum
  static bool hasMaxLength(String value, int maxLength) {
    return value.length <= maxLength;
  }
}

/// Helper class untuk formatting text
class TextHelper {
  /// Truncate text dengan ellipsis
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}...';
  }

  /// Capitalize first letter
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Convert to title case
  static String toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) => capitalize(word)).join(' ');
  }

  /// Remove extra whitespace
  static String normalizeWhitespace(String text) {
    return text.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Count words
  static int countWords(String text) {
    return text.trim().split(RegExp(r'\s+')).length;
  }

  /// Count tokens (rough estimate: 1 token ≈ 4 characters)
  static int estimateTokens(String text) {
    return (text.length / 4).ceil();
  }
}

/// Helper class untuk error handling
class ErrorHelper {
  /// Get user-friendly error message
  static String getUserFriendlyMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('socket')) {
      return 'Tidak dapat terhubung ke internet. Periksa koneksi Anda.';
    } else if (errorString.contains('timeout')) {
      return 'Koneksi timeout. Coba lagi.';
    } else if (errorString.contains('unauthorized') ||
        errorString.contains('401')) {
      return 'API key tidak valid. Periksa konfigurasi.';
    } else if (errorString.contains('rate limit') ||
        errorString.contains('429')) {
      return 'Terlalu banyak permintaan. Tunggu sebentar.';
    } else if (errorString.contains('500') ||
        errorString.contains('server error')) {
      return 'Server sedang bermasalah. Coba lagi nanti.';
    } else if (errorString.contains('not found') ||
        errorString.contains('404')) {
      return 'Resource tidak ditemukan.';
    } else {
      return 'Terjadi kesalahan. Silakan coba lagi.';
    }
  }
}

/// Helper class untuk storage
class StorageHelper {
  /// Format file size
  static String formatFileSize(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB'];
    var size = bytes.toDouble();
    var unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return '${size.toStringAsFixed(2)} ${units[unitIndex]}';
  }

  /// Get file extension
  static String getFileExtension(String filename) {
    final parts = filename.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  /// Check if file is image
  static bool isImageFile(String filename) {
    final ext = getFileExtension(filename);
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext);
  }

  /// Check if file is document
  static bool isDocumentFile(String filename) {
    final ext = getFileExtension(filename);
    return [
      'pdf',
      'doc',
      'docx',
      'txt',
      'xls',
      'xlsx',
      'ppt',
      'pptx',
    ].contains(ext);
  }
}

/// Helper class untuk debouncing
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 500)});

  void call(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

/// Helper class untuk loading state
class LoadingHelper {
  static bool _isLoading = false;

  static bool get isLoading => _isLoading;

  static void show() {
    _isLoading = true;
  }

  static void hide() {
    _isLoading = false;
  }
}