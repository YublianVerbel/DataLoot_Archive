# 🎮 DataLoot Archive

> Agregador de noticias de videojuegos en tiempo real para Android, construido con Flutter y automatizado con N8N.

---

## 📱 ¿Qué es DataLoot Archive?

**DataLoot Archive** es una aplicación móvil desarrollada en Flutter que reúne en un solo lugar las últimas noticias del mundo de los videojuegos, recopiladas automáticamente desde múltiples fuentes especializadas como Eurogamer, Vandal, HobbyConsolas, Gamespot, Kotaku y PCGamer.

El backend está completamente automatizado con **N8N Cloud**, que se encarga de leer los feeds RSS de cada revista cada 30 minutos, limpiar y normalizar los datos, y guardarlos en **Firebase Firestore**. La app Flutter se conecta directamente a un **Webhook de N8N** que actúa como intermediario entre la app y Firestore, devolviendo las noticias en formato JSON. Además, el sistema envía **notificaciones push automáticas** a los usuarios suscritos a cada revista cuando hay noticias nuevas.

---

## ✨ Características

- 📰 Feed de noticias en tiempo real desde múltiples fuentes
- 🔍 Filtrado por revista (Eurogamer, Vandal, HobbyConsolas, Gamespot, Kotaku, PCGamer)
- 🖼️ Imágenes de portada con caché automático
- 🏷️ Etiquetas de plataforma (PS5, Xbox, PC, Nintendo, General)
- 🔗 Apertura del artículo completo en el navegador
- 🔔 Notificaciones push por revista (el usuario elige a cuáles suscribirse)
- ⚡ Caché local de 5 minutos para evitar saturación del servidor
- 🔄 Pull-to-refresh para actualizar manualmente

---

## 🏗️ Arquitectura

El proyecto está dividido en tres partes: el pipeline RSS de N8N, el Webhook API de N8N y la app móvil en Flutter.

```
┌─────────────────────────────────────────────────────────┐
│              FLUJO 1: Recolector RSS (N8N)               │
│                                                         │
│  Schedule Trigger (cada 30 min)                         │
│        │                                                │
│        ├──► RSS Eurogamer    ──┐                        │
│        ├──► RSS HobbyConsolas ──┤                       │
│        ├──► RSS Gamespot     ──┼──► Merge               │
│        ├──► RSS Kotaku       ──┤       │                │
│        └──► RSS PCGamer      ──┘       │                │
│                                        ▼                │
│                               Code (limpieza +          │
│                               normalización +           │
│                               timestamp)                │
│                                        │                │
│                                        ▼                │
│                               Google Firestore          │
│                               (Create or Update)        │
└─────────────────────────────────────────────────────────┘
                                         │
┌─────────────────────────────────────────────────────────┐
│              FLUJO 2: Webhook API (N8N)                  │
│                                                         │
│  GET /webhook/noticias?source=Eurogamer                 │
│        │                                                │
│        ▼                                                │
│  Firestore (Get All)                                    │
│        │                                                │
│        ▼                                                │
│  Code (filtra por source + ordena por timestamp)        │
│        │                                                │
│        ▼                                                │
│  Respond to Webhook (JSON)                              │
└─────────────────────────────────────────────────────────┘
                                         │
                                    HTTP GET
                                         │
┌─────────────────────────────────────────────────────────┐
│                Flutter App (Frontend)                    │
│                                                         │
│   Cache (5 min) ──► HTTP Request ──► FutureBuilder      │
│                                           │             │
│                                    NoticiaCard          │
│                                           │             │
│                                    url_launcher         │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│           FLUJO 3: Notificaciones Push (N8N)             │
│                                                         │
│  Schedule Trigger (cada 30 min)                         │
│        │                                                │
│        ▼                                                │
│  Code (genera JWT con service account)                  │
│        │                                                │
│        ▼                                                │
│  HTTP Request (obtiene Access Token OAuth2)             │
│        │                                                │
│        ▼                                                │
│  HTTP Request (obtiene noticias del Webhook)            │
│        │                                                │
│        ▼                                                │
│  Code (1 noticia mas reciente por fuente)               │
│        │                                                │
│        ▼                                                │
│  Loop Over Items                                        │
│        │                                                │
│        ▼                                                │
│  HTTP Request (FCM API V1 → push notification)          │
└─────────────────────────────────────────────────────────┘
```

---

## 🔄 Flujo de datos detallado

### Flujo 1 — Recolector RSS
N8N ejecuta el flujo cada 30 minutos. Lee en paralelo los RSS de las 5 fuentes, los une con Merge en modo Append, los normaliza con un nodo Code (extrae imagen del HTML, detecta plataforma desde categorias, genera ID unico por URL, convierte fechas a timestamp numerico) y los guarda en Firestore con operacion Upsert para evitar duplicados. Se resolvio un problema real donde algunas fuentes enviaban el campo `guid` y `link` como objetos en vez de strings, solucionado con una funcion `extractString()` que maneja ambos formatos.

### Flujo 2 — Webhook API
Flutter llama directamente al Webhook de N8N con un parametro opcional `?source=Eurogamer`. N8N consulta Firestore, filtra por fuente si se especifica, ordena por timestamp descendente y devuelve las noticias mas recientes en JSON. Flutter implementa un cache local de 5 minutos para evitar saturar Firestore con llamadas repetidas.

### Flujo 3 — Notificaciones Push
Cada 30 minutos N8N genera un JWT firmado con la service account de Firebase, obtiene un Access Token OAuth2 de Google (requerido por la FCM API V1 que reemplazo la Legacy API en 2024), obtiene las noticias del Webhook, toma la noticia mas reciente por fuente y envia una notificacion push al topic correspondiente de FCM. Los usuarios se suscriben o desuscriben a los topics desde la pantalla de notificaciones de la app.

---

## 🛠️ Tecnologias utilizadas

| Tecnologia | Uso |
|---|---|
| Flutter  | Framework de desarrollo movil |
| Dart | Lenguaje de programacion |
| Firebase Firestore | Base de datos en tiempo real |
| Firebase Cloud Messaging (FCM V1) | Notificaciones push |
| N8N Cloud | Automatizacion del pipeline RSS y notificaciones |
| http | Cliente HTTP para consumir el Webhook de N8N |
| cached_network_image | Carga y cache de imagenes |
| url_launcher | Apertura de articulos en el navegador |
| shared_preferences | Persistencia de suscripciones de notificaciones |

---

## 📁 Estructura del proyecto

```
lib/
├── main.dart                        # Punto de entrada e inicializacion Firebase
├── firebase_options.dart            # Configuracion generada por FlutterFire CLI
├── models/
│   └── noticia.dart                 # Modelo de datos de una noticia
├── screens/
│   ├── home_screen.dart             # Pantalla principal con feed, filtros y cache
│   └── notificaciones_screen.dart   # Pantalla de suscripcion a notificaciones
├── widgets/
│   └── noticia_card.dart            # Tarjeta visual de cada noticia
└── services/
    ├── notification_service.dart    # Gestion de FCM topics
    └── preferences_service.dart     # Persistencia de preferencias del usuario
```

---

## 🚀 Como correr el proyecto

### Prerequisitos

- Flutter SDK instalado
- Android Studio o VS Code
- Cuenta de Firebase con proyecto creado
- N8N Cloud con los 3 flujos configurados

### Instalacion

```bash
# 1. Clona el repositorio
git clone https://github.com/tu-usuario/dataloot-archive.git
cd dataloot-archive

# 2. Instala las dependencias
flutter pub get

# 3. Conecta tu proyecto Firebase
dart pub global activate flutterfire_cli
flutterfire configure

# 4. Corre la app
flutter run
```

### Generar APK

```bash
flutter build apk --release
```

El APK se genera en `build/app/outputs/flutter-apk/app-release.apk`.

---

## 📡 Fuentes de noticias

| Revista | Idioma | RSS |
|---|---|---|
| Eurogamer ES | Español | `eurogamer.es/feed` |
| HobbyConsolas | Español | `hobbyconsolas.com/rss` |
| Gamespot | Ingles | `gamespot.com/feeds/news/` |
| Kotaku | Ingles | `kotaku.com/rss` |
| PCGamer | Ingles | `pcgamer.com/rss/` |

---

## 🔔 Sistema de Notificaciones

La app usa **FCM Topics** para las notificaciones push. Cada revista tiene su propio topic:

| Revista | Topic FCM |
|---|---|
| Eurogamer | `eurogamer` |
| HobbyConsolas | `hobbyconsolas` |
| Gamespot | `gamespot` |
| Kotaku | `kotaku` |
| PCGamer | `pcgamer` |

El usuario puede suscribirse o desuscribirse desde la pantalla de notificaciones. N8N envia automaticamente una notificacion con el titular de la noticia mas reciente de cada fuente cada 30 minutos usando la **FCM HTTP V1 API** con autenticacion OAuth2.

---

## 🧩 Problemas resueltos durante el desarrollo

Durante el desarrollo se resolvieron varios problemas tecnicos reales de integracion:

- Algunas fuentes RSS enviaban `guid` y `link` como objetos en vez de strings, solucionado con una funcion `extractString()` que detecta el tipo y extrae el valor correctamente.
- Se implementaron indices compuestos en Firestore para consultas que combinan filtros por `source` con ordenamiento por `timestamp`.
- La migracion de FCM Legacy API a FCM HTTP V1 requirio implementar generacion de JWT y autenticacion OAuth2 desde N8N ya que la API heredada fue eliminada en 2024.
- Se implemento un sistema de cache local en Flutter para evitar saturar Firestore cuando el usuario cambia de pestaña rapidamente.

---

## 👨‍💻 Autor

Desarrollado como proyecto final de semestre — Ingenieria de Sistemas, Septimo Semestre.
Tecnologico Comfenalco — Electiva II: Desarrollo Movil Flutter.
