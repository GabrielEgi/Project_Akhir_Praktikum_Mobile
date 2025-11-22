import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';

class ApiService {
  // Ganti dengan API endpoint Anda
  static const String baseUrl = 'https://api.openai.com/v1';

  // Ganti dengan API key Anda
  // PENTING: Untuk production, simpan API key di environment variable atau secure storage
  static const String apiKey = 'YOUR_API_KEY_HERE';

  // Fungsi untuk mengirim pesan dan mendapat respons dari AI
  Future<String> sendMessage({
    required List<Message> messages,
    String model = 'gpt-3.5-turbo',
  }) async {
    try {
      final url = Uri.parse('$baseUrl/chat/completions');

      // Convert messages to API format
      final apiMessages = messages.map((msg) {
        return {'role': msg.role.name, 'content': msg.content};
      }).toList();

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': apiMessages,
          'temperature': 0.7,
          'max_tokens': 2000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        return content;
      } else {
        throw Exception('Failed to get response: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }

  // Fungsi untuk generate title dari percakapan
  Future<String> generateChatTitle(String firstMessage) async {
    try {
      final url = Uri.parse('$baseUrl/chat/completions');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content':
                  'Generate a short title (max 5 words) for this conversation. Only return the title, nothing else.',
            },
            {'role': 'user', 'content': firstMessage},
          ],
          'temperature': 0.5,
          'max_tokens': 20,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].toString().trim();
      } else {
        // Fallback title jika gagal
        return firstMessage.length > 30
            ? '${firstMessage.substring(0, 30)}...'
            : firstMessage;
      }
    } catch (e) {
      // Fallback title jika error
      return firstMessage.length > 30
          ? '${firstMessage.substring(0, 30)}...'
          : firstMessage;
    }
  }
}
