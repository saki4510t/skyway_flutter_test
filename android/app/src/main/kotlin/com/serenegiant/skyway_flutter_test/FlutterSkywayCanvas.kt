package com.serenegiant.skyway_flutter_test

import android.content.Context
import android.util.Log
import android.util.SparseArray
import android.view.View
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import io.skyway.Peer.Browser.Canvas
import java.lang.IndexOutOfBoundsException

/**
 * Skywayの映像表示用のCanvasをFlutterのウイジェットとして使えるようにラップ
 */
class FlutterSkywayCanvas(
	context: Context,
	messenger: BinaryMessenger,
	id: Int, args: Any?) : PlatformView, MethodChannel.MethodCallHandler {

	private val mId = id
	private val canvas: Canvas = Canvas(context)

	init {
		if (DEBUG) Log.v(TAG, "ctor:id=$id")
		sViews.append(id, this)
		canvas.mirror = false
		// FIXME レイアウトxmlで指定できないのでデフォルトから変更が必要な属性はここでセットする
		// FIXME 表示されているかの確認ようにとりあえず適当に背景色を付けておく
		canvas.setBackgroundColor(0x3fff0000.toInt())

		// Dart側からのsetter/getter呼び出しのためのメソッドチャネルを生成
		MethodChannel(messenger, Const.SKYWAY_CANVAS_VIEW + "_$id").also {
			it.setMethodCallHandler(this)
		}
	}

	override fun getView(): View {
		if (DEBUG) Log.v(TAG, "getView:")
		return canvas;
	}

	override fun dispose() {
		if (DEBUG) Log.v(TAG, "dispose:")
		sViews.remove(mId)

	}

	fun getCanvas(): Canvas {
		return canvas
	}

	override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
		if (DEBUG) Log.v(TAG, "onMethodCall:${call}");
		// FIXME Dart側からのsetter/getter呼び出しを実装する
	}

//--------------------------------------------------------------------------------
	companion object {
		private const val DEBUG = true // set false on production
		private val TAG = FlutterSkywayCanvas::class.java.simpleName
		private val sViews = SparseArray<FlutterSkywayCanvas>()

		fun findViewById(id: Int?): FlutterSkywayCanvas? {
			if (id != null) {
				return sViews[id]
			} else {
				return null
			}

		}
	}
}

/**
 * FlutterSkywayCanvas生成のためのファクトリークラス
 */
class CanvasFactory(private val messenger: BinaryMessenger)
	: PlatformViewFactory(StandardMessageCodec.INSTANCE) {

	override fun create(context: Context?, viewId: Int, args: Any?): PlatformView
		= FlutterSkywayCanvas(context!!, messenger, viewId, args)
}
