import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'AI Assistant';
  static const String appVersion = '1.0.0';

  static const String chatsBoxName = 'chats';
  static const String messagesBoxName = 'messages';
  static const String usersBoxName = 'users';

  static const int apiTimeout = 30;
  static const int maxRetries = 3;

  static const int maxChatHistoryLength = 10;
  static const int maxTitleLength = 50;

  static const double borderRadius = 12.0;
  static const double avatarRadius = 16.0;
  static const double messageSpacing = 16.0;
}

class AppColors {
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF1A1A1A);
  static const Color darkCard = Color(0xFF2D2D2D);

  static const Color primary = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFF6B7280);

  static const Color userMessage = Color(0xFF3B82F6);
  static const Color assistantMessage = Color(0xFF10B981);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textHint = Color(0xFF6B7280);

  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
}

class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static const TextStyle body2 = TextStyle(
    fontSize: 14,
    color: AppColors.textPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  static const TextStyle messageUser = TextStyle(
    fontSize: 15,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle messageAssistant = TextStyle(
    fontSize: 15,
    color: AppColors.textPrimary,
    height: 1.4,
  );
}

class AppDurations {
  static const Duration short = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration long = Duration(milliseconds: 500);

  static const Duration snackBar = Duration(seconds: 2);
  static const Duration toast = Duration(seconds: 1);
}

class AppPaddings {
  static const EdgeInsets screenPadding = EdgeInsets.all(16.0);
  static const EdgeInsets cardPadding = EdgeInsets.all(12.0);
  static const EdgeInsets listPadding = EdgeInsets.all(8.0);

  static const EdgeInsets small = EdgeInsets.all(8.0);
  static const EdgeInsets medium = EdgeInsets.all(16.0);
  static const EdgeInsets large = EdgeInsets.all(24.0);
}

class AppStrings {
  static const String appName = 'AI Assistant';
  static const String ok = 'OK';
  static const String cancel = 'Batal';
  static const String save = 'Simpan';
  static const String delete = 'Hapus';
  static const String edit = 'Ubah';
  static const String send = 'Kirim';

  static const String signIn = 'Masuk';
  static const String signUp = 'Daftar';
  static const String signOut = 'Keluar';

  static const String newChat = 'Obrolan baru';
  static const String chatHistory = 'Riwayat obrolan';
  static const String noChats = 'Belum ada obrolan';
  static const String deleteChat = 'Hapus obrolan';
  static const String deleteChatConfirm =
      'Apakah Anda yakin ingin menghapus obrolan ini?';
  static const String renameChat = 'Ubah judul';
  static const String chatDeleted = 'Obrolan dihapus';

  static const String sendMessage = 'Kirim pesan';
  static const String typeMessage = 'Ketik pesan...';
  static const String messageCopied = 'Pesan disalin';
  static const String you = 'Anda';
  static const String assistant = 'AI Assistant';

  static const String errorOccurred = 'Terjadi kesalahan';
  static const String errorNetwork = 'Kesalahan jaringan';
  static const String errorApiKey = 'API key tidak valid';
  static const String errorLoading = 'Gagal memuat data';

  static const String settings = 'Pengaturan';
  static const String privacy = 'Privasi';
  static const String termsOfService = 'Ketentuan Penggunaan';
  static const String privacyPolicy = 'Kebijakan Privasi';

  static const String suggestionsTitle = 'Apa yang bisa saya bantu?';
  static const String getAdvice = 'Dapatkan nasihat';
  static const String createPlan = 'Buatkan rencana';
  static const String summarizeText = 'Rangkum teks';
  static const String writeCode = 'Kode';

  static const String camera = 'Kamera';
  static const String photo = 'Foto';
  static const String file = 'File';
}
