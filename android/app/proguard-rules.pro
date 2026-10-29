# Reglas de R8 propias de la app. El plugin de Flutter carga este archivo
# automáticamente en las compilaciones de release.

# audio_service, just_audio y audio_session no incluyen reglas de R8. Sin estas
# líneas el audio suena, pero el estado de reproducción no llega a Android: no
# aparece la notificación con los controles, el servicio no pasa a primer plano
# y el sistema puede cerrar la app en segundo plano. Probado en un Honor 90 Lite
# (Android 14): con R8 y sin estas reglas la sesión multimedia queda en NONE.
-keep class com.ryanheise.** { *; }
-keep class android.support.v4.media.** { *; }
-keep class androidx.media.** { *; }

# WorkManager (dependencia del SDK de Google Mobile Ads) usa Room 2.2.5, que
# crea su base de datos por reflexión con el constructor vacío de
# WorkDatabase_Impl. La regla de esa versión de Room no conserva constructores
# en el modo completo de R8, y sin esta línea la app se cierra al abrir con
# "Failed to create an instance of androidx.work.impl.WorkDatabase".
# La v1.0 no incluye AdMob, pero la regla se mantiene para cuando se active.
-keep class * extends androidx.room.RoomDatabase { <init>(); }
