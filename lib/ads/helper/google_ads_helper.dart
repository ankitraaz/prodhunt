import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class AdHelper {
  // ✅ Banner Ad Unit ID
  static String get bannerAdUnitId {
    if (kIsWeb) {
      // Web पर AdMob support नहीं है (AdSense का use करना होगा)
      throw UnsupportedError(
        "AdMob does not support Flutter Web. Use AdSense.",
      );
    } else if (Platform.isAndroid) {
      return 'ca-app-pub-9423986225196759/3080941320';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-9423986225196759/3080941320';
    } else {
      throw UnsupportedError("Unsupported platform");
    }
  }

  // ✅ Interstitial Ad Unit ID
  static String get interstitialAdUnitId {
    if (kIsWeb) {
      throw UnsupportedError(
        "AdMob does not support Flutter Web. Use AdSense.",
      );
    } else if (Platform.isAndroid) {
      return 'ca-app-pub-9423986225196759/1397158711';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-9423986225196759/1397158711';
    } else {
      throw UnsupportedError("Unsupported platform");
    }
  }
}
