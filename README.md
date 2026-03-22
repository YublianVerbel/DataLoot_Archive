# 🎮 DataLoot Archive

> Agregador de noticias de videojuegos en tiempo real para Android, construido con Flutter y automatizado con N8N.

---

## 📱 ¿Qué es DataLoot Archive?

**DataLoot Archive** es una aplicación móvil desarrollada en Flutter que reúne en un solo lugar las últimas noticias del mundo de los videojuegos, recopiladas automáticamente desde múltiples fuentes especializadas como Eurogamer, Vandal, Gamespot, Kotaku y PCGamer.

El backend está completamente automatizado con **N8N**, que se encarga de leer los feeds RSS de cada revista cada 30 minutos, limpiar y normalizar los datos, y guardarlos en **Firebase Firestore**. La app Flutter escucha esos datos en tiempo real y los muestra al usuario sin necesidad de recargar manualmente.

---

## ✨ Funcionalidades

- 📰 Feed de noticias en tiempo real desde múltiples fuentes
- 🔍 Filtrado por revista (Vandal, Eurogamer, Gamespot, Kotaku, PCGamer)
- 🖼️ Imágenes de portada con caché automático
- 🏷️ Etiquetas de plataforma (PS5, Xbox, PC, Nintendo, General)
- 🔗 Apertura del artículo completo en el navegador
- 🌙 Tema oscuro con estética gamer

---

## 🏗️ Arquitectura

El proyecto está dividido en dos partes: el pipeline de automatización en N8N y la app móvil en Flutter.

```
┌─────────────────────────────────────────────────────┐
│                     N8N (Backend)                   │
│                                                     │
│  Schedule Trigger (cada 30 min)                     │
│        │                                            │
│        ├──► RSS Eurogamer  ──┐                      │
│        ├──► RSS Vandal     ──┤                      │
│        ├──► RSS Gamespot   ──┼──► Merge             │
│        ├──► RSS Kotaku     ──┤       │               │
│        └──► RSS PCGamer    ──┘       │               │
│                                     ▼               │
│                              Code (limpieza y       │
│                              normalización)         │
│                                     │               │
│                                     ▼               │
│                              Google Firestore       │
└─────────────────────────────────────────────────────┘
                                      │
                               tiempo real
                                      │
┌─────────────────────────────────────────────────────┐
│                  Flutter App (Frontend)             │
│                                                     │
│   StreamBuilder ──► Lista de noticias               │
│        │                                            │
│        └──► NoticiaCard ──► url_launcher            │
└─────────────────────────────────────────────────────┘
```

---

## 🔄 Flujo de datos detallado

### 1. Recolección automática con N8N

N8N ejecuta el flujo cada 30 minutos siguiendo estos pasos:

- **Schedule Trigger** dispara el flujo automáticamente
- **RSS Feed Read** lee en paralelo los feeds de las 5 fuentes
- **Merge (Append)** une todos los artículos en una sola lista
- **Code (JavaScript)** normaliza los datos: extrae la imagen del HTML, detecta la plataforma desde las categorías, genera un ID único por URL y limpia el resumen
- **Google Cloud Firestore** guarda cada noticia como documento en la colección `noticias`

### 2. Visualización en tiempo real con Flutter

- Flutter abre un **Stream** hacia la colección `noticias` en Firestore
- El **StreamBuilder** escucha cambios en tiempo real y actualiza la UI automáticamente
- Cada documento de Firestore se convierte en un objeto `Noticia` mediante `Noticia.fromFirestore()`
- El usuario puede filtrar por fuente, lo que modifica la query de Firestore en vivo

---

## 🛠️ Tecnologías utilizadas

| Tecnología | Uso |
|---|---|
| Flutter 3.x | Framework de desarrollo móvil |
| Dart | Lenguaje de programación |
| Firebase Firestore | Base de datos en tiempo real |
| Firebase Core | Inicialización de Firebase |
| N8N | Automatización del pipeline RSS |
| cached_network_image | Carga y caché de imágenes |
| url_launcher | Apertura de artículos en el navegador |

---

## 📁 Estructura del proyecto

```
lib/
├── main.dart                  # Punto de entrada e inicialización Firebase
├── firebase_options.dart      # Configuración generada por FlutterFire CLI
├── models/
│   └── noticia.dart           # Modelo de datos de una noticia
├── screens/
│   └── home_screen.dart       # Pantalla principal con feed y filtros
└── widgets/
    └── noticia_card.dart      # Tarjeta visual de cada noticia
```

---

## 🚀 Cómo correr el proyecto

### Prerequisitos

- Flutter SDK instalado
- Android Studio o VS Code
- Cuenta de Firebase con proyecto creado
- N8N corriendo (local con Docker o en la nube)

### Instalación

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
| Vandal | Español | `vandal.net/rss/` |
| Gamespot | Inglés | `gamespot.com/feeds/news/` |
| Kotaku | Inglés | `kotaku.com/rss` |
| PCGamer | Inglés | `pcgamer.com/rss/` |

---

## 👨‍💻 Autor

Desarrollado como proyecto final de semestre — Ingeniería de Sistemas.
