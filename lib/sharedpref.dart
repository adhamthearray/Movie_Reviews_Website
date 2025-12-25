import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefs {
  static late SharedPreferences _prefs;

  // Call this ONCE before using (like in main())
  static Future init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Save string
  static Future setUsername(String username) async {
    await _prefs.setString('username', username);
  }

  // Get string
  static String getUsername() {
    return _prefs.getString('username') ?? '';
  }


  // Remove string
  static Future removeUsername() async {
    await _prefs.remove('username');
  }
  static Future setLoggedIn(bool value) async {
    await _prefs.setBool('isLoggedIn', value);
  }

// Get login state (default = false if not set)
  static bool isLoggedIn() {
    return _prefs.getBool('isLoggedIn') ?? false;
  }
}
