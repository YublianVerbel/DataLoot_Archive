import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/noticia.dart';
import '../widgets/noticia_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _filtroFuente = 'Todas';
  late Future<List<Noticia>> _noticiasFuture;

  // ⚠️ Reemplaza esto con la URL de tu Webhook de N8N
  static const String _webhookUrl =
      'https://tu-n8n.app.n8n.cloud/webhook/noticias';

  final List<String> _fuentes = [
    'Todas', 'Vandal', 'Eurogamer', 'Gamespot', 'Kotaku', 'PCGamer'
  ];

  @override
  void initState() {
    super.initState();
    _noticiasFuture = _getNoticias();
  }

  Future<List<Noticia>> _getNoticias() async {
    try {
      final uri = _filtroFuente != 'Todas'
          ? Uri.parse('$_webhookUrl?source=$_filtroFuente')
          : Uri.parse(_webhookUrl);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((item) => Noticia.fromFirestore(
                item as Map<String, dynamic>, item['id'] ?? ''))
            .toList();
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('No se pudo conectar con N8N: $e');
    }
  }

  void _cambiarFuente(String fuente) {
    setState(() {
      _filtroFuente = fuente;
      _noticiasFuture = _getNoticias();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Row(
          children: [
            Text('🎮', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text(
              'DataLoot Archive',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filtros por fuente
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _fuentes.length,
              itemBuilder: (context, index) {
                final fuente = _fuentes[index];
                final isSelected = fuente == _filtroFuente;
                return GestureDetector(
                  onTap: () => _cambiarFuente(fuente),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF6C63FF)
                          : const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        fuente,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Lista de noticias con FutureBuilder
          Expanded(
            child: FutureBuilder<List<Noticia>>(
              future: _noticiasFuture,
              builder: (context, snapshot) {
                // Estado de carga
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF6C63FF)),
                        SizedBox(height: 16),
                        Text(
                          'Cargando noticias...',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                // Estado de error
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        const Text(
                          'Error al cargar noticias',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => _cambiarFuente(_filtroFuente),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C63FF),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Sin datos
                final noticias = snapshot.data ?? [];
                if (noticias.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay noticias aún',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                // Lista con pull to refresh
                return RefreshIndicator(
                  color: const Color(0xFF6C63FF),
                  onRefresh: () async => _cambiarFuente(_filtroFuente),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: noticias.length,
                    itemBuilder: (context, index) =>
                        NoticiaCard(noticia: noticias[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}