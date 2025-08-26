// lib/services/trending_service.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prodhunt/model/trending_model.dart';
import 'firebase_service.dart';

class TrendingService {
  // Today’s trending (by UTC day to match Cloud Function)
  static Stream<TrendingModel?> getTodaysTrending() {
    final utc = DateTime.now().toUtc();
    final id =
        '${utc.year}-${utc.month.toString().padLeft(2, '0')}-${utc.day.toString().padLeft(2, '0')}';

    return FirebaseService.firestore
        .collection('dailyRankings')
        .doc(id)
        .snapshots()
        .map((d) => d.exists ? TrendingModel.fromFirestore(d) : null);
  }

  // Optional: get trending by any date (UTC-normalized)
  static Future<TrendingModel?> getTrendingByDate(DateTime date) async {
    final utc = DateTime.utc(date.year, date.month, date.day);
    final id =
        '${utc.year}-${utc.month.toString().padLeft(2, '0')}-${utc.day.toString().padLeft(2, '0')}';

    final doc = await FirebaseService.firestore
        .collection('dailyRankings')
        .doc(id)
        .get();

    return doc.exists ? TrendingModel.fromFirestore(doc) : null;
  }

  /// Admin-only manual trigger (calls Cloud Function)
  static Future<Map<String, dynamic>?> triggerGenerate({DateTime? date}) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'generateDailyTrendingNow',
      );

      final data = date == null
          ? <String, dynamic>{}
          : {
              'date':
                  '${date.toUtc().year}-${date.toUtc().month.toString().padLeft(2, '0')}-${date.toUtc().day.toString().padLeft(2, '0')}',
            };

      final res = await callable.call(data);
      return (res.data as Map).cast<String, dynamic>();
    } catch (e) {
      // optionally log/notify
      return null;
    }
  }
}
