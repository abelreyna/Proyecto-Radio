import 'package:flutter/material.dart';

import '../../core/constants.dart';

/// Espacio reservado para un banner de AdMob, anclado bajo el mini
/// reproductor.
///
/// La v1.0 no incluye el SDK de anuncios, así que este widget no ocupa
/// espacio. Para activarlos hay que seguir la sección "Activar anuncios" del
/// README: agregar `google_mobile_ads`, cargar aquí un `BannerAd` y cambiar
/// [AppConstants.enableAds] a `true`.
class AdSpace extends StatelessWidget {
  const AdSpace({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
