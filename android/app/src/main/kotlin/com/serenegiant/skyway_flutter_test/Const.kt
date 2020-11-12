package com.serenegiant.skyway_flutter_test

internal object Const {
	/**
	 * MainActivityで実装するメソッドチャネル名
	 */
	const val METHOD_CHANNEL_NAME = "com.serenegiant.flutter.skyway/method"

	/**
	 * MainActivityで実装するメソッドチャネル名
	 */
	const val EVENT_CHANNEL_NAME = "com.serenegiant.flutter.skyway/event"

	/**
	 * 各ピア接続毎にFlutterSkywayPeerで実装するメソッドチャネルの～ベス名(実際には_$peerIdでポストフィックス)
	 */
	const val PEER_EVENT_CHANNEL_NAME = "com.serenegiant.flutter.skyway/event"

	/**
	 * FlutterSkywayCanvasクラスの登録名
	 * "_${id}"をポストフィックスとして付加したものをsetter/getter用メソッドチャネル名として使用する
	 */
	const val SKYWAY_CANVAS_VIEW = "com.serenegiant.flutter.skyway/SkywayCanvas"

	enum class SkywayEvent {
		/**
		 * ピア接続した
		 */
		OnConnect,
		/**
		 * ピア接続が切断された
		 */
		OnDisconnect,
		/**
		 * p2pで着呼した
 		 */
		OnCall,
		/**
		 * リモート映像のMediaStreamが追加された
		 */
		OnAddRemoteStream,
		/**
		 * リモート映像のMediaStreamが削除された
		 */
		OnRemoveRemoteStream,
		/**
		 * SFUまたはMeshルームをオープンした(自分が入室した)
		 */
		OnOpenRoom,
		/**
		 * SFUまたはMeshルームをオープンした(自分が退室した)
		 */
		OnCloseRoom,
		/**
		 * SFU/Mesh接続で誰かががルームに入室した
		 */
		OnJoin,
		/**
		 * SFU/Mesh接続で誰かががルームから退室した
		 */
		OnLeave,
		/**
		 * FlutterSkywayPeerオブジェクトが破棄された
		 */
		OnRelease,
		/**
		 * なにかのエラーが発生した
		 */
		OnError,
	}
}