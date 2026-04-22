import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/preferences_service.dart';

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  final List<String> _fuentes = [
    'Eurogamer', 'HobbyConsolas', 'Gamespot', 'Kotaku', 'PCGamer', 'Vandal'
  ];

  Map<String, bool> _suscripciones = {};
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarSuscripciones();
  }

  Future<void> _cargarSuscripciones() async {
    final Map<String, bool> mapa = {};
    for (final fuente in _fuentes) {
      mapa[fuente] = await PreferencesService.estaSuscrito(fuente);
    }
    setState(() {
      _suscripciones = mapa;
      _cargando = false;
    });
  }

  Future<void> _toggleSuscripcion(String fuente) async {
    final estaSuscrito = _suscripciones[fuente] ?? false;

    if (estaSuscrito) {
      await NotificationService.desuscribirseDe(fuente);
      await PreferencesService.desuscribirse(fuente);
    } else {
      await NotificationService.suscribirseA(fuente);
      await PreferencesService.suscribirse(fuente);
    }

    setState(() {
      _suscripciones[fuente] = !estaSuscrito;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          estaSuscrito
              ? 'Desuscrito de $fuente'
              : 'Suscrito a $fuente ✅',
        ),
        backgroundColor: const Color(0xFF6C63FF),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Notificaciones',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Elige las revistas de las que quieres recibir notificaciones:',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
                ..._fuentes.map((fuente) {
                  final suscrito = _suscripciones[fuente] ?? false;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: suscrito
                            ? const Color(0xFF6C63FF)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: SwitchListTile(
                      title: Text(
                        fuente,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        suscrito
                            ? 'Recibirás notificaciones'
                            : 'Sin notificaciones',
                        style: TextStyle(
                          color: suscrito
                              ? const Color(0xFF6C63FF)
                              : Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      value: suscrito,
                      onChanged: (_) => _toggleSuscripcion(fuente),
                      activeColor: const Color(0xFF6C63FF),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}