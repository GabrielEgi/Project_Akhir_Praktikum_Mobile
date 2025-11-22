# ChatGPT Clone - AI Assistant App

Aplikasi AI Assistant pribadi yang dibuat dengan Flutter, mirip dengan ChatGPT. Aplikasi ini memiliki fitur CRUD (Create, Read, Update, Delete) untuk mengelola percakapan dengan AI.

## Fitur Utama

✅ **Chat dengan AI** - Berkomunikasi dengan AI assistant menggunakan API OpenAI
✅ **CRUD Operations** - Buat, baca, update, dan hapus percakapan
✅ **Local Storage** - Simpan riwayat chat secara offline dengan SQLite
✅ **Material Design** - UI yang modern dan responsif
✅ **State Management** - Menggunakan Provider untuk state management
✅ **Authentication** - Login dengan Google atau telepon (opsional)

## Struktur Project

```
chatgpt_clone/
├── lib/
│   ├── models/
│   │   ├── chat.dart              # Model untuk Chat
│   │   └── message.dart           # Model untuk Message
│   ├── services/
│   │   ├── database_helper.dart   # SQLite database service
│   │   └── api_service.dart       # API service untuk OpenAI
│   ├── providers/
│   │   └── chat_provider.dart     # State management dengan Provider
│   ├── screens/
│   │   ├── auth_screen.dart       # Halaman login/authentication
│   │   └── home_screen.dart       # Halaman utama chat
│   ├── widgets/
│   │   ├── chat_list_item.dart    # Widget item chat di drawer
│   │   ├── message_bubble.dart    # Widget bubble pesan
│   │   └── input_field.dart       # Widget input field
│   └── main.dart                  # Entry point aplikasi
└── pubspec.yaml                   # Dependencies
```

## Instalasi

### 1. Install Flutter

Pastikan Flutter sudah terinstall di sistem Anda. Cek dengan:

```bash
flutter --version
```

Jika belum, install dari [flutter.dev](https://flutter.dev)

### 2. Clone/Download Project

Download project ini ke komputer Anda.

### 3. Install Dependencies

```bash
cd chatgpt_clone
flutter pub get
```

### 4. Konfigurasi API Key

**PENTING:** Anda perlu API key dari OpenAI untuk menggunakan aplikasi ini.

1. Buka file `lib/services/api_service.dart`
2. Ganti `YOUR_API_KEY_HERE` dengan API key Anda:

```dart
static const String apiKey = 'sk-your-actual-api-key-here';
```

**Cara mendapatkan API Key:**
- Daftar di [platform.openai.com](https://platform.openai.com)
- Buat API key di dashboard
- Copy API key dan paste ke kode

**Catatan Keamanan:** 
- Untuk production, jangan hardcode API key di kode
- Gunakan environment variable atau secure storage
- Pertimbangkan membuat backend API sendiri

### 5. Jalankan Aplikasi

```bash
flutter run
```

## Konfigurasi Google Sign-In (Opsional)

Jika ingin menggunakan fitur Google Sign-In:

### Android:

1. Buat project di [Firebase Console](https://console.firebase.google.com)
2. Download `google-services.json`
3. Letakkan di `android/app/`
4. Update `android/build.gradle` dan `android/app/build.gradle`

### iOS:

1. Download `GoogleService-Info.plist`
2. Letakkan di `ios/Runner/`
3. Update `Info.plist`

## Penggunaan Aplikasi

### Membuat Chat Baru

1. Tap icon menu (☰) di kiri atas
2. Tap "Obrolan baru" atau icon edit

### Mengirim Pesan

1. Ketik pesan di kolom input di bawah
2. Tap tombol kirim (↑) atau tekan Enter

### Mengelola Chat

- **Ubah Judul**: Tap icon (⋮) > "Ubah judul"
- **Hapus Chat**: Tap icon (⋮) > "Hapus obrolan"
- **Pindah Chat**: Tap chat di drawer kiri

### Fitur Input

- **Text**: Ketik langsung di input field
- **Attachment**: Tap icon 📎 untuk upload (coming soon)
  - Kamera
  - Foto
  - File

## CRUD Operations

### Create (Buat)
```dart
await chatProvider.createNewChat();
```

### Read (Baca)
```dart
await chatProvider.selectChat(chatId);
final chats = chatProvider.chats;
final messages = chatProvider.currentMessages;
```

### Update (Update)
```dart
await chatProvider.updateChatTitle(chatId, newTitle);
```

### Delete (Hapus)
```dart
await chatProvider.deleteChat(chatId);
```

## Customization

### Ganti Model AI

Edit di `lib/services/api_service.dart`:

```dart
Future<String> sendMessage({
  required List<Message> messages,
  String model = 'gpt-4', // Ganti model di sini
}) async {
  // ...
}
```

Model yang tersedia:
- `gpt-3.5-turbo` (lebih murah, cepat)
- `gpt-4` (lebih pintar, lebih mahal)
- `gpt-4-turbo`

### Ubah Warna Tema

Edit di `lib/main.dart`:

```dart
theme: ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Colors.black, // Ganti warna background
  // ...
)
```

### Ubah Avatar

Edit di `lib/widgets/message_bubble.dart`:

```dart
CircleAvatar(
  backgroundColor: Colors.blue, // Ganti warna
  child: Icon(Icons.person), // Ganti icon
)
```

## Troubleshooting

### Error: API Key tidak valid
- Pastikan API key sudah benar
- Cek apakah API key masih aktif di dashboard OpenAI
- Pastikan ada kredit di akun OpenAI

### Error: Database
```bash
flutter clean
flutter pub get
flutter run
```

### Error: Google Sign-In
- Pastikan konfigurasi Firebase sudah benar
- Cek SHA-1 fingerprint di Firebase Console

## Dependencies

Aplikasi ini menggunakan:

- `provider` - State management
- `sqflite` - Local database
- `http` & `dio` - HTTP client
- `google_sign_in` - Authentication
- `google_fonts` - Custom fonts
- `shared_preferences` - Key-value storage
- `intl` - Internationalization
- `uuid` - Generate unique IDs

## Build untuk Production

### Android APK:
```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle:
```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### iOS:
```bash
flutter build ios --release
```

## Roadmap

- [ ] Upload & preview gambar
- [ ] Upload & read dokumen (PDF, DOCX)
- [ ] Voice input (speech-to-text)
- [ ] Text-to-speech untuk respons AI
- [ ] Export percakapan (PDF, TXT)
- [ ] Search dalam percakapan
- [ ] Dark/Light theme toggle
- [ ] Multi-language support
- [ ] Streaming response (real-time)
- [ ] Code syntax highlighting
- [ ] Markdown rendering

## Lisensi

MIT License - Bebas digunakan dan dimodifikasi

## Kontak & Support

Jika ada pertanyaan atau masalah, silakan buat issue di repository ini.

## Catatan Penting

⚠️ **Keamanan API Key:**
- Jangan commit API key ke Git
- Tambahkan `lib/config/api_keys.dart` ke `.gitignore`
- Untuk production, gunakan backend proxy

⚠️ **Biaya OpenAI:**
- API OpenAI berbayar per request
- Monitor penggunaan di dashboard OpenAI
- Set limit untuk menghindari biaya tak terduga

⚠️ **Privacy:**
- Data chat disimpan di device user
- Pastikan enkripsi database untuk data sensitif
- Buat privacy policy jika publish ke store

---

**Happy Coding! 🚀**