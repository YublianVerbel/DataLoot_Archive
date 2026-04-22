import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/noticia.dart';
import '../widgets/noticia_card.dart';
import 'notificaciones_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _filtroFuente = 'Todas';
  late Future<List<Noticia>> _noticiasFuture;

  static const String _webhookUrl =
      'https://bread12.app.n8n.cloud/webhook/noticias';

  // Cache local
  static final Map<String, List<Noticia>> _cache = {};
  static final Map<String, DateTime> _cacheTime = {};
  static const Duration _cacheDuration = Duration(minutes: 5);

  final List<String> _fuentes = [
    'Todas',
    'Eurogamer',
    'HobbyConsolas',
    'Gamespot',
    'Kotaku',
    'PCGamer',
    'Vandal',
  ];

  @override
  void initState() {
    super.initState();
    _noticiasFuture = _getNoticias();
  }

  Future<List<Noticia>> _getNoticias() async {
    // Verifica si hay cache valido
    final cacheKey = _filtroFuente;
    final ahora = DateTime.now();

    if (_cache.containsKey(cacheKey) && _cacheTime.containsKey(cacheKey)) {
      final tiempoCache = _cacheTime[cacheKey]!;
      if (ahora.difference(tiempoCache) < _cacheDuration) {
        return _cache[cacheKey]!;
      }
    }

    int intentos = 0;
    const maxIntentos = 2;

    while (intentos < maxIntentos) {
      try {
        intentos++;
        String url = _webhookUrl;
        if (_filtroFuente != 'Todas') {
          url = '$_webhookUrl?source=$_filtroFuente';
        }

        final response = await http
            .get(
              Uri.parse(url),
              headers: {'Content-Type': 'application/json'},
            )
            .timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final body = response.body.trim();
          if (body.isEmpty) return [];

          final dynamic decoded = json.decode(body);
          if (decoded is! List) return [];

          final noticias = decoded
              .where((item) => item is Map)
              .map((item) {
                final map = item as Map<String, dynamic>;
                final id = map['_id'] ?? map['id'] ?? '';
                return Noticia.fromFirestore(map, id);
              })
              .where((n) => n.title.isNotEmpty)
              .toList();

          // Guarda en cache
          _cache[cacheKey] = noticias;
          _cacheTime[cacheKey] = ahora;

          return noticias;
        } else {
          throw Exception('Error del servidor: ${response.statusCode}');
        }
      } catch (e) {
        if (intentos >= maxIntentos) {
          // Si hay cache aunque sea viejo, usalo
          if (_cache.containsKey(cacheKey)) {
            return _cache[cacheKey]!;
          }
          throw Exception('No se pudo conectar con N8N');
        }
        await Future.delayed(const Duration(seconds: 5));
      }
    }
    return [];
  }

  void _cambiarFuente(String fuente) {
    setState(() {
      _filtroFuente = fuente;
      _noticiasFuture = _getNoticias();
    });
  }

  void _refrescarForzado() {
    // Limpia el cache de la fuente actual y recarga
    _cache.remove(_filtroFuente);
    _cacheTime.remove(_filtroFuente);
    setState(() {
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refrescarForzado,
            tooltip: 'Actualizar noticias',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificacionesScreen(),
                ),
              );
            },
          ),
        ],
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
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Esto puede tardar unos segundos',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
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
                        const Icon(
                          Icons.wifi_off_rounded,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Error al cargar noticias',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'Verifica tu conexion a internet e intenta de nuevo',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _refrescarForzado,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C63FF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Sin datos
                final noticias = snapshot.data ?? [];
                if (noticias.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.newspaper_outlined,
                          color: Colors.grey,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No hay noticias disponibles',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _refrescarForzado,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Recargar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C63FF),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Lista con pull to refresh
                return RefreshIndicator(
                  color: const Color(0xFF6C63FF),
                  onRefresh: () async => _refrescarForzado(),
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