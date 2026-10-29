# 📻 Radios Perú Mix

Directorio y reproductor de emisoras de radio peruanas en vivo (nacionales, regionales y locales) para **Android** e **iOS**, hecho con **Flutter**.

La especificación completa está en [documentacion_proyecto_radio.md](documentacion_proyecto_radio.md).

## Funcionalidades

- **Catálogo híbrido**: el JSON curado [`assets/data/radios_peru.json`](assets/data/radios_peru.json), servido desde GitHub, se combina con cientos de emisoras peruanas de [Radio Browser API](https://www.radio-browser.info/) sin duplicados.
- **Reproducción en segundo plano** con controles de Play/Pausa/Detener en la notificación y en la pantalla de bloqueo.
- **Metadatos en vivo (ICY)**: canción o programa en curso, en la app y en la notificación.
- **Buscador y filtros** por nombre, frecuencia, departamento/región y género.
- **Favoritos** guardados en el dispositivo, sin inicio de sesión.
- **Temporizador de apagado** de 15, 30, 45 o 60 minutos.
- **Tema claro, oscuro o según el sistema**. El modo oscuro usa negro puro para ahorrar batería en pantallas OLED.
- **Compartir** la app o la emisora actual. El enlace `radiosperumix://station/<id>` abre la app reproduciendo esa emisora.
- **AdMob preparado** y desactivado en la v1.0 (`AppConstants.enableAds = false`).

## Requisitos

- Flutter 3.47 o superior (Dart 3.13)
- Android Studio con Android SDK para compilar en Android
- Xcode en macOS para compilar en iOS

## Cómo ejecutarlo

```bash
flutter pub get
flutter run
```

Pruebas y análisis estático:

```bash
flutter analyze
flutter test
```

## Estructura

```text
lib/
├── main.dart                     # Inicializa audio en segundo plano, AdMob, Provider y deep links
├── core/
│   ├── constants.dart            # URLs, servidores de Radio Browser, bandera de AdMob, timers
│   ├── theme.dart                # Modo Claro y Modo Oscuro
│   ├── text_utils.dart           # Normalización de texto (búsqueda sin tildes)
│   └── station_classifier.dart   # Deduce región, género y frecuencia de Radio Browser
├── models/
│   └── station_model.dart        # Clase Station con fromJson()/toJson()
├── services/
│   ├── radio_api_service.dart    # Servicio híbrido GitHub JSON + Radio Browser API
│   ├── audio_handler.dart        # just_audio + audio_service, errores de stream y Sleep Timer
│   ├── storage_service.dart      # Favoritos, tema y caché del catálogo
│   ├── deep_link_service.dart    # Enlaces radiosperumix://station/<id>
│   └── share_service.dart        # Textos y diálogo nativo para compartir
├── providers/
│   └── radio_provider.dart       # Estado global
└── ui/
    ├── screens/                  # HomeScreen y PlayerScreen
    └── widgets/                  # StationCard, MiniPlayer, AdSpace, StationLogo
```

## Catálogo curado

Para agregar, destacar o corregir emisoras, edita [`assets/data/radios_peru.json`](assets/data/radios_peru.json) y súbelo a `main`. La app lo descarga desde:

```
https://raw.githubusercontent.com/abelreyna/Proyecto-Radio/main/assets/data/radios_peru.json
```

> **Importante:** el enlace *Raw* solo funciona si el repositorio es **público**. Mientras sea privado, la app usa la copia del JSON empaquetada en la versión instalada.

Campos de cada emisora: `id` (único), `nombre`, `frecuencia`, `region` (departamento), `genero` (Noticias, Deportes, Cumbia, Salsa, Rock & Pop, Folklore, Baladas, Urbano o Variado), `url_stream`, `url_logo` y `es_destacada`.

## Antes de publicar en las tiendas

- [ ] Ícono de la aplicación y pantalla de carga (*splash screen*).
- [ ] Firma de *release* para Android (`android/app/build.gradle.kts`) y equipo de firma en Xcode.
- [ ] `AppConstants.appStoreUrl` con el enlace de App Store una vez publicada en iOS.
- [ ] Para activar anuncios: crear la cuenta de AdMob, reemplazar los IDs **de prueba** en `lib/core/constants.dart`, `AndroidManifest.xml` e `Info.plist`, y cambiar `enableAds` a `true`.
- [ ] La app incluye el SDK de Google Mobile Ads, que agrega el permiso de ID de publicidad. En Play Console declara su uso, o quita el paquete `google_mobile_ads` si la v1.0 sale sin anuncios.
