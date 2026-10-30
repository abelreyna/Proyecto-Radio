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
- **Espacio para anuncios reservado**: la v1.0 sale sin publicidad y sin el SDK de AdMob (ver [Activar anuncios](#activar-anuncios-admob)).

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

## Publicar en Google Play

- Identificador de la app: `com.radiosperumix.app`. No se puede cambiar una vez publicada.
- La guía paso a paso, la ficha de la tienda y los gráficos están en [play_store/](play_store/GUIA_PUBLICACION.md).
- **Firma:** `tool/crear_clave_subida.ps1` crea la clave de subida en `C:\Users\ADMIN\keys\` y escribe `android/key.properties`. Ninguno de los dos se sube a GitHub. Sin `key.properties`, la versión de release se firma con la clave de depuración.
- **Paquete para Play:**
  ```bash
  flutter build appbundle --release
  ```
  El archivo queda en `build/app/outputs/bundle/release/app-release.aab`.
- **Ícono y pantalla de carga:** `tool/generar_graficos.ps1` dibuja las imágenes. Después, `dart run flutter_launcher_icons` y `dart run flutter_native_splash:create` las aplican a Android e iOS.
- **Capturas e imagen destacada de la ficha:** `tool/generar_promo.ps1` combina las capturas reales de `play_store/capturas_app/` con los textos de `tool/promo_textos.json`.
- **R8:** `android/app/proguard-rules.pro` conserva las clases de los plugins de audio. Sin esas reglas, la radio suena pero no aparece la notificación con los controles y Android puede cerrar la app en segundo plano.
- **Política de privacidad:** `docs/privacidad.html`, publicada con GitHub Pages desde la carpeta `/docs`.

## Pendiente para iOS

- Equipo de firma en Xcode y publicación en App Store.
- Reemplazar `AppConstants.appStoreUrl` por el enlace de App Store cuando la app esté publicada.

## Activar anuncios (AdMob)

1. Agrega el SDK:
   ```bash
   flutter pub add google_mobile_ads
   ```
2. Agrega el ID de aplicación de AdMob en `AndroidManifest.xml` (`<meta-data android:name="com.google.android.gms.ads.APPLICATION_ID" .../>`) y en `Info.plist` (`GADApplicationIdentifier`).
3. En `main.dart`, inicializa con `MobileAds.instance.initialize()`. En `lib/ui/widgets/ad_space.dart`, carga un `BannerAd` y muéstralo con `AdWidget`.
4. Cambia `AppConstants.enableAds` a `true`.
5. Actualiza la política de privacidad y la sección de anuncios y datos en Play Console.
