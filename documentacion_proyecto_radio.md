# 📻 Radios Perú Mix — Documentación Técnica del Proyecto

## 1. Visión General del Proyecto
* **Nombre de la Aplicación:** Radios Perú Mix
* **Concepto:** Directorio y reproductor de múltiples emisoras de radio en vivo enfocadas exclusivamente en el Perú (emisoras nacionales, regionales y locales).
* **Plataformas Objetivo:** Móvil Multiplataforma (**Android** y **iOS**).
* **Tecnología Principal:** **Flutter** (Lenguaje Dart).
* **Modelo de Monetización:** **Arquitectura Escalable (AdMob Ready)**. La versión inicial se lanzará libre de publicidad para priorizar la retención de usuarios, pero contará con los contenedores y la lógica lista para activar anuncios de Google AdMob mediante un interruptor en el código.

---

## 2. Arquitectura de Datos (Enfoque Híbrido)
Para garantizar un catálogo completo de emisoras peruanas y facilidad de mantenimiento sin depender de servidores de pago, la aplicación utilizará dos fuentes combinadas:

1. **Catálogo Curado (Archivo JSON en GitHub):**
   * Un archivo `radios_peru.json` alojado en un repositorio propio de GitHub (consumido mediante su enlace *Raw*).
   * **Ventaja:** Permite agregar radios de provincias/distritos, destacar emisoras principales y corregir enlaces caídos al instante sin obligar al usuario a actualizar la app en Play Store o App Store.
2. **Catálogo Automatizado (Radio Browser API):**
   * Consulta directa a la API pública gratuita filtrando por el código de país de Perú (`countrycode=PE`).
   * **Ventaja:** Provee cientos de emisoras peruanas adicionales de forma automática para enriquecer el buscador.

### Ejemplo de Estructura para `radios_peru.json`
```json
[
  {
    "id": "pe_rpp_lima",
    "nombre": "RPP Noticias",
    "frecuencia": "89.7 FM",
    "region": "Lima",
    "genero": "Noticias",
    "url_stream": "https://mdstrm.com/audio/5fab3416b5f9ef165cfab6e9/icecast.audio",
    "url_logo": "https://ejemplo.com/logos/rpp.png",
    "es_destacada": true
  }
]
```

---

## 3. Funcionalidades del Producto (Alcance del MVP)

* **🎵 Reproducción en Segundo Plano:** El audio continúa reproduciéndose al apagar la pantalla o cambiar de aplicación, mostrando controles de *Play/Pausa/Detener* en la barra de notificaciones y pantalla de bloqueo.
* **📡 Metadatos en Vivo (ICY Metadata):** Lectura y visualización en tiempo real del nombre de la canción, artista o programa que se está transmitiendo (cuando la emisora lo provea).
* **🔍 Buscador y Filtros Inteligentes:**
  * Búsqueda rápida por nombre de emisora o frecuencia.
  * Filtros por **Departamento/Región** (Lima, Áncash, Arequipa, Cusco, Piura, La Libertad, etc.).
  * Filtros por **Género** (Noticias, Cumbia, Rock & Pop, Salsa, Folklore, Deportes).
* **❤️ Sistema de Favoritos Local:** Botón de acceso rápido para guardar y listar las emisoras preferidas del usuario directamente en la memoria del dispositivo (sin requerir inicio de sesión).
* **🌙 Temporizador de Apagado (*Sleep Timer*):** Programación de apagado automático (15, 30, 45, 60 minutos) ideal para usuarios que escuchan radio antes de dormir.
* **🎨 Tema Claro y Oscuro:** Interfaz adaptable a las preferencias visuales del usuario y al ahorro de batería en pantallas OLED.
* **📲 Compartir Emisora y App (Viralización y Deep Links):**
  * Opción para compartir el enlace de descarga de **Radios Perú Mix** (Play Store / App Store).
  * Opción para compartir la emisora que se está escuchando en ese momento (ej. vía WhatsApp). Si el receptor tiene la app, se abrirá directamente reproduciendo esa emisora.

---

## 4. Stack Tecnológico y Paquetes de Flutter (`pubspec.yaml`)

| Funcionalidad | Paquete (`pub.dev`) | Propósito en el Proyecto |
| :--- | :--- | :--- |
| **Motor de Audio y Metadatos** | `just_audio` | Reproduce streams (`.mp3`, `.aac`, `.m3u8`) y extrae metadatos ICY en vivo. |
| **Audio en Segundo Plano** | `just_audio_background` / `audio_service` | Mantiene el servicio de audio activo con pantalla apagada y gestiona la notificación nativa. |
| **Peticiones de Red** | `http` | Descarga el archivo `.json` desde GitHub y consulta la API de *Radio Browser*. |
| **Persistencia Local** | `shared_preferences` | Almacena la lista de IDs de radios favoritas y la configuración del Modo Oscuro/Claro. |
| **Gestión de Estado** | `provider` | Conecta el estado del reproductor, el *Sleep Timer* y los filtros con las pantallas en tiempo real. |
| **Compartir y Enlaces Profundos** | `share_plus` + `app_links` | Genera el diálogo nativo para compartir por redes/WhatsApp y captura los enlaces entrantes. |
| **Caché de Imágenes** | `cached_network_image` | Guarda los logos de las radios en caché para ahorrar datos móviles y cargar la lista rápido. |
| **Monetización (Preparada)** | `google_mobile_ads` | *(Opcional en v1.0)* Contenedor preparado con bandera booleana para activar banners de AdMob en el futuro. |

---

## 5. Estructura de Directorios del Proyecto

```text
lib/
├── main.dart                  # Punto de entrada, inicialización de background audio y Providers
├── core/
│   ├── constants.dart         # URLs del JSON en GitHub, endpoints de API, constantes y bandera de AdMob
│   └── theme.dart             # Definición de colores y estilos para Modo Claro y Modo Oscuro
├── models/
│   └── station_model.dart     # Clase Station con métodos fromJson() y toJson()
├── services/
│   ├── radio_api_service.dart # Servicio híbrido: combina GitHub JSON + Radio Browser API
│   ├── audio_handler.dart     # Controlador de just_audio, manejo de errores de stream y Sleep Timer
│   └── storage_service.dart   # Lectura y escritura de Favoritos y preferencias en memoria local
├── providers/
│   └── radio_provider.dart    # Estado global: emisora actual, estado de carga, filtros activos y favoritos
└── ui/
    ├── screens/
    │   ├── home_screen.dart   # Pantalla principal con buscador, chips de filtros y pestaña de Favoritos
    │   └── player_screen.dart # Reproductor a pantalla completa con carátula, metadatos, timer y compartir
    └── widgets/
        ├── station_card.dart  # Tarjeta individual de cada emisora en la lista
        ├── mini_player.dart   # Barra inferior persistente con controles rápidos
        └── ad_space.dart      # Widget contenedor reservado para activar anuncios en futuras versiones
```

---

## 6. Hoja de Ruta de Desarrollo (Roadmap)

### Fase 1: Estructura de Datos y Catálogo Híbrido
- [ ] Crear el archivo base `radios_peru.json` con un grupo inicial de emisoras peruanas probadas.
- [ ] Subir el archivo a un repositorio de GitHub y obtener la URL *Raw*.
- [ ] Programar el modelo `Station` (`station_model.dart`) en Dart.
- [ ] Crear el servicio `RadioApiService` que descargue y unifique las emisoras de GitHub y de *Radio Browser API*.

### Fase 2: Configuración del Proyecto y Motor de Audio
- [ ] Inicializar el proyecto Flutter (`flutter create radios_peru_mix`).
- [ ] Configurar permisos nativos en `AndroidManifest.xml` (Internet, Foreground Service, WakeLock) y en `Info.plist` (iOS Background Audio).
- [ ] Implementar `just_audio` y `just_audio_background`.
- [ ] Probar la reproducción continua con pantalla bloqueada y lectura de metadatos ICY.

### Fase 3: Interfaz de Usuario, Filtros y Favoritos
- [ ] Construir la pantalla principal (`HomeScreen`) con barra de búsqueda y filtros por Región y Género.
- [ ] Diseñar el `MiniPlayer` inferior y la pantalla expandida `PlayerScreen`.
- [ ] Implementar el guardado de Favoritos con `shared_preferences`.
- [ ] Configurar el cambio dinámico entre Modo Claro y Modo Oscuro.

### Fase 4: Funciones Avanzadas y Preparación para Tiendas
- [ ] Programar la lógica del Temporizador de Apagado (*Sleep Timer*).
- [ ] Integrar el botón de compartir emisora/app usando `share_plus`.
- [ ] Crear el widget `AdSpace` con el interruptor de configuración (`enableAds = false`).
- [ ] Configurar ícono de la aplicación, pantalla de carga (*Splash Screen*) y compilar el APK / App Bundle de prueba.