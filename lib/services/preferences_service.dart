import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _key = 'fuentes_suscritas';

  // Obtiene las fuentes a las que está suscrito
  static Future<List<String>> getFuentesSuscritas() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  // Guarda las fuentes suscritas
  static Future<void> setFuentesSuscritas(List<String> fuentes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, fuentes);
  }

  // Agrega una fuente
  static Future<void> suscribirse(String fuente) async {
    final fuentes = await getFuentesSuscritas();
    if (!fuentes.contains(fuente)) {
      fuentes.add(fuente);
      await setFuentesSuscritas(fuentes);
    }
  }

  // Quita una fuente
  static Future<void> desuscribirse(String fuente) async {
    final fuentes = await getFuentesSuscritas();
    fuentes.remove(fuente);
    await setFuentesSuscritas(fuentes);
  }

  // Verifica si está suscrito
  static Future<bool> estaSuscrito(String fuente) async {
    final fuentes = await getFuentesSuscritas();
    return fuentes.contains(fuente);
  }
}