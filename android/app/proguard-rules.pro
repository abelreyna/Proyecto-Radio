# Reglas de R8 propias de la app. El plugin de Flutter carga este archivo
# automáticamente en las compilaciones de release.

# WorkManager (dependencia del SDK de Google Mobile Ads) usa Room 2.2.5, que
# crea su base de datos por reflexión con el constructor vacío de
# WorkDatabase_Impl. La regla de esa versión de Room no conserva constructores
# en el modo completo de R8, y sin esta línea la app se cierra al abrir con
# "Failed to create an instance of androidx.work.impl.WorkDatabase".
-keep class * extends androidx.room.RoomDatabase { <init>(); }
