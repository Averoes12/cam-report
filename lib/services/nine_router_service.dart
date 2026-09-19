import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class NineRouterService {
  NineRouterService._internal()
    : baseUrl = defaultBaseUrl,
      apiKey = defaultApiKey,
      model = defaultModel;

  static final NineRouterService instance = NineRouterService._internal();

  static const String defaultBaseUrl = 'https://r9.athanatius.my.id/v1';
  static const String defaultApiKey = 'sk-be3e5d2f289910f8-bzftzn-f8f0ee77';
  static const String defaultModel = 'ag/gemini-3.8-flash';

  final String baseUrl;
  final String apiKey;
  final String model;

  NineRouterService({
    this.baseUrl = defaultBaseUrl,
    this.apiKey = defaultApiKey,
    this.model = defaultModel,
  });

  /// Analyzes an image with a prompt using 9router OpenAI-compatible chat completion.
  Future<String> extractTextFromImage({
    required Uint8List imageBytes,
    String? prompt,
    String? customModel,
    String mimeType = 'image/jpeg',
  }) async {
    final effectivePrompt =
        prompt ??
        "Extract the handwriting text from this image. Return only the extracted text, no other comments.";

    final base64Image = base64Encode(imageBytes);
    final dataUri = 'data:$mimeType;base64,$base64Image';

    final uri = Uri.parse(
      '$baseUrl/chat/completions',
    ).replace(queryParameters: {'key': apiKey});
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    final payload = {
      'model': customModel ?? model,
      'stream': false,
      'messages': [
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': effectivePrompt},
            {
              'type': 'image_url',
              'image_url': {'url': dataUri},
            },
          ],
        },
      ],
    };

    try {
      final response = await http
          .post(uri, headers: headers, body: jsonEncode(payload))
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final choices = data['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final content = choices[0]['message']?['content'] as String?;
          return content?.trim() ?? '';
        }
        return '';
      } else if (response.statusCode == 429) {
        throw Exception(
          'Limit AI / Kuota API tercapai (429). Silakan coba beberapa saat lagi.',
        );
      } else {
        throw Exception(
          'Request failed with status: ${response.statusCode}, body: ${response.body}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
