package com.serenegiant.skyway_flutter_test

import android.os.Bundle
import android.os.PersistableBundle
import android.util.Log
import android.widget.Toast
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.skyway.Peer.*
import java.util.*
import kotlin.collections.HashMap

/**
 * プラグインを作る代わりにFlutterActivityを拡張して
 * プラットフォーム側の処理を実装する
 *
 * skywayのsdkではカメラやマイクのパーミッションの処理を行っていないので
 * 必要なパーミッション(CAMERA, RECORD_AUDIO)を保持しているかを確認し
 * 保持していない場合にはパーミッションを要求しないといけないが、
 * Androidでの通常のパーミッション要求処理は正常に動作しない。
 * このためDart側でpermission_handlerパッケージを使って
 * あらかじめパーミッションの要求＆保持をしていおかないといけない
 */
class MainActivity : FlutterActivity() {
	private var _localViewId: Int = 0
	private var _remoteViewIds = IntArray(0)

	private var peers: MutableMap<String, FlutterSkywayPeer> = HashMap()

	override fun onCreate(savedInstanceState: Bundle?, persistentState: PersistableBundle?) {
		super.onCreate(savedInstanceState, persistentState)
		if (DEBUG) Log.v(TAG, "onCreate:");
	}

	override fun onDestroy() {
		if (DEBUG) Log.v(TAG, "onDestroy:");
		releaseAll()
		super.onDestroy()
	}

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		if (DEBUG) Log.v(TAG, "configureFlutterEngine:");
		flutterEngine
			.platformViewsController
			.registry
			.registerViewFactory(Const.SKYWAY_CANVAS_VIEW,
				CanvasFactory(flutterEngine.dartExecutor.binaryMessenger))
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, Const.METHOD_CHANNEL_NAME)
			.setMethodCallHandler { call, result -> onMethodCall(call, result) }
	}

	private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
		when (call.method) {
		"connect" -> {
			connect(call, result)
		}
		"disconnect" -> {
			disconnect(call, result);
		}
		"startLocalStream" -> {
			startLocalStream(call, result)
		}
		"startRemoteStream" -> {
			startRemoteStream(call, result)
		}
		"listAllPeers" -> {
			listAllPeers(call, result)
		}
		"hangUp" -> {
			hangUp(call, result)
		}
		"call" -> {
			call(call, result)
		}
		"join" -> {
			join(call, result)
		}
		"leave" -> {
			leave(call, result)
		}
		"accept" -> {
			accept(call, result)
		}
		"reject" -> {
			reject(call, result)
		}
		else -> {
			Log.w(TAG, "unknown method call${call}")
		}
		}
		// FIXME Dart側からのsetter/getter呼び出しを実装する
	}

//--------------------------------------------------------------------------------
	/**
	 * 接続中のすべてのピアを開放する
	 */
	private fun releaseAll() {
	if (DEBUG) Log.v(TAG, "releaseAll:")
		val copy : MutableMap<String, FlutterSkywayPeer>
		synchronized(peers) {
			copy = HashMap(peers)
			peers.clear()
		}
		if (copy.isNotEmpty()) {
			for ((_, v) in copy) {
				v.release()
			}
		}
	}

	/**
	 * Skywayとのピア接続を開始
	 * @param call
	 * @param result
	 */
	private fun connect(call: MethodCall, result: MethodChannel.Result) {
		if (DEBUG) Log.v(TAG, "connect:${call}")
		_localViewId = 0
		_remoteViewIds = IntArray(0)
		val local = call.argument<Int>("localViewId")
		if (local != null) {
			_localViewId = local
		}
		val remotes = call.argument<IntArray>("remoteViewIds")
		if (remotes != null) {
			_remoteViewIds = remotes
		}
		val apiKey = call.argument<String>("apiKey")
		var domain = call.argument<String>("domain")
		if (domain == null) {
			domain = "localhost"
		}
		if (DEBUG) Log.v(TAG, "connect:domain=${domain},apiKey=${apiKey}")
		if (apiKey != null) {
			// Initialize Peer
			val option = PeerOption()
			option.key = apiKey
			option.domain = domain
			option.debug = Peer.DebugLevelEnum.ALL_LOGS
			val peer = Peer(this, option)

			// OPEN
			peer.on(Peer.PeerEventEnum.OPEN) { `object` ->
				// Show my ID
				val ownId = `object` as String
				val wrapped = FlutterSkywayPeer(this,
					ownId, peer,
					flutterEngine!!.dartExecutor.binaryMessenger)
				synchronized(peers) {
					peers.put(ownId, wrapped)
				}
				result.success(ownId)
			}

			// ERROR
			peer.on(Peer.PeerEventEnum.ERROR) { `object` ->
				val error = `object` as PeerError
				if (DEBUG) Log.w(TAG, "[On/Error]$error")
				Toast.makeText(applicationContext, "Error on connecting peer(API key would be wrong),$error", Toast.LENGTH_LONG).show()
			}

			// CLOSE
			peer.on(Peer.PeerEventEnum.CLOSE) {
				if (DEBUG) Log.v(TAG, "[On/Close]")
				synchronized(peers) {
					peers.remove(peer.identity())?.release()
				}
			}
		} else {
			result.error("Invalid apiKey", "Invalid apiKey", "Invalid apiKey")
		}
	}

	/**
	 * Skywayとのピア接続を切断
	 * @param call
	 * @param result
	 */
	private fun disconnect(call: MethodCall, result: MethodChannel.Result) {
		if (DEBUG) Log.v(TAG, "disconnect:${call}")
		val peerId = call.argument<String>("peerId")
		if (peerId != null) {
			synchronized(peers) {
				peers.remove<String?, FlutterSkywayPeer>(peerId)?.release()
			}
		}
		result.success("success")
	}

	/**
	 * ローカル映像を取得開始
	 * @param call
	 * @param result
	 */
	private fun startLocalStream(call: MethodCall, result: MethodChannel.Result) {
		if (DEBUG) Log.v(TAG, "startLocalStream:${call}")
		val peerId = call.argument<String>("peerId")
		val localVideoId = call.argument<Int>("localVideoId")
		val peer = getPeer(peerId)
		if (peer != null && (localVideoId != null)) {
			peer.startLocalStream(localVideoId)
			result.success("success")
		} else {
			result.error("Failed to start local stream", "Pls. check permission", "")
		}
	}

	/**
	 * リモート映像の取得開始
	 * @param call
	 * @param result
	 */
	private fun startRemoteStream(call: MethodCall, result: MethodChannel.Result) {
		if (DEBUG) Log.v(TAG, "startRemoteStream:${call}")
		val peerId = call.argument<String>("peerId")
		val remoteVideoId = call.argument<Int>("remoteVideoId")
		val remotePeerId = call.argument<String>("remotePeerId")
		val peer = getPeer(peerId)
		if (peer != null && (remoteVideoId != null) && (remotePeerId != null)) {
			peer.startRemoteStream(remoteVideoId, remotePeerId)
			result.success("success")
		} else {
			result.error("Failed to start local stream", "Pls. check permission", "")
		}
	}

	/**
	 * 同じSkywayのアプリケーションに接続しているピア一覧を取得
	 * (Skyway側の設定で一覧取得が有効になっているときのみ取得可能)
	 * @param call
	 * @param result
	 */
	private fun listAllPeers(call: MethodCall, result: MethodChannel.Result) {
		if (DEBUG) Log.v(TAG, "listAllPeers:${call}")
		val peerId = call.argument<String>("peerId")
		val peer = getPeer(peerId)
		if (peer != null) {
			peer.listAllPeers(object: FlutterSkywayPeer.OnListAllPeersCallback {
				override fun onListAllPeers(list: List<String>) {
					result.success(list)
				}
			})
		} else {
			result.success(arrayOf<String>())
		}
	}

	/**
	 * 通話を終了(ローカル映像の取得とピア接続自体は有効なまま)
	 * @param call
	 * @param result
	 */
	private fun hangUp(call: MethodCall, result: MethodChannel.Result) {
		if (DEBUG) Log.v(TAG, "call:${call}")
		val peerId = call.argument<String>("peerId")
		val peer = getPeer(peerId)
		if (peer != null) {
			peer.hangUp()
			result.success("success")
		} else {
			result.error("Failed to hangUp", "Failed to hangUp", "")
		}
	}

	/**
	 * 指定したリモートピアへp2p接続を開始
	 * @param call
	 * @param result
	 */
	private fun call(call: MethodCall, result: MethodChannel.Result) {
		if (DEBUG) Log.v(TAG, "call:${call}")
		val peerId = call.argument<String>("peerId")
		val remotePeerId = call.argument<String>("remotePeerId")
		val peer = getPeer(peerId)
		if (peer != null && (remotePeerId != null)) {
			peer.startCall(remotePeerId)
			result.success("success")
		} else {
			result.error("Failed to call", "Failed to call", "")
		}
	}

	/**
	 * 指定したSFU/meshのルームへ入室
	 * @param call
	 * @param result
	 */
	private fun join(call: MethodCall, result: MethodChannel.Result) {
		if (DEBUG) Log.v(TAG, "join:${call}")
		val peerId = call.argument<String>("peerId")
		val room = call.argument<String>("room")
		val mode = call.argument<Int>("mode")
		val peer = getPeer(peerId)
		if ((peer != null) && (room != null) && (mode != null)) {
			when (mode) {
			RoomOption.RoomModeEnum.MESH.ordinal -> {
				peer.join(room, RoomOption.RoomModeEnum.MESH)
				result.success("success")
			}
			RoomOption.RoomModeEnum.SFU.ordinal -> {
				peer.join(room, RoomOption.RoomModeEnum.SFU)
				result.success("success")
			}
			else -> {
				result.error("Invalid mode(${mode})", "Invalid mode(${mode})", "")
			}
			}
		} else {
			result.error("Failed to call", "Failed to call", "")
		}
	}

	/**
	 * 指定したSFU/Meshのルームから退室
	 * @param call
	 * @param result
	 */
	private fun leave(call: MethodCall, result: MethodChannel.Result) {
		if (DEBUG) Log.v(TAG, "leave:${call}")
		val peerId = call.argument<String>("peerId")
		val room = call.argument<String>("room")
		val peer = getPeer(peerId)
		if ((peer != null) && (room != null)) {
			peer.leave(room)
			result.success("success")
		} else {
			result.error("Failed to call", "Failed to call", "")
		}
	}

	/**
	 * p2p接続での着呼要求を承認
	 * @param call
	 * @param result
	 */
	private fun accept(call: MethodCall, result: MethodChannel.Result) {
		if (DEBUG) Log.v(TAG, "accept:${call}")
		val peerId = call.argument<String>("peerId")
		val remotePeerId = call.argument<String>("remotePeerId")
		// FIXME 未実装 削除するかも
		result.success("success")
	}

	/**
	 * p2p接続での着呼要求を拒否
	 * @param call
	 * @param result
	 */
	private fun reject(call: MethodCall, result: MethodChannel.Result) {
		if (DEBUG) Log.v(TAG, "reject:${call}")
		val peerId = call.argument<String>("peerId")
		val remotePeerId = call.argument<String>("remotePeerId")
		// FIXME 未実装 削除するかも
		result.success("success")
	}

	/**
	 * 指定したピアidに対応するFlutterSkywayPeerを取得する
	 * @param peerId
	 */
	private fun getPeer(peerId: String?) : FlutterSkywayPeer? {
		synchronized(peers) {
			return peers[peerId]
		}
	}

	companion object {
		private const val DEBUG = true // set false on production
		private val TAG = MainActivity::class.java.simpleName
	}
}
