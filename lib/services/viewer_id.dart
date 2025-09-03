import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class ViewerId {
  static String? _cached;
  static Future<String> get() async {
    if (_cached != null) return _cached!;
    final prefs = await SharedPreferences.getInstance();
    var v = prefs.getString('viewer_id');
    if (v == null) {
      v = const Uuid().v4();
      await prefs.setString('viewer_id', v);
    }
    _cached = v;
    return v!;
  }
}
