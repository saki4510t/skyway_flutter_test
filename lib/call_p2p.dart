import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skyway_flutter_test/skyway.dart';

import 'skyway_canvas_view.dart';

class CallP2pScreen extends StatefulWidget {
  CallP2pScreen(this.apiKey, this.domain, {Key key, this.title}) : super(key: key);

  final String apiKey;
  final String domain;
  final String title;

  @override
  _CallP2pScreenState createState() => _CallP2pScreenState();
}

class _CallP2pScreenState extends State<CallP2pScreen> {
  final ValueKey _localVideoKey = ValueKey('localVideo');
  final ValueKey _remoteVideoKey = ValueKey('remoteVideo');

  String _status = '';
  bool _isConnecting = false;
  bool _hasLocalStream = false;
  bool _hasRemoteStream = false;
  SkywayPeer _peer;
  List<String> _peers;
  String _remotePeerId;

  bool get isConnected {
    return _peer != null;
  }

  bool get isTalking {
    return (_peer != null) && (_remotePeerId != null);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(CallP2pScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final Size sz = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SizedBox.expand(
        child: Stack(
          children: <Widget>[
            if (isTalking)
              Container(  // リモート映像表示用
                alignment: Alignment.center,
                padding: const EdgeInsets.all(8.0),
                width: sz.width,
                height: sz.height,
                child: _buildRemoteVideo(),
              ),
            if (isConnected)
              Align(
                alignment: Alignment.bottomRight,
                child: Container(  // ローカル映像表示用
                  padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
                  width: 160.0,
                  height: 120.0,
                  child: _buildLocalVideo(),
                ),
              ),
            Column(
              children: [
                Padding(padding: EdgeInsets.all(4.0)),
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
                Padding(padding: EdgeInsets.all(4.0)),
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
                          if (isTalking)
                            FlatButton(
                              child: Text(
                                'Hangup',
                                style: TextStyle(
                                    color: Colors.blue, fontSize: 16.0),
                                textAlign: TextAlign.center,
                              ),
                              onPressed: _hangup)
                          else
                            FlatButton(
                              child: Text(
                                'Refresh',
                                style:
                                    TextStyle(color: Colors.blue, fontSize: 16.0),
                                textAlign: TextAlign.center,
                              ),
                              onPressed: _fetchAllPeers),
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
                if (isConnected && !isTalking)
                  ListView(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.all(8.0),
                    children: <Widget>[
                    ].where((c) => c != null).toList() +
                      _buildPeers()
                  )
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

  // リモート映像表示用widgetを生成
  Widget _buildRemoteVideo() {
    final Size sz = MediaQuery.of(context).size;
    if (Platform.isIOS) {
      return UiKitView(
        key: _remoteVideoKey,
        viewType: 'flutter_skyway/video_view',
        onPlatformViewCreated: _onRemoteViewCreated,
      );
    } else if (Platform.isAndroid) {
      return SkywayCanvasView(
        key: _remoteVideoKey,
        onViewCreated: _onRemoteViewCreated,
      );
    } else {
      throw UnsupportedError("unsupported platform");
    }
  }

  /// リモート側ピア一覧を表示するためのwidgetを生成
  List<Widget> _buildPeers() {
    print("_buildPeers:");
    return _peers != null
        ? _peers.isNotEmpty
            ? _peers.map((peerId) {
                return Center(
                  child: SizedBox(
                    width: 320.0,
                    child: Card(
                      color: Color.fromARGB(255, 240, 240, 240),
                      margin: EdgeInsets.all(12.0),
                      child: Container(
                        padding: EdgeInsets.fromLTRB(8.0, 20.0, 8.0, 0.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              '$peerId',
                              style: TextStyle(fontSize: 16.0),
                            ),
                            FlatButton(
                              child: Text(
                                'Call',
                                style: TextStyle(
                                  fontSize: 16.0,
                                  color: Colors.blue,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              onPressed: () {
                                _call(peerId);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList()
            : [
                Text(
                  'Other peer does not exist.',
                  textAlign: TextAlign.center,
                )
              ]
        : [];
  }

//--------------------------------------------------------------------------------
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
      status = 'Connected!';
      peer = await SkywayPeer.connect(widget.apiKey, widget.domain, _onSkywayEvent);
    } on PlatformException catch (e) {
      print(e);
      status = 'Failed to connect.';
    }

    setState(() {
      _isConnecting = false;
      _status = status;
      _peer = peer;
      _fetchAllPeers();
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
      _peers = null;
      _hasLocalStream = false;
      _remotePeerId = null;
      _hasRemoteStream = false;
    });
  }

  Future<void> _hangup() async {
    print("_hangup:");
    if (_peer != null) {
      await _peer.hangUp();
    }
    setState(() {
      _remotePeerId = null;
      _hasRemoteStream = false;
    });
  }

  Future<void> _fetchAllPeers() async {
    print("_fetchAllPeers:");
    if (!isConnected) {
      return;
    }

    List<String> peers;
    try {
      peers = await _peer.listAllPeers();
      peers = peers.where((peerId) => peerId != _peer.peerId).toList();
    } on PlatformException catch (e) {
      print(e);
    }

    setState(() {
      _peers = peers;
    });
  }

  void _call(String targetPeerId) {
    print("call to $targetPeerId");
    _peer.call(targetPeerId);
  }

  Future<void> _onLocalViewCreated(int id) async {
    if (isConnected && !_hasLocalStream) {
      await _peer.startLocalStream(id);
    }
    setState(() {
      _hasLocalStream = true;
    });
  }

  Future<void> _onRemoteViewCreated(int id) async {
    if (isTalking && !_hasRemoteStream) {
      await _peer.startRemoteStream(id, _remotePeerId);
    }
    setState(() {
      _hasRemoteStream = true;
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
      case SkywayEvent.OnCall:
        _onCall(args['remotePeerId']);
        break;
      case SkywayEvent.OnAddRemoteStream:
        _onAddRemoteStream(args['remotePeerId']);
        break;
      case SkywayEvent.OnRemoveRemoteStream:
        _onRemoveRemoteStream(args['remotePeerId']);
        break;
      case SkywayEvent.OnOpenRoom:
      case SkywayEvent.OnCloseRoom:
      case SkywayEvent.OnJoin:
      case SkywayEvent.OnLeave:
        // do nothing, never comes for p2p
        break;
    }
  }

  void _onConnect(String peerId) {
    print('_onConnect:peerId=$peerId');
  }

  void _onDisconnect(String peerId) {
    print('_onConnect:peerId=$peerId');
  }

  void _onAddRemoteStream(String remotePeerId) {
    print('_onAddRemoteStream:remotePeerId: $remotePeerId');
    setState(() {
      _remotePeerId = remotePeerId;
    });
  }

  void _onRemoveRemoteStream(String remotePeerId) {
    print('_onRemoveRemoteStream:remotePeerId: $remotePeerId');
    setState(() {
      _remotePeerId = null;
      _hasRemoteStream = false;
    });
  }

  void _onCall(remotePeerId) {
    print('_onCall:remotePeerId: $remotePeerId');
    // showDialog(
    //   context: context,
    //   builder: (BuildContext context) => new AlertDialog(
    //         title: new Text('Received a call from $remotePeerId'),
    //         actions: <Widget>[
    //           new FlatButton(
    //               child: const Text('Reject'),
    //               onPressed: () {
    //                 Navigator.pop(context, 0);
    //               }),
    //           new FlatButton(
    //               child: const Text('Accept'),
    //               onPressed: () {
    //                 Navigator.pop(context, 1);
    //               })
    //         ],
    //       ),
    // ).then<void>((value) {
    //   switch (value) {
    //     case 0:
    //       _peer.reject(remotePeerId);
    //       break;
    //     case 1:
    //       _peer.accept(remotePeerId);
    //       break;
    //     default:
    //   }
    // });
  }
}
