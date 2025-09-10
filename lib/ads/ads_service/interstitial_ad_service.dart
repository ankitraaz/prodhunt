import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:prodhunt/ads/helper/google_ads_helper.dart';

class InterstitialAdService {
  static InterstitialAd? _interstitialAd;

  static void loadAd() {
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          print("Interstitial failed to load: $error");
          _interstitialAd = null;
        },
      ),
    );
  }

  static void showAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialAd = null;
      loadAd();
    } else {
      print("Interstitial not ready yet.");
    }
  }
}
