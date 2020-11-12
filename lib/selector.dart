import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:skyway_flutter_test/call_mesh.dart';
import 'package:skyway_flutter_test/call_p2p.dart';
import 'package:skyway_flutter_test/call_sfu.dart';
import 'package:skyway_flutter_test/settings.dart';

const String _PREF_KEY_API_KEY = 'skyway.API_KEY';
const String _PREF_KEY_DOMAIN = 'skyway.DOMAIN';

class SelectorScreen extends StatefulWidget {
  SelectorScreen({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _SelectorScreenState createState() => _SelectorScreenState();
}

class _SelectorScreenState extends State<SelectorScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _domainController = TextEditingController();

  String _apiKey = '';
  String _domain = '';

  var _selectedValue;
  var _usStates = ["Settings"];

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _domainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    void _buttonPressed(int index) {
      print('_buttonPressed:$index');
      switch (index) {
        case 0:
          Navigator.push(context,
            MaterialPageRoute(builder:  (context) => CallP2pScreen(_apiKey, _domain, title: widget.title)),
          );
          break;
        case 1:
          Navigator.push(context,
            MaterialPageRoute(builder:  (context) => CallSfuScreen(_apiKey, _domain, title: widget.title)),
          );
          break;
        case 2:
          Navigator.push(context,
            MaterialPageRoute(builder:  (context) => CallP2pMeshScreen(_apiKey, _domain, title: widget.title)),
          );
          break;
        default:
          break;
      }
    }

    void _onSelected(String item) {
      print('_onSelected:$item');
      setState(() {
        _selectedValue = item;
        switch (item) {
          case 'Settings':
            Navigator.push(context,
              MaterialPageRoute(builder:  (context) => SettingsScreen(title: widget.title)),
            );
          break;
          default:
          break;
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          PopupMenuButton<String>(
            initialValue: _selectedValue,
            onSelected: _onSelected,
            itemBuilder: (BuildContext context) {
              return _usStates.map((String s) {
                return PopupMenuItem(
                  child: Text(s),
                  value: s,
                );
              }).toList();
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _apiKeyController,
                decoration: InputDecoration(
                  labelText: 'API key:',
                  hintText: 'Enter API key of skyway',
                ),
                onSubmitted: _setAPIKey,
              ),
            ),
            Expanded(
              child: TextField(
                controller: _domainController,
                decoration: InputDecoration(
                  labelText: 'Domain:',
                  hintText: 'Enter domain',
                ),
                onSubmitted: _setDomain,
              ),
            ),
            if (_enabled) ...[
              Expanded(
                child: RaisedButton(
                  key: null,
                  onPressed: () => { _buttonPressed(0) },
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'P2p',
                    style: TextStyle(
                      fontSize:32.0,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Roboto'),
                  ),
                ),
              ),
              Expanded(
                child: RaisedButton(
                  key: null,
                  onPressed: () => { _buttonPressed(1) },
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'SFU',
                    style: TextStyle(
                      fontSize:32.0,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Roboto'),
                  ),
                ),
              ),
              Expanded(
                child: RaisedButton(
                  key: null,
                  onPressed: () => { _buttonPressed(2) },
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'P2p Mesh',
                    style: TextStyle(
                      fontSize:32.0,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Roboto'),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool get _enabled {
    return (_apiKey != null) && (_apiKey.length > 0)
      && (_domain != null) && (_domain.length > 0);
  }

  /// SharedPreferencesから前回の設定を読み込む
  void _loadPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String apiKey = prefs.getString(_PREF_KEY_API_KEY) ?? '';
    final String domain = prefs.get(_PREF_KEY_DOMAIN) ?? 'localhost';
    setState(() {
      _apiKey = apiKey;
      _domain = domain;
      _apiKeyController.text = apiKey;
      _domainController.text = domain;
    });
  }

  /// 入力したapiキーを保存する
  void _setAPIKey(final String apiKey) async {
    if ((apiKey != null) && (apiKey.length > 0)) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString(_PREF_KEY_API_KEY, apiKey);
    }
    setState(() {
      _apiKey = apiKey;
    });
  }

  /// 入力したドメイン名を保存する
  void _setDomain(final String domain) async {
    if ((domain != null) && (domain.length > 0)) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString(_PREF_KEY_DOMAIN, domain);
    }
    setState(() {
      _domain = domain;
    });
  }
}