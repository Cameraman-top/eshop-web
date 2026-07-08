import 'package:flutter/foundation.dart';
import '../services/api_client.dart';

class UserProvider extends ChangeNotifier {
  int? _userId;
  String? _token;
  String _nickname = '';
  String _phone = '';
  bool _loading = false;

  int? get userId => _userId;
  String? get token => _token;
  String get nickname => _nickname;
  String get phone => _phone;
  bool get isLoggedIn => _token != null;
  bool get loading => _loading;

  Future<Map<String, dynamic>> login(String phone, String password) async {
    _loading = true; notifyListeners();
    try {
      final api = ApiClient();
      final result = await api.login(phone, password);
      _userId = result['id'];
      _token = result['token'];
      _nickname = result['nickname'] ?? '';
      _phone = phone;
      _loading = false; notifyListeners();
      return {'success': true};
    } catch (e) {
      _loading = false; notifyListeners();
      return {'success': false, 'msg': e.toString()};
    }
  }

  Future<Map<String, dynamic>> register(String phone, String password, {String? nickname}) async {
    _loading = true; notifyListeners();
    try {
      final api = ApiClient();
      final result = await api.register(phone, password, nickname: nickname);
      _userId = result['id'];
      _token = result['token'];
      _nickname = result['nickname'] ?? nickname ?? '';
      _phone = phone;
      _loading = false; notifyListeners();
      return {'success': true};
    } catch (e) {
      _loading = false; notifyListeners();
      return {'success': false, 'msg': e.toString()};
    }
  }

  void logout() {
    _userId = null;
    _token = null;
    _nickname = '';
    _phone = '';
    notifyListeners();
  }
}
