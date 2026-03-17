package kado;

import haxe.crypto.Base64;
import haxe.ds.IntMap;
import haxe.Serializer;
import haxe.Unserializer;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.BytesOutput;
import haxe.io.UInt16Array;
import js.lib.Uint8Array;
import js.Browser;
import js.html.KeyboardEvent;

typedef ReplayInitParams = {
	var recordedKeys:UInt16Array;
	@:optional var recordInputs:Bool;
	@:optional var recordEvents:Bool;
	// var recordMousePosition:Bool;
}

typedef ReplayEvent = Dynamic;

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
	private static inline var FLAG_INPUTS:Int = 1;
	private static inline var FLAG_EVENTS:Int = 2;
	private static inline var EVENT_ENCODING_PACKED_GRID:Int = 0;
	private static inline var EVENT_ENCODING_SERIALIZED:Int = 1;

	private var replayData:Bytes;
	private var currentFrame:Int = 0;
	private var isRecording:Bool = false;
	private var isPlaying:Bool = false;
	private var params:ReplayInitParams;

	private var frameRecords:IntMap<ReplayFrameRecord>;
	private var replayFrameRecords:IntMap<ReplayFrameRecord>;
	private var pendingEvents:Array<ReplayEvent>;
	private var frameEvents:Array<ReplayEvent>;
	private var trackedKeys:IntMap<Bool>;
	private var recordedKeyStates:IntMap<Bool>;
	private var shouldRecordInputs:Bool = true;
	private var shouldRecordEvents:Bool = true;
	private var useFramePolledInputs:Bool = false;

	private var keyboardRegistered:Bool = false;

	public function new(?replayData:String = null) {
		this.replayData = parseReplayString(replayData);
		this.frameRecords = new IntMap();
		this.replayFrameRecords = new IntMap();
		this.pendingEvents = [];
		this.frameEvents = [];
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
		this.useFramePolledInputs = this.shouldRecordInputs && this.params.recordedKeys.length > 0;
	}

	public function start():Void {
		if (this.isRecording || this.isPlaying) {
			trace("ReplayManager is already started");
			return;
		}

		pendingEvents = [];
		frameEvents = [];
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

			if (shouldRecordInputs && !useFramePolledInputs) {
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

	public inline function isPlayingReplay():Bool {
		return this.isPlaying;
	}

	public inline function isRecordingReplay():Bool {
		return this.isRecording;
	}

	public function beginFrame():Void {
		if (!this.isRecording && !this.isPlaying) {
			return;
		}

		var appliedKeyboardOps = common_haxe_avm1.KeyboardManager.beginFrame();
		var appliedMouseOps = common_haxe_avm1.MouseManager.beginFrame();
		frameEvents = [];
		var recordedInputCount = 0;
		var recordedEventCount = 0;
		var replayInputCount = 0;
		var replayEventCount = 0;

		if (this.isRecording && this.shouldRecordInputs && this.useFramePolledInputs) {
			recordedInputCount = captureFrameInputs();
		}

		if (this.isRecording && this.shouldRecordEvents && pendingEvents.length > 0) {
			var record = getOrCreateFrameRecord(currentFrame);
			recordedEventCount = pendingEvents.length;
			for (event in pendingEvents) {
				record.events.push(event);
			}
			pendingEvents = [];
		}

		if (this.isPlaying) {
			var replayRecord = replayFrameRecords.get(currentFrame);
			if (replayRecord != null) {
				replayInputCount = replayRecord.inputs.length;
				replayEventCount = replayRecord.events.length;
			}
			applyFrame(currentFrame);
		}
	}

	public function endFrame():Void {
		if (!this.isRecording && !this.isPlaying) {
			return;
		}
		currentFrame++;
	}

	// public inline function update():Void {
	// 	beginFrame();
	// 	endFrame();
	// }

	public function recordEvent(event:ReplayEvent, ?frameIndex:Int):Void {
		if (!this.isRecording || !this.shouldRecordEvents || event == null) {
			return;
		}

		if (frameIndex == null) {
			pendingEvents.push(event);
			return;
		}

		var frame = Std.int(frameIndex);
		var record = getOrCreateFrameRecord(frame);
		record.events.push(event);
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
		if (frameEvents.length == 0) {
			return [];
		}

		var output = frameEvents;
		frameEvents = [];
		return output;
	}

	public function encodeBinaryData():Bytes {
		var output = new BytesOutput();
		output.writeString(MAGIC_HEADER);
		output.writeByte(REPLAY_VERSION);

		var flags = 0;
		if (params.recordInputs)
			flags |= FLAG_INPUTS;
		if (params.recordEvents)
			flags |= FLAG_EVENTS;
		output.writeByte(flags);

		writeInitParams(output, flags);
		if ((flags & FLAG_INPUTS) != 0) {
			writeInputRecords(output);
		}
		if ((flags & FLAG_EVENTS) != 0) {
			writeEventRecords(output);
		}
		return output.getBytes();
	}

	public function encodeReplayString():String {
		if (replayData != null) {
			return null;
		}
		var compressed = externs.Pako.deflate(bytesToUint8Array(encodeBinaryData()));
		return Base64.encode(uint8ArrayToBytes(compressed));
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
			frameEvents.push(event);
		}
	}

	private function captureFrameInputs():Int {
		var count = 0;
		for (keyCode in trackedKeys.keys()) {
			var isDown = common_haxe_avm1.KeyboardManager.isDown(keyCode);
			var previous = recordedKeyStates.exists(keyCode) ? recordedKeyStates.get(keyCode) : false;
			if (previous == isDown) {
				continue;
			}

			recordInput(keyCode, isDown, currentFrame);
			count++;
		}
		return count;
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

	private function writeInitParams(output:BytesOutput, flags:Int):Void {
		if ((flags & FLAG_INPUTS) == 0) {
			return;
		}

		writeVarUInt(output, params.recordedKeys.length);
		for (i in 0...params.recordedKeys.length) {
			writeVarUInt(output, params.recordedKeys[i]);
		}
	}

	private function writeInputRecords(output:BytesOutput):Void {
		var frameIndexes = [for (frameIndex in frameRecords.keys()) frameIndex];
		frameIndexes.sort((a, b) -> a - b);
		frameIndexes = frameIndexes.filter((frameIndex) -> {
			var record = frameRecords.get(frameIndex);
			return record != null && record.inputs.length > 0;
		});

		writeVarUInt(output, frameIndexes.length);
		var previousFrame = 0;
		for (frameIndex in frameIndexes) {
			var record = frameRecords.get(frameIndex);
			if (record == null || record.inputs.length == 0) {
				continue;
			}

			writeVarUInt(output, frameIndex - previousFrame);
			previousFrame = frameIndex;

			writeVarUInt(output, record.inputs.length);
			for (input in record.inputs) {
				var packed = (input.keyCode << 1) | (input.isDown ? 1 : 0);
				writeVarUInt(output, packed);
			}
		}
	}

	private function writeEventRecords(output:BytesOutput):Void {
		var frameIndexes = [for (frameIndex in frameRecords.keys()) frameIndex];
		frameIndexes.sort((a, b) -> a - b);
		frameIndexes = frameIndexes.filter((frameIndex) -> {
			var record = frameRecords.get(frameIndex);
			return record != null && record.events.length > 0;
		});

		writeVarUInt(output, frameIndexes.length);
		var previousFrame = 0;
		for (frameIndex in frameIndexes) {
			var record = frameRecords.get(frameIndex);
			if (record == null || record.events.length == 0) {
				continue;
			}

			writeVarUInt(output, frameIndex - previousFrame);
			previousFrame = frameIndex;

			writeVarUInt(output, record.events.length);
			for (event in record.events) {
				writeEvent(output, event);
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
		var flags = input.readByte();

		readInitParams(input, flags);
		if ((flags & FLAG_INPUTS) != 0) {
			readInputRecords(input, replayFrameRecords);
		}
		if ((flags & FLAG_EVENTS) != 0) {
			readEventRecords(input, replayFrameRecords);
		}
	}

	private function readInitParams(input:BytesInput, flags:Int):Void {
		var recordInputs = (flags & FLAG_INPUTS) != 0;
		var recordEvents = (flags & FLAG_EVENTS) != 0;

		var keyCount = recordInputs ? readVarUInt(input) : 0;
		var keys = new UInt16Array(keyCount);
		for (i in 0...keyCount) {
			keys[i] = readVarUInt(input);
		}

		this.params = normalizeParams({
			recordedKeys: keys,
			recordInputs: recordInputs,
			recordEvents: recordEvents
		});

		refreshTrackedKeys();
		this.shouldRecordInputs = this.params.recordInputs;
		this.shouldRecordEvents = this.params.recordEvents;
	}

	private function readInputRecords(input:BytesInput, target:IntMap<ReplayFrameRecord>):Void {
		var frameCount = readVarUInt(input);
		var frameIndex = 0;

		for (i in 0...frameCount) {
			frameIndex += readVarUInt(input);
			var inputCount = readVarUInt(input);
			var record = getOrCreateFrameRecordFromMap(target, frameIndex);
			for (j in 0...inputCount) {
				var packed = readVarUInt(input);
				record.inputs.push({
					keyCode: packed >> 1,
					isDown: (packed & 1) == 1
				});
			}
		}
	}

	private function readEventRecords(input:BytesInput, target:IntMap<ReplayFrameRecord>):Void {
		var frameCount = readVarUInt(input);
		var frameIndex = 0;

		for (i in 0...frameCount) {
			frameIndex += readVarUInt(input);
			var eventCount = readVarUInt(input);
			var record = getOrCreateFrameRecordFromMap(target, frameIndex);
			for (j in 0...eventCount) {
				record.events.push(readEvent(input));
			}
		}
		#if debug
		trace('Decoded replay data: ' + frameCount + ' frames');
		trace(target);
		#end
	}

	private function writeEvent(output:BytesOutput, event:ReplayEvent):Void {
		var k = intFieldOrNull(event, "k");
		var x = intFieldOrNull(event, "x");
		var y = intFieldOrNull(event, "y");
		var canPack = k != null && x != null && y != null && k >= 0 && k < 4 && x >= 0 && x < 8 && y >= 0 && y < 8;

		if (canPack) {
			output.writeByte(EVENT_ENCODING_PACKED_GRID);
			output.writeByte((k << 6) | (x << 3) | y);
			return;
		}

		output.writeByte(EVENT_ENCODING_SERIALIZED);
		writeVarString(output, Serializer.run(event));
	}

	private function readEvent(input:BytesInput):ReplayEvent {
		var encoding = input.readByte();
		switch (encoding) {
			case EVENT_ENCODING_PACKED_GRID:
				var packed = input.readByte();
				return {
					k: (packed >> 6) & 0x3,
					x: (packed >> 3) & 0x7,
					y: packed & 0x7
				};
			case EVENT_ENCODING_SERIALIZED:
				return Unserializer.run(readVarString(input));
			default:
				throw "Unsupported event encoding " + encoding;
		}
	}

	private function getOrCreateFrameRecordFromMap(target:IntMap<ReplayFrameRecord>, frameIndex:Int):ReplayFrameRecord {
		var record = target.get(frameIndex);
		if (record != null) {
			return record;
		}

		record = {
			events: [],
			inputs: []
		};
		target.set(frameIndex, record);
		return record;
	}

	private function writeVarString(output:BytesOutput, value:String):Void {
		var bytes = Bytes.ofString(value);
		writeVarUInt(output, bytes.length);
		output.write(bytes);
	}

	private function readVarString(input:BytesInput):String {
		var length = readVarUInt(input);
		return input.readString(length);
	}

	private function writeVarUInt(output:BytesOutput, value:Int):Void {
		if (value < 0) {
			throw "Replay varint cannot encode negative value";
		}

		var n = value;
		while (n >= 0x80) {
			output.writeByte((n & 0x7F) | 0x80);
			n = n >>> 7;
		}
		output.writeByte(n);
	}

	private function readVarUInt(input:BytesInput):Int {
		var result = 0;
		var shift = 0;

		while (true) {
			var b = input.readByte();
			result |= (b & 0x7F) << shift;
			if ((b & 0x80) == 0) {
				return result;
			}

			shift += 7;
			if (shift > 28) {
				throw "Replay varint is too long";
			}
		}
	}

	private function intFieldOrNull(event:ReplayEvent, field:String):Null<Int> {
		var value:Dynamic = Reflect.field(event, field);
		if (value == null) {
			return null;
		}

		var intValue = Std.int(value);
		if (intValue != value) {
			return null;
		}

		return intValue;
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
			var decoded = Base64.decode(input);
			try {
				return uint8ArrayToBytes(externs.Pako.inflate(bytesToUint8Array(decoded)));
			} catch (_:Dynamic) {
				// fail safe, return decoded even if decompression fails (for backward compatibility with uncompressed data)
				return decoded;
			}
		} catch (_:Dynamic) {
			return Bytes.ofString(input);
		}
	}

	private inline function bytesToUint8Array(data:Bytes):Uint8Array {
		var out = new Uint8Array(data.length);
		for (i in 0...data.length) {
			out[i] = data.get(i);
		}
		return out;
	}

	private inline function uint8ArrayToBytes(data:Uint8Array):Bytes {
		var out = Bytes.alloc(data.length);
		for (i in 0...data.length) {
			out.set(i, data[i]);
		}
		return out;
	}

	private function normalizeParams(input:ReplayInitParams):ReplayInitParams {
		if (input == null) {
			return defaultParams();
		}

		return {
			recordedKeys: input.recordedKeys != null ? input.recordedKeys : new UInt16Array(0),
			recordInputs: input.recordInputs != null ? input.recordInputs : true,
			recordEvents: input.recordEvents != null ? input.recordEvents : true
		};
	}

	private function defaultParams():ReplayInitParams {
		return {
			recordedKeys: new UInt16Array(0),
			recordInputs: true,
			recordEvents: true
		};
	}
}
