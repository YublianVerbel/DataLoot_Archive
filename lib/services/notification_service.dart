import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Inicializa las notificaciones
  static Future<void> init() async {
    // Pide permiso al usuario
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Maneja notificaciones cuando la app está abierta
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Notificación recibida: ${message.notification?.title}');
    });
  }

  // Suscribe al topic de una revista
  static Future<void> suscribirseA(String fuente) async {
    final topic = fuente.toLowerCase().replaceAll(' ', '_');
    await _messaging.subscribeToTopic(topic);
    print('Suscrito a: $topic');
  }

  // Desuscribe del topic de una revista
  static Future<void> desuscribirseDe(String fuente) async {
    final topic = fuente.toLowerCase().replaceAll(' ', '_');
    await _messaging.unsubscribeFromTopic(topic);
    print('Desuscrito de: $topic');
  }

  // Verifica si está suscrito (guardado en SharedPreferences)
  static String topicDeFuente(String fuente) {
    return fuente.toLowerCase().replaceAll(' ', '_');
  }
}