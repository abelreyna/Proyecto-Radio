import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/constants.dart';

/// Contenedor reservado para un banner de AdMob.
///
/// Mientras [AppConstants.enableAds] sea `false` no ocupa espacio ni carga
/// nada. Al activarlo, carga un banner y solo lo muestra si llegó a cargarse.
class AdSpace extends StatefulWidget {
  const AdSpace({super.key});

  @override
  State<AdSpace> createState() => _AdSpaceState();
}

class _AdSpaceState extends State<AdSpace> {
  BannerAd? _banner;
  bool _loaded = false;

  static String get _adUnitId => defaultTargetPlatform == TargetPlatform.iOS
      ? AppConstants.iosBannerAdUnitId
      : AppConstants.androidBannerAdUnitId;

  @override
  void initState() {
    super.initState();
    if (!AppConstants.enableAds) return;
    _banner = BannerAd(
      adUnitId: _adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _banner = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banner = _banner;
    if (!AppConstants.enableAds || banner == null || !_loaded) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: banner.size.width.toDouble(),
      height: banner.size.height.toDouble(),
      child: AdWidget(ad: banner),
    );
  }
}
