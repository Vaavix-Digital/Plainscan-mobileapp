

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class Adhelper {
  static bool get isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  // Official Google AdMob Test Ad Unit IDs
  static const String _androidSampleBannerId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _iosSampleBannerId =
      'ca-app-pub-3940256099942544/2934735716';
  static const String _androidSampleInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _iosSampleInterstitialId =
      'ca-app-pub-3940256099942544/4411468910';

  // Production Ad Unit IDs
  static const String _androidProdBannerId =
      'ca-app-pub-4377728206732134/5203998822';
  static const String _iosProdBannerId = '';
  static const String _androidProdInterstitialId =
      'ca-app-pub-4377728206732134/6207913132';
  static const String _iosProdInterstitialId = '';

  static String get bannerAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) {
      return kDebugMode ? _androidSampleBannerId : _androidProdBannerId;
    } else if (Platform.isIOS) {
      return kDebugMode ? _iosSampleBannerId : _iosProdBannerId;
    } else {
      return '';
    }
  }

  static String get interstitialAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) {
      return kDebugMode
          ? _androidSampleInterstitialId
          : _androidProdInterstitialId;
    } else if (Platform.isIOS) {
      return kDebugMode
          ? _iosSampleInterstitialId
          : _iosProdInterstitialId;
    } else {
      return '';
    }
  }
}