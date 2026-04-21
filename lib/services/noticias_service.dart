import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/noticia.dart';

class NoticiasService {
  static const String _webhookUrl =
      'https://bread12.app.n8n.cloud/webhook/noticias';

  Future<List<Noticia>> getNoticias({String? source}) async {
    try {
      final uri = source != null && source != 'Todas'
          ? Uri.parse('$_webhookUrl?source=$source')
          : Uri.parse(_webhookUrl);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((item) => Noticia.fromFirestore(item, item['id'] ?? ''))
            .toList();
      } else {
        throw Exception('Error ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al conectar con N8N: $e');
    }
  }
}