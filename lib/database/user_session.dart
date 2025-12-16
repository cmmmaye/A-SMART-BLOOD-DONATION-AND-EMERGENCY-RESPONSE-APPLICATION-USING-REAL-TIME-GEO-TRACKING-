import 'package:hive/hive.dart';
import '../common/hive_boxes.dart';
import 'database_helper.dart' as db;

class UserSession {
  static const String _userIdKey = 'current_user_id';

  static Future<void> setCurrentUserId(int? userId) async {
    final configBox = Hive.box(ConfigBox.key);
    if (userId != null) {
      await configBox.put(_userIdKey, userId);
    } else {
      await configBox.delete(_userIdKey);
    }
  }

  static int? getCurrentUserId() {
    final configBox = Hive.box(ConfigBox.key);
    return configBox.get(_userIdKey) as int?;
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final userId = getCurrentUserId();
    if (userId == null) return null;
    return await db.DatabaseHelper.instance.getUserById(userId);
  }

  static Future<void> clearSession() async {
    await setCurrentUserId(null);
  }
}
