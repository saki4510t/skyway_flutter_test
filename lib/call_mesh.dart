import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skyway_flutter_test/skyway.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'skyway_canvas_view.dart';

const String _PREF_KEY_ROOM = 'skyway.ROOM_MESH';

class RemotePeer {
  bool _hasRemoteStream = false;
}

class CallP2pMeshScreen extends StatefulWidget {
  CallP2pMeshScreen(this.apiKey, this.domain, {Key key, this.title}) : super(key: key);

  final String apiKey;
  final String domain;
  final String title;

  @override
  _CallP2pMeshScreenState createState() => _CallP2pMeshScreenState();
}

class _CallP2pMeshScreenState extends State<CallP2pMeshScreen> {
  final ValueKey _localVideoKey = ValueKey('localVideo');
  final TextEditingController _controller = TextEditingController();

  String _status = '';
  String _roomName = '';
  bool _isConnecting = false;
  bool _hasLocalStream = false;
  bool _isJoined = false;
  SkywayPeer _peer;
  final Map<String, RemotePeer> _peers = {};

  bool get isConnected {
    return _peer != null;
  }

  bool get isTalking {
    return (_peer != null) &&_peers.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CallP2pMeshScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSz = MediaQuery.of(context).size;
    final double w = (screenSz.width - 8) / 2.0;
    final double h = w / 3.0 * 4.0;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SizedBox.expand(
        child: Stack(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(4.0),
              width: screenSz.width,
              height: screenSz.height,
              child: GridView.count(
                scrollDirection: Axis.vertical,
                shrinkWrap: true,
                crossAxisCount: 2,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                // XXX GridViewの項目の高さを変えるにはアスペクト比を指定する
                childAspectRatio: (w / h),
                children: _buildRemoteVideos(w, h),
              ),
            ),
            if (isConnected)
              Align(
                alignment: Alignment.bottomRight,
                child: Container(  // ローカル映像表示用
                  padding: const EdgeInsets.all(4.0),
                  width: w * 0.6,
                  height: h * 0.6,
                  child: _buildLocalVideo(),
                ),
              ),
            Column(
              children: [
                Padding(padding: const EdgeInsets.all(8.0)),
                if (!_isJoined)
                  Container(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        labelText: 'room name',
                      ),
                      onSubmitted: (String value) async {
                        _setRoomName(value);
                      }
                    ),
                  ),
                Padding(padding: const EdgeInsets.all(2.0)),
                Text( // 接続ステータス表示用
                  '$_status',
                  style: TextStyle(fontSize: 16.0),
                  textAlign: TextAlign.center,
                ),
                if (isConnected)
                  Text( // 自分のピアidを表示
                    'Your peer ID: ${_peer.peerId}',
                    style: TextStyle(fontSize: 16.0),
                    textAlign: TextAlign.center,
                  ),
                Padding(padding: const EdgeInsets.all(2.0)),
                if (_isConnecting)
                  Center(
                    child: SizedBox(
                      child: CircularProgressIndicator(),
                      width: 30.0,
                      height: 30.0,
                    )
                  )
                else
                  Center(
                    child: Column(
                      children: [
                        if (!isConnected)
                          FlatButton(
                            child: Text(
                              'Connect',
                              style: TextStyle(
                                  color: Colors.blue, fontSize: 16.0),
                              textAlign: TextAlign.center,
                            ),
                            onPressed: _connect)
                        else ...[
                          if (_isJoined)
                            FlatButton(
                              child: Text(
                                'Leave from [$_roomName]',
                                style: TextStyle(
                                    color: Colors.blue, fontSize: 16.0),
                                textAlign: TextAlign.center,
                              ),
                              onPressed: _hangup)
                          else
                            FlatButton(
                              child: Text(
                                'Enter',
                                style: TextStyle(
                                    color: Colors.blue, fontSize: 16.0),
                                textAlign: TextAlign.center,
                              ),
                              onPressed: (){ _enter(_roomName); }
                            ),
                          FlatButton(
                            child: Text(
                              'Disconnect',
                              style: TextStyle(
                                  color: Colors.blue, fontSize: 16.0),
                              textAlign: TextAlign.center,
                            ),
                            onPressed: _disconnect),
                        ]
                      ]
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// ローカル映像表示用widgetを生成
  Widget _buildLocalVideo() {
    if (Platform.isIOS) {
      return UiKitView(
        key: _localVideoKey,
        viewType: 'flutter_skyway/video_view',
        onPlatformViewCreated: _onLocalViewCreated,
      );
    } else if (Platform.isAndroid) {
      return SkywayCanvasView(
        key: _localVideoKey,
        onViewCreated: _onLocalViewCreated,
      );
    } else {
      throw UnsupportedError("unsupported platform");
    }
  }

  // リモート映像のグリッド表示用widgetを生成
  List<Widget> _buildRemoteVideos(final double w, final double h) {
    final Size sz = MediaQuery.of(context).size;
    if (_peers.isNotEmpty) {
      List<Widget> result = [];
      _peers.forEach((key, value) {
        result.add(
          Container(
            width: w,
            height: h,
            child: Column(
              children: [
                Expanded(
                  child: _createRemoteView(key),
                ),
                Text(
                  '$key',
                  style: TextStyle(fontSize: 12.0),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      });
      return result;
    } else {
      return [];
    }
  }

  /// リモート映像表示用widgetを生成
  Widget _createRemoteView(String remotePeerId) {
    if (Platform.isIOS) {
      return UiKitView(
        key: ValueKey('remoteVideo$remotePeerId'),
        viewType: 'flutter_skyway/video_view',
        onPlatformViewCreated: (id) {
          _onRemoteViewCreated(remotePeerId, id);
        },
      );
    } else if (Platform.isAndroid) {
      return SkywayCanvasView(
        key: ValueKey('remoteVideo$remotePeerId'),
        onViewCreated: (id) {
          _onRemoteViewCreated(remotePeerId, id);
        },
      );
    } else {
      throw UnsupportedError("unsupported platform");
    }
  }
//--------------------------------------------------------------------------------
  /// SharedPreferencesから前回の設定を読み込む
  void _loadPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String room = prefs.getString(_PREF_KEY_ROOM) ?? '';
    setState(() {
      _roomName = room;
      _controller.text = room;
    });
  }

  Future<void> _connect() async {
    print("_connect:");
    if (_isConnecting) {
      return;
    }
    setState(() {
      _isConnecting = true;
      _status = 'Connecting...';
    });

    String status;
    SkywayPeer peer;

    try {
      status = 'Connected';
      peer = await SkywayPeer.connect(widget.apiKey, widget.domain, _onSkywayEvent);
    } on PlatformException catch (e) {
      print(e);
      status = 'Failed to connect.';
    }

    setState(() {
      _isConnecting = false;
      _status = status;
      _peer = peer;
    });
  }

  Future<void> _disconnect() async {
    print("_disconnect:");
    if (_peer != null) {
      await _peer.disconnect();
    }
    setState(() {
      _status = 'Disconnected.';
      _peer = null;
      _hasLocalStream = false;
      _peers.clear();
    });
  }

  Future<void> _setRoomName(String roomName) async {
    print('_setRoomName:$roomName');
    if ((roomName != null) && (roomName.length > 0)) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString(_PREF_KEY_ROOM, roomName);
    }
    setState(() {
      _roomName = roomName;
    });
  }

  Future<void> _enter(String roomName) async {
    if (isConnected && !isTalking && !_isJoined
      && (roomName != null) && (roomName.length > 0)) {
      await _peer.join(roomName, SkywayRoomMode.Mesh);
      setState(() {
        _status = 'Joined to [$_roomName]';
        _isJoined = true;
      });
    }
  }

  Future<void> _hangup() async {
    print("_hangup:");
    if (_peer != null) {
      await _peer.leave(_roomName);
    }
    setState(() {
      _status = 'Connected';
      _peers.clear();
      _isJoined = false;
    });
  }

  Future<void> _onLocalViewCreated(int id) async {
    if (isConnected && !_hasLocalStream) {
      await _peer.startLocalStream(id);
    }
    setState(() {
      _hasLocalStream = true;
    });
    // ルーム名が既にセットされていれば入室する
    _enter(_roomName);
  }

  Future<void> _onRemoteViewCreated(String remotePeerId, int id) async {
    if (isTalking && _peers.containsKey(remotePeerId)) {
      await _peer.startRemoteStream(id, remotePeerId);
    }
    setState(() {
      _peers[remotePeerId]._hasRemoteStream = true;
    });
  }

  /// Skyway関係のイベントハンドラ
  void _onSkywayEvent(SkywayEvent event, Map<dynamic, dynamic> args) {
    switch (event) {
      case SkywayEvent.OnConnect:
        _onConnect(args['peerId']);
        break;
      case SkywayEvent.OnDisconnect:
        _onDisconnect(args['peerId']);
        break;
      case SkywayEvent.OnAddRemoteStream:
        _onAddRemoteStream(args['remotePeerId']);
        break;
      case SkywayEvent.OnRemoveRemoteStream:
        _onRemoveRemoteStream(args['remotePeerId']);
        break;
      case SkywayEvent.OnOpenRoom:
        _onOpenRoom(args['room']);
        break;
      case SkywayEvent.OnCloseRoom:
        _onCloseRoom(args['room']);
        break;
      case SkywayEvent.OnJoin:
        _onJoin(args['remotePeerId']);
        break;
      case SkywayEvent.OnLeave:
        _onLeave(args['remotePeerId']);
        break;
      case SkywayEvent.OnCall:
        // do nothing, never comes for p2p
        break;
    }
  }

  void _onConnect(String peerId) {
    print('_onConnect:peerId=$peerId');
  }

  void _onDisconnect(String peerId) {
    print('_onConnect:peerId=$peerId');
    setState(() {
      _isJoined = false;
    });
  }

  void _onAddRemoteStream(String remotePeerId) {
    print('_onAddRemoteStream:remotePeerId=$remotePeerId');
    setState(() {
      _peers[remotePeerId] = RemotePeer();
    });
  }

  void _onRemoveRemoteStream(String remotePeerId) {
    print('_onRemoveRemoteStream:remotePeerId=$remotePeerId');
    setState(() {
      _peers.remove(remotePeerId);
    });
  }

  void _onOpenRoom(String room) {
    print('_onOpenRoom:room=$room');
    setState(() {
      _isJoined = true;
    });
  }

  void _onCloseRoom(String room) {
    print('_onCloseRoom:room=$room');
    setState(() {
      _isJoined = false;
    });
  }

  void _onJoin(String remotePeerId) {
    print('_onJoin:remotePeerId=$remotePeerId');
  }

  void _onLeave(String remotePeerId) {
    print('_onLeave:remotePeerId=$remotePeerId');
  }
}
