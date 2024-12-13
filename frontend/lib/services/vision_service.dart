import 'package:http/http.dart' as http;
import 'dart:convert';

class VisionService {
  static const String _baseUrl =
      'https://getoutfitsuggestions-348449317363.us-central1.run.app';

  Future<String> getOutfitSuggestions({
    required String item,
    required String expression,
    required String temperature,
    required String season,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/getOutfitSuggestions'
          '?item=$item'
          '&expression=$expression'
          '&temperature=$temperature'
          '&season=$season',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['suggestions'];
      } else {
        throw Exception('Failed to get outfit suggestions');
      }
    } catch (e) {
      print('Error getting outfit suggestions: $e');
      return 'Unable to generate outfit suggestions at this time.';
    }
  }
}
