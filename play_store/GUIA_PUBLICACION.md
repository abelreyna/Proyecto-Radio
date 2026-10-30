# Guía de publicación en Google Play — Radios Perú Mix

Todo lo que hay que subir está en esta carpeta (`play_store/`). Los pasos marcados con 🔒 solo los puedes hacer tú: piden tu cuenta de Google, pagos o aceptar acuerdos.

| Archivo | Para qué sirve |
| --- | --- |
| `app-release.aab` | El paquete de la app que se sube a Play (se genera con `flutter build appbundle`) |
| `icon-512.png` | Ícono de la ficha (512 × 512) |
| `feature-graphic.png` | Imagen destacada (1024 × 500) |
| `screenshots/*.png` | Capturas promocionales de teléfono (1080 × 1920, proporción 9:16 que exige Play) |
| `capturas_app/*.png` | Capturas reales de la app (1080 × 2160) con las que se arman las promocionales |

Las capturas promocionales y la imagen destacada se generan con `tool/generar_promo.ps1`; los títulos están en `tool/promo_textos.json`. Para actualizarlas, reemplaza las capturas de `capturas_app/` y vuelve a ejecutar:

```
powershell -ExecutionPolicy Bypass -File tool\generar_promo.ps1
```

---

## 1. 🔒 Crear la cuenta de desarrollador

1. Entra a <https://play.google.com/console/signup> con la cuenta de Google que será la dueña de la app.
2. Elige **Cuenta personal** (para tu nombre) u **Organización** (necesita número D-U-N-S).
3. Paga la tarifa única de **25 USD** y completa la **verificación de identidad** (documento de identidad y, a veces, verificación del teléfono). Google puede tardar unos días en aprobarla.

> **Importante (cuentas personales nuevas):** antes de publicar en producción, Google exige una **prueba cerrada con al menos 12 testers que se mantengan inscritos durante 14 días seguidos**. Ve juntando a 12 amigos o familiares con Android y una cuenta de Gmail.

## 2. 🔒 Activar la política de privacidad (GitHub Pages)

La política (`docs/privacidad.html`) ya nombra como responsable a **Juan Abel Reyna Gonzales** y al nombre de desarrollador en Google Play, **ABELREYNA**. Si cambias el nombre de desarrollador en Play Console, actualízalo también en la política.

1. En GitHub: **Settings → General → Danger Zone → Change visibility → Public**.
2. En GitHub: **Settings → Pages → Build and deployment → Source: Deploy from a branch → Branch: `main` / carpeta `/docs` → Save**.
3. En unos minutos la política estará en:
   **<https://abelreyna.github.io/Proyecto-Radio/privacidad.html>**

Al hacer público el repositorio, la app también empieza a descargar el catálogo `assets/data/radios_peru.json` desde GitHub, así que puedes agregar o corregir emisoras sin publicar una actualización.

## 3. 🔒 Crear la app en Play Console

**Inicio → Crear app**:

| Campo | Valor |
| --- | --- |
| Nombre de la app | Radios Perú Mix |
| Idioma predeterminado | Español (Latinoamérica) – es-419 |
| App o juego | App |
| Gratis o de pago | Gratis |

Acepta las declaraciones (políticas del programa y leyes de exportación de EE. UU.).

## 4. Ficha de Play Store

**Crecer → Presencia en Play Store → Ficha principal**

**Nombre (máx. 30):**
```
Radios Perú Mix
```

**Descripción breve (máx. 80):**
```
Escucha radios del Perú en vivo: noticias, cumbia, salsa, rock y mucho más.
```

**Descripción completa (máx. 4000):**
```
Radios Perú Mix reúne en una sola app las emisoras del Perú para que las escuches en vivo, estés donde estés.

📻 CIENTOS DE EMISORAS PERUANAS
Radios nacionales, regionales y locales: noticias, cumbia, salsa, rock & pop, folklore, baladas, música urbana y más.

🔍 ENCUENTRA TU RADIO AL TOQUE
Busca por nombre o frecuencia y filtra por departamento (Lima, Arequipa, Cusco, Piura, La Libertad, Áncash y todas las regiones) o por género.

🎵 SIGUE ESCUCHANDO CON LA PANTALLA APAGADA
La radio continúa sonando en segundo plano, con controles de Play, Pausa y Detener en la notificación y en la pantalla de bloqueo.

🎤 QUÉ ESTÁ SONANDO
Si la emisora lo transmite, verás en tiempo real el nombre de la canción, el artista o el programa.

❤️ TUS FAVORITAS A UN TOQUE
Guarda tus emisoras preferidas sin crear cuentas ni iniciar sesión.

🌙 TEMPORIZADOR PARA DORMIR
Programa el apagado automático a los 15, 30, 45 o 60 minutos.

🌗 MODO CLARO Y OSCURO
El modo oscuro usa negro puro para ahorrar batería en pantallas OLED.

📲 COMPARTE
Envía a tus amigos la emisora que estás escuchando o el enlace para descargar la app.

✅ Gratis, sin registro y sin publicidad.

Aviso: Radios Perú Mix es un directorio independiente. Los nombres, logos y transmisiones de cada emisora pertenecen a sus respectivos propietarios; la app no está afiliada a ninguna de ellas. La disponibilidad de cada transmisión depende de la emisora.
```

**Gráficos:**
- Ícono: `icon-512.png`
- Imagen destacada: `feature-graphic.png`
- Capturas de teléfono: todas las de `screenshots/` (mínimo 2, máximo 8)

**Crecer → Presencia en Play Store → Configuración de la tienda:**
- Categoría: **Música y audio**
- Etiquetas: radio, música, noticias
- Correo de contacto: el que quieras mostrar públicamente
- Sitio web (opcional): `https://abelreyna.github.io/Proyecto-Radio/`

## 5. Contenido de la app (Política → Contenido de la app)

| Sección | Qué responder |
| --- | --- |
| **Política de privacidad** | `https://abelreyna.github.io/Proyecto-Radio/privacidad.html` |
| **Anuncios** | **No**, la app no contiene anuncios |
| **Acceso a la app** | **Todas las funciones están disponibles sin restricciones** (no hay inicio de sesión) |
| **Clasificación del contenido** | Categoría «Todos los demás tipos de apps». Responde con sinceridad: la app no tiene violencia, contenido sexual, apuestas ni compras; los usuarios no interactúan entre sí ni comparten su ubicación. Ten en cuenta que reproduce radio en vivo de terceros (puede haber canciones con letras explícitas). |
| **Público objetivo** | 13 a 15, 16 a 17 y 18 o más. **No** marques menores de 13 (activaría el programa de Familias). Ante «¿Podría atraer a niños?», responde **No**. |
| **Seguridad de los datos** | ¿Recopila o comparte datos obligatorios? → **No**. La app no tiene cuentas, analítica ni anuncios, y los favoritos solo se guardan en el teléfono. |
| **App de noticias** | **No** (es un reproductor y directorio de radios) |
| **Apps gubernamentales / Funciones financieras / Salud** | **No** |
| **Permisos de servicio en primer plano** | Marca **Reproducción de contenido multimedia** (ver abajo) |

**Texto para la declaración de servicio en primer plano:**
```
Radios Perú Mix es un reproductor de radio en vivo. Cuando el usuario toca una emisora, la app inicia un servicio en primer plano de tipo mediaPlayback para que el audio siga sonando con la pantalla apagada o mientras usa otras apps. El servicio muestra una notificación con los controles Play, Pausa y Detener, y termina cuando el usuario detiene la radio, cuando vence el temporizador de apagado o cuando cierra la app desde Recientes.
```
**Video de demostración** (Play puede pedirlo). Grábalo tú con la grabadora de pantalla del teléfono para controlar lo que aparece:
1. Primero **borra o silencia tus notificaciones personales** (WhatsApp, etc.) para que no salgan en el video.
2. Inicia la grabación de pantalla, abre Radios Perú Mix y toca una emisora.
3. Pulsa el botón de inicio: la radio sigue sonando.
4. Baja la barra de notificaciones y muestra los controles de la radio. Toca Pausa y luego Play.
5. Detén la grabación (unos 20 segundos bastan).
6. Súbelo a YouTube como **Oculto** (no listado) y pega el enlace en la declaración.

## 6. Firma de la app

- La clave de subida está en `C:\Users\ADMIN\keys\radiosperumix-upload.jks` y su contraseña en `android\key.properties`. **Ninguno de los dos se sube a GitHub.**
- **Haz una copia de seguridad del `.jks` y anota la contraseña** (por ejemplo, en un gestor de contraseñas o en un USB). Sin la clave no podrás subir actualizaciones. Si la pierdes, puedes pedir a Google que la reemplace desde Play Console.
- Al subir el primer `.aab`, acepta **Firma de apps de Play**: Google guarda la clave definitiva y tú firmas las subidas con la clave de subida.

## 7. 🔒 Prueba cerrada (obligatoria en cuentas personales)

1. **Prueba → Prueba cerrada → Crear pista** (o usa «Alpha»).
2. **Testers:** crea una lista de correos con al menos 12 cuentas de Gmail, o usa un Grupo de Google.
3. **Países:** Perú (y los que quieras).
4. **Crear versión** → sube `play_store/app-release.aab` → nombre de la versión `1.0.0 (1)`.
5. **Notas de la versión** (es-419):
   ```
   <es-419>
   Primera versión de Radios Perú Mix: emisoras del Perú en vivo, búsqueda y filtros por región y género, favoritos, temporizador de apagado, modo oscuro y reproducción en segundo plano.
   </es-419>
   ```
6. **Revisar versión → Iniciar el lanzamiento**. Google la revisa (de unas horas a unos días).
7. Cuando esté aprobada, copia el **enlace para unirse a la prueba** y envíalo a tus testers. Cada uno debe aceptar la invitación e instalar la app desde Play.
8. Espera **14 días seguidos** con al menos 12 testers inscritos.

## 8. 🔒 Producción

1. En **Panel → Solicitar acceso a producción**, responde las preguntas sobre la prueba cerrada (cómo la probaron y qué mejoraste).
2. Cuando Google lo apruebe: **Producción → Crear versión** → reutiliza el mismo `.aab` de la prueba cerrada (o sube uno nuevo con versión mayor) → **Iniciar el lanzamiento a producción**.

## Publicar actualizaciones

1. Sube el número de versión en `pubspec.yaml`, por ejemplo `version: 1.0.1+2`. El número después de `+` siempre debe aumentar.
2. Genera el paquete:
   ```
   flutter build appbundle --release
   ```
3. Sube `build/app/outputs/bundle/release/app-release.aab` en Play Console.

## Riesgos a tener en cuenta

- **Marcas de las emisoras:** Google puede retirar la app si una emisora reclama por el uso de su nombre o logo. La descripción ya aclara que la app es un directorio independiente; si alguna emisora lo pide, quítala de `radios_peru.json`.
- **Streams caídos:** las URLs de las emisoras cambian con el tiempo. Revisa de vez en cuando que las del catálogo curado sigan sonando.
