package kado;

import haxe.crypto.Base64;
import haxe.ds.IntMap;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.BytesOutput;
import haxe.io.UInt16Array;
import js.Browser;
import js.html.KeyboardEvent;

typedef ReplayInitParams = {
	var recordedKeys:UInt16Array;
	var recordMouseClicks:Bool;
	@:optional var recordInputs:Bool;
	@:optional var recordEvents:Bool;
	// var recordMousePosition:Bool;
}

typedef ReplayEvent = {
	var eventId:String;
	@:optional var payload:String;
	// var customData:String
	// var mousePosition:{ x:Int, y:Int };
}

typedef ReplayInputEvent = {
	var keyCode:Int;
	var isDown:Bool;
}

typedef ReplayFrameRecord = {
	var events:Array<ReplayEvent>;
	var inputs:Array<ReplayInputEvent>;
	// var mouseClicks:Array<{x:Int, y:Int}>;
}

class ReplayManager {
	public static inline var REPLAY_VERSION:Int = 1;
	private static inline var MAGIC_HEADER:String = "KADO";

	private var replayData:Bytes;
	private var currentFrame:Int = 0;
	private var isRecording:Bool = false;
	private var isPlaying:Bool = false;
	private var params:ReplayInitParams;

	private var frameRecords:IntMap<ReplayFrameRecord>;
	private var replayFrameRecords:IntMap<ReplayFrameRecord>;
	private var pendingEvents:Array<ReplayEvent>;
	private var trackedKeys:IntMap<Bool>;
	private var recordedKeyStates:IntMap<Bool>;
	private var shouldRecordInputs:Bool = true;
	private var shouldRecordEvents:Bool = true;

	private var keyboardRegistered:Bool = false;

	public function new(?replayData:String = null) {
		this.replayData = parseReplayString(replayData);
		this.frameRecords = new IntMap();
		this.replayFrameRecords = new IntMap();
		this.pendingEvents = [];
		this.trackedKeys = new IntMap();
		this.recordedKeyStates = new IntMap();
		this.params = defaultParams();

		if (this.replayData != null) {
			try {
				decodeBinaryData(this.replayData);
			} catch (e:Dynamic) {
				trace("Invalid replay data: " + e);
				this.replayData = null;
			}
		}
	}

	public function init(params:ReplayInitParams):Void {
		this.params = normalizeParams(params);
		refreshTrackedKeys();
		this.shouldRecordInputs = this.params.recordInputs;
		this.shouldRecordEvents = this.params.recordEvents;
	}

	public function start():Void {
		if (this.isRecording || this.isPlaying) {
			trace("ReplayManager is already started");
			return;
		}

		pendingEvents = [];
		recordedKeyStates = new IntMap();
		currentFrame = 0;

		if (this.replayData != null) {
			this.isPlaying = true;
			common_haxe_avm1.KeyboardManager.setInputLocked(true);
			common_haxe_avm1.KeyboardManager.clearState();
		} else {
			this.isRecording = true;
			frameRecords = new IntMap();
			common_haxe_avm1.KeyboardManager.setInputLocked(false);

			if (shouldRecordInputs) {
				registerKeyboardEvents();
			}
		}
	}

	public function stop():Void {
		this.isRecording = false;
		this.isPlaying = false;
		common_haxe_avm1.KeyboardManager.setInputLocked(false);

		unregisterKeyboardEvents();
	}

	public function update():Void {
		if (!this.isRecording && !this.isPlaying) {
			return;
		}

		if (this.isPlaying) {
			applyFrame(currentFrame);
		}

		currentFrame++;
	}

	public function recordEvent(eventId:String, ?payload:String, ?frameIndex:Int):Void {
		if (!this.isRecording || !this.shouldRecordEvents || eventId == null || eventId.length == 0) {
			return;
		}

		var frame = frameIndex == null ? currentFrame : frameIndex;
		var record = getOrCreateFrameRecord(frame);
		record.events.push({eventId: eventId, payload: payload});
	}

	public function recordInput(keyCode:Int, isDown:Bool, ?frameIndex:Int):Void {
		if (!this.isRecording || !this.shouldRecordInputs || !shouldTrackKey(keyCode)) {
			return;
		}

		var previous = recordedKeyStates.exists(keyCode) ? recordedKeyStates.get(keyCode) : false;
		if (previous == isDown) {
			return;
		}

		if (isDown) {
			recordedKeyStates.set(keyCode, true);
		} else {
			recordedKeyStates.remove(keyCode);
		}

		var frame = frameIndex == null ? currentFrame : frameIndex;
		var record = getOrCreateFrameRecord(frame);
		record.inputs.push({keyCode: keyCode, isDown: isDown});
	}

	public function consumeEvents():Array<ReplayEvent> {
		if (pendingEvents.length == 0) {
			return [];
		}

		var output = pendingEvents;
		pendingEvents = [];
		return output;
	}

	public function encodeBinaryData():Bytes {
		var output = new BytesOutput();
		output.writeString(MAGIC_HEADER);
		output.writeByte(REPLAY_VERSION);
		writeInitParams(output);
		writeFrameRecords(output);
		return output.getBytes();
	}

	public function encodeReplayString():String {
		if (replayData != null) {
			return null;
		}
		return Base64.encode(encodeBinaryData());
	}

	public function registerKeyboardEvents():Void {
		if (keyboardRegistered) {
			return;
		}

		Browser.window.addEventListener("keydown", onKeyDown);
		Browser.window.addEventListener("keyup", onKeyUp);
		keyboardRegistered = true;
	}

	public function unregisterKeyboardEvents():Void {
		if (!keyboardRegistered) {
			return;
		}

		Browser.window.removeEventListener("keydown", onKeyDown);
		Browser.window.removeEventListener("keyup", onKeyUp);
		keyboardRegistered = false;
	}

	private function onKeyDown(e:KeyboardEvent):Void {
		recordInput(e.keyCode, true);
	}

	private function onKeyUp(e:KeyboardEvent):Void {
		recordInput(e.keyCode, false);
	}

	private function applyFrame(frameIndex:Int):Void {
		var record = replayFrameRecords.get(frameIndex);
		if (record == null) {
			return;
		}

		for (input in record.inputs) {
			if (input.isDown) {
				common_haxe_avm1.KeyboardManager.setKeyDown(input.keyCode);
			} else {
				common_haxe_avm1.KeyboardManager.setKeyUp(input.keyCode);
			}
		}

		for (event in record.events) {
			pendingEvents.push(event);
		}
	}

	private function getOrCreateFrameRecord(frameIndex:Int):ReplayFrameRecord {
		var record = frameRecords.get(frameIndex);
		if (record != null) {
			return record;
		}

		record = {
			events: [],
			inputs: []
		};
		frameRecords.set(frameIndex, record);
		return record;
	}

	private function shouldTrackKey(keyCode:Int):Bool {
		if (trackedKeys.keys().hasNext()) {
			return trackedKeys.exists(keyCode);
		}

		return true;
	}

	private function writeInitParams(output:BytesOutput):Void {
		output.writeByte(params.recordMouseClicks ? 1 : 0);
		output.writeByte(params.recordInputs ? 1 : 0);
		output.writeByte(params.recordEvents ? 1 : 0);

		output.writeUInt16(params.recordedKeys.length);
		for (i in 0...params.recordedKeys.length) {
			output.writeUInt16(params.recordedKeys[i]);
		}
	}

	private function writeFrameRecords(output:BytesOutput):Void {
		var frameIndexes = [for (frameIndex in frameRecords.keys()) frameIndex];
		frameIndexes.sort((a, b) -> a - b);

		output.writeInt32(frameIndexes.length);
		for (frameIndex in frameIndexes) {
			var record = frameRecords.get(frameIndex);
			if (record == null) {
				continue;
			}

			output.writeInt32(frameIndex);
			output.writeUInt16(record.events.length);
			for (event in record.events) {
				writeString(output, event.eventId);
				writeNullableString(output, event.payload);
			}

			output.writeUInt16(record.inputs.length);
			for (input in record.inputs) {
				output.writeUInt16(input.keyCode);
				output.writeByte(input.isDown ? 1 : 0);
			}
		}
	}

	private function decodeBinaryData(data:Bytes):Void {
		var input = new BytesInput(data);
		var magic = input.readString(MAGIC_HEADER.length);
		if (magic != MAGIC_HEADER) {
			throw "Invalid replay data header";
		}

		var version = input.readByte();
		if (version != REPLAY_VERSION) {
			throw "Unsupported replay version " + version;
		}

		readInitParams(input);
		readFrameRecords(input, replayFrameRecords);
	}

	private function readInitParams(input:BytesInput):Void {
		var recordMouseClicks = input.readByte() == 1;
		var recordInputs = input.readByte() == 1;
		var recordEvents = input.readByte() == 1;

		var keyCount = input.readUInt16();
		var keys = new UInt16Array(keyCount);
		for (i in 0...keyCount) {
			keys[i] = input.readUInt16();
		}

		this.params = normalizeParams({
			recordedKeys: keys,
			recordMouseClicks: recordMouseClicks,
			recordInputs: recordInputs,
			recordEvents: recordEvents
		});

		refreshTrackedKeys();
		this.shouldRecordInputs = this.params.recordInputs;
		this.shouldRecordEvents = this.params.recordEvents;
	}

	private function readFrameRecords(input:BytesInput, target:IntMap<ReplayFrameRecord>):Void {
		var frameCount = input.readInt32();

		for (i in 0...frameCount) {
			var frameIndex = input.readInt32();
			var eventCount = input.readUInt16();
			var events = new Array<ReplayEvent>();
			for (j in 0...eventCount) {
				events.push({
					eventId: readString(input),
					payload: readNullableString(input)
				});
			}

			var inputCount = input.readUInt16();
			var inputs = new Array<ReplayInputEvent>();
			for (j in 0...inputCount) {
				inputs.push({
					keyCode: input.readUInt16(),
					isDown: input.readByte() == 1
				});
			}

			target.set(frameIndex, {
				events: events,
				inputs: inputs
			});
		}
	}

	private function writeString(output:BytesOutput, value:String):Void {
		var bytes = Bytes.ofString(value);
		if (bytes.length > 65534) {
			throw "Replay string is too long to encode";
		}
		output.writeUInt16(bytes.length);
		output.write(bytes);
	}

	private function writeNullableString(output:BytesOutput, ?value:String):Void {
		if (value == null) {
			output.writeUInt16(65535);
			return;
		}

		writeString(output, value);
	}

	private function readString(input:BytesInput):String {
		var length = input.readUInt16();
		return input.readString(length);
	}

	private function readNullableString(input:BytesInput):Null<String> {
		var length = input.readUInt16();
		if (length == 65535) {
			return null;
		}
		return input.readString(length);
	}

	private function refreshTrackedKeys():Void {
		trackedKeys = new IntMap();
		for (i in 0...params.recordedKeys.length) {
			trackedKeys.set(params.recordedKeys[i], true);
		}
	}

	private function parseReplayString(?input:String):Bytes {
		if (input == null) {
			return null;
		}

		try {
			return Base64.decode(input);
		} catch (_:Dynamic) {
			return Bytes.ofString(input);
		}
	}

	private function normalizeParams(input:ReplayInitParams):ReplayInitParams {
		if (input == null) {
			return defaultParams();
		}

		return {
			recordedKeys: input.recordedKeys != null ? input.recordedKeys : new UInt16Array(0),
			recordMouseClicks: input.recordMouseClicks,
			recordInputs: input.recordInputs != null ? input.recordInputs : true,
			recordEvents: input.recordEvents != null ? input.recordEvents : true
		};
	}

	private function defaultParams():ReplayInitParams {
		return {
			recordedKeys: new UInt16Array(0),
			recordMouseClicks: false,
			recordInputs: true,
			recordEvents: true
		};
	}
}
