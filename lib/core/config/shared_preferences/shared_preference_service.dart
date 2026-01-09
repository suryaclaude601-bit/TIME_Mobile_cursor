import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:streaming_dashboard/core/config/log_service.dart';
import 'package:streaming_dashboard/features/views/login/model/login_model.dart';

class SharedPreferenceService {
  static SharedPreferenceService? _instance;
  static SharedPreferences? _preferences;

  //Private Constructor
  SharedPreferenceService._internal();

  //Singleton pattern
  static Future<SharedPreferenceService> getInstance() async {
    _instance ??= SharedPreferenceService._internal();
    _preferences ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  //Keys for storing data
  static const String _keyIsLoggedIn = 'is_logged_in';

  static const String _keyPrivileges = 'privileges';
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserId = 'userId';

  static const String _keyRememberMe = 'remember_me';
  static const String _keyUserName = 'saved_username';
  static const String _keyPassword = 'saved_password';

  // ==================== Login Status ====================
  //Save Login status
  Future<bool> saveLoginStatus(bool isLoggedIn) async {
    return await _preferences!.setBool(_keyIsLoggedIn, isLoggedIn);
  }

  //Get Login status
  bool getLoginStatus() {
    return _preferences!.getBool(_keyIsLoggedIn) ?? false;
  }

  Future<bool> saveUserDataToPreferences(Data userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('accessToken', userData.accessToken ?? '');
      await prefs.setString('refreshToken', userData.refreshToken ?? '');
      await prefs.setString('userId', userData.userId ?? '');
      await prefs.setString('userName', userData.userName ?? '');
      await prefs.setString('email', userData.email ?? '');
      await prefs.setString('firstName', userData.firstName ?? '');
      await prefs.setString('lastName', userData.lastName ?? '');
      await prefs.setBool(_keyIsLoggedIn, true);

      if (userData.privillage != null) {
        await prefs.setString('privileges', jsonEncode(userData.privillage));
      }
      return true;
    } catch (e) {
      LogService.debug('Error saving login data: $e');
      return false;
    }
  }

  // Get privileges
  static Future<List<String>> getPrivileges() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final privilegesJson = prefs.getString(_keyPrivileges);

      if (privilegesJson != null) {
        final List<dynamic> decoded = jsonDecode(privilegesJson);
        return decoded.cast<String>();
      }
      return [];
    } catch (e) {
      LogService.debug('Error getting privileges: $e');
      return [];
    }
  }

  // Check if user has a specific privilege
  static Future<bool> hasPrivilege(String privilege) async {
    final privileges = await getPrivileges();
    return privileges.contains(privilege);
  }

  // Save access token
  Future<bool> saveAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(_keyAccessToken, token);
  }

  // Get access token
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  // Get access token
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAccessToken);
  }

  // Save refresh token
  Future<bool> saveRefreshToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(_keyRefreshToken, token);
  }

  // Get refresh token
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRefreshToken);
  }

  // Save user name
  Future<bool> saveUserName(String token) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(_keyUserName, token);
  }

  // Get user name
  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName);
  }

  // Save password
  Future<bool> savePassword(String token) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(_keyPassword, token);
  }

  // Get password
  Future<String?> getPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPassword);
  }

  // Save remember me
  Future<bool> saveRememberMe(bool token) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setBool(_keyRememberMe, token);
  }

  // Get remember me
  bool getRememberMe() {
    return _preferences!.getBool(_keyRememberMe) ?? false;
  }

  Future<bool> clearAll() async {
    return await _preferences!.clear();
  }

  /// Clear all user data (logout)
  Future<bool> logout() async {
    try {
      await _preferences!.remove(_keyIsLoggedIn);
      await _preferences!.remove(_keyPrivileges);
      await _preferences!.remove(_keyAccessToken);
      await _preferences!.remove(_keyRefreshToken);
      await _preferences!.remove(_keyUserId);

      return true;
    } catch (e) {
      LogService.debug('Error during logout: $e');
      return false;
    }
  }
}
