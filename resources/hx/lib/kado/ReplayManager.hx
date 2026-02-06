package kado;

import haxe.Int32;
import haxe.io.UInt16Array;
import haxe.io.Bytes;

typedef ReplayInitParams = {
	var recordedKeys:UInt16Array;
	var recordMouseClicks:Bool;
	// var recordMousePosition:Bool;
}

typedef ReplayEvent = {
	var keysDown:UInt16Array;
	var keysUp:UInt16Array;
	// var mouseClicks:Array<{x:Int, y:Int}>;
	// var customData:String
	// var mousePosition:{ x:Int, y:Int };
}

class ReplayManager {
	private var replayData:Bytes;
	private var currentFrame:Int = 0;
	private var isRecording:Bool = false;
	private var isPlaying:Bool = false;
	private var params:ReplayInitParams;

	private var events:Map<Int32, ReplayEvent>;

	public function new(?replayData:String = null) {
		this.replayData = replayData != null ? Bytes.ofString(replayData) : null;

		// todo: decode replay data and prepare for playback
	}

	public function init(params:ReplayInitParams):Void {
		this.params = params;
	}

	public function start():Void {
		if (this.isRecording || this.isPlaying) {
			trace("ReplayManager is already started");
			return;
		}
		currentFrame = 0;
		if (this.replayData != null) {
			this.isPlaying = true;
		} else {
			this.isRecording = true;
		}
	}

	public function update():Void {
		if (this.isPlaying) {}
	}
}
