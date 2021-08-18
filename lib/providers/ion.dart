import 'package:flutter/foundation.dart';
import 'package:flutter_ion/flutter_ion.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class IonController with ChangeNotifier {
  late SharedPreferences _prefs;
  IonBaseConnector? _connector;
  IonAppBiz? _biz;
  IonSDKSFU? _sfu;
  late String _sid;
  late String _name;
  final String _uid = const Uuid().v4();
  String get sid => _sid;
  String get uid => _uid;
  String get name => _name;
  IonAppBiz? get biz => _biz;
  IonSDKSFU? get sfu => _sfu;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences prefs() {
    return _prefs;
  }

  connect(host) async {
    if (_biz == null || _sfu == null || _connector == null) {
      _connector =
          IonBaseConnector('http://$host:5551', token: 'token123123123');
      _biz = IonAppBiz(_connector!);
      _sfu = IonSDKSFU(_connector!);
      await _biz?.connect();
    }
  }

  join(String sid, String displayName) async {
    _sid = sid;
    _name = displayName;
    _biz?.join(
        sid: _sid, uid: _uid, info: <String, String>{'name': displayName});
  }

  Future<void> close() async {
    if (_connector == null && _biz == null && _sfu == null) {
      return;
    }
    _connector?.close();
    _biz = null;
    _sfu = null;
    _connector = null;
  }

  Future<bool> handleJoin(String server, String sid) async {
    if (server.isEmpty || sid.isEmpty) {
      return false;
    }
    _prefs.setString('server', server);
    _prefs.setString('room', sid);
    connect(server);
    return true;
  }
}
