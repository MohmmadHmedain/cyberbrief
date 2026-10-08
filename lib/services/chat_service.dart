import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  // غيّر هذا العنوان حسب مكان تشغيل الـ FastAPI Backend
  static const String apiUrl = "http://10.0.2.2:8000/chat";

  static Future<String> sendMessage(String message) async {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "messages": [
          {
            "role": "user",
            "content": message,
          }
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["reply"] ?? "لم يتم الحصول على رد.";
    } else {
      throw Exception(
        "فشل الاتصال بخدمة المساعد: ${response.statusCode}",
      );
    }
  }
}