import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = "https://api.bmkg.go.id/publik/prakiraan-cuaca?adm4={kode_wilayah_tingkat_iv}";

  // ambil data cuaca berdasarkan adm4 (kecamatan/kelurahan)
  Future<Map<String, dynamic>?> getWeather(String adm4) async {
  try {
    final url = Uri.parse("$baseUrl?adm4=$adm4");
    final response = await http.get(url);

    print("URL: $url");
    print("STATUS: ${response.statusCode}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return null; // <= biar ga crash
  } catch (e) {
    print("Error API BMKG: $e");
    return null;
  }
}

}
