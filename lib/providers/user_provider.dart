import 'package:flutter/foundation.dart';
import '../services/api_client.dart';
import 'dart:html';

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

  UserProvider() { _restore(); }

  void _restore() {
    try {
      final ls = window.localStorage;
      final t = ls['eshop_token'];
      _token = (t == null || t.isEmpty) ? null : t;
      final uid = ls['eshop_uid'];
      _userId = uid == null ? null : int.tryParse(uid);
      _nickname = ls['eshop_nick'] ?? '';
      _phone = ls['eshop_phone'] ?? '';
      if (_token != null) notifyListeners();
    } catch (_) {}
  }

  void _persist() {
    try {
      final ls = window.localStorage;
      if (_token != null) ls['eshop_token'] = _token!;
      if (_userId != null) ls['eshop_uid'] = '$_userId';
      ls['eshop_nick'] = _nickname;
      ls['eshop_phone'] = _phone;
    } catch (_) {}
  }

  void _clear() {
    try {
      final ls = window.localStorage;
      ls.remove('eshop_token');
      ls.remove('eshop_uid');
      ls.remove('eshop_nick');
      ls.remove('eshop_phone');
    } catch (_) {}
  }

  Future<Map<String, dynamic>> login(String phone, String password) async {
    _loading = true; notifyListeners();
    try {
      final result = await ApiClient().login(phone, password);
      _userId = result['id'];
      _token = result['token'];
      _nickname = result['nickname'] ?? '';
      _phone = phone;
      _persist();
      _loading = false; notifyListeners();
      return {'success': true};
    } catch (e) {
      _loading = false; notifyListeners();
      final msg = e.toString().replaceFirst('Exception: ', '').replaceFirst('Exception: ', '');
      return {'success': false, 'msg': msg};
    }
  }

  Future<Map<String, dynamic>> register(String phone, String password, {String? nickname}) async {
    _loading = true; notifyListeners();
    try {
      final result = await ApiClient().register(phone, password, nickname: nickname);
      _userId = result['id'];
      _token = result['token'];
      _nickname = result['nickname'] ?? nickname ?? '';
      _phone = phone;
      _persist();
      _loading = false; notifyListeners();
      return {'success': true};
    } catch (e) {
      _loading = false; notifyListeners();
      final msg = e.toString().replaceFirst('Exception: ', '').replaceFirst('Exception: ', '');
      return {'success': false, 'msg': msg};
    }
  }

  void logout() {
    _userId = null;
    _token = null;
    _nickname = '';
    _phone = '';
    _clear();
    notifyListeners();
  }
}
