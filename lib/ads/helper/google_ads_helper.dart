import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class AdHelper {
  // ✅ Banner Ad Unit ID
  static String get bannerAdUnitId {
    if (kIsWeb) {
      // Web पर AdMob नहीं चलता
      throw UnsupportedError(
        "AdMob does not support Flutter Web. Use AdSense.",
      );
    } else if (Platform.isAndroid) {
      return 'ca-app-pub-9423986225196759/1776291411'; // Android banner
    } else if (Platform.isIOS) {
      return 'ca-app-pub-9423986225196759/1776291411'; // iOS banner (AdMob से लेना होगा)
    } else {
      throw UnsupportedError("Unsupported platform");
    }
  }

  // ✅ Interstitial Ad Unit ID (🔄 Updated)
  static String get interstitialAdUnitId {
    if (kIsWeb) {
      throw UnsupportedError(
        "AdMob does not support Flutter Web. Use AdSense.",
      );
    } else if (Platform.isAndroid) {
      return 'ca-app-pub-9423986225196759/8066367593'; // ✅ नया Android interstitial ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-9423986225196759/8066367593'; // iOS interstitial (AdMob से लेना होगा)
    } else {
      throw UnsupportedError("Unsupported platform");
    }
  }
}
