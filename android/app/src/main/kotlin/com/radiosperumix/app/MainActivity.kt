package com.radiosperumix.app

import com.ryanheise.audioservice.AudioServiceActivity

// audio_service necesita que la actividad principal herede de
// AudioServiceActivity para compartir el motor de Flutter con el servicio
// de reproducción en segundo plano.
class MainActivity : AudioServiceActivity()
