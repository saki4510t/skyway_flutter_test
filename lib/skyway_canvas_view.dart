import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const String SKYWAY_CANVAS_VIEW = "com.serenegiant.flutter.skyway/SkywayCanvas";

typedef onViewCreatedCallback = void Function(int id);

/// プラットフォーム側のSkywayCanvasViewのラッパー
class SkywayCanvasView extends StatefulWidget {
  final onViewCreatedCallback onViewCreated;

  SkywayCanvasView({
    Key key,
    this.onViewCreated
  }): super(key: key);

  @override
  State<StatefulWidget> createState() => _SkywayCanvasViewState();
}

class _SkywayCanvasViewState extends State<SkywayCanvasView> {
  _SkywayCanvasViewController _controller;

  void _onPlatformViewCreated(int id) {
    print('_onPlatformViewCreated:id=$id');
    _controller = _SkywayCanvasViewController(id);
    if (widget.onViewCreated != null) {
      widget.onViewCreated(id);
    }
  }

  int getId() {
    return _controller != null ? _controller._id : 0;
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      return AndroidView(
        viewType: SKYWAY_CANVAS_VIEW,
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    } else {
      return Text(
        '$defaultTargetPlatform. is not yet supported by this project');
    }
  }
}

class _SkywayCanvasViewController {
  int _id;
  final MethodChannel _channel;

  _SkywayCanvasViewController(
    this._id,
  ) : _channel = MethodChannel(SKYWAY_CANVAS_VIEW + '_$_id');

  // FIXME setter/getterを実装する
}