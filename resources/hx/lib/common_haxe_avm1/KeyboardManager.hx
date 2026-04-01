package common_haxe_avm1;

import haxe.ds.IntMap;
import js.html.KeyboardEvent;

class KeyboardManager {
	static public inline var DOWN = 40;
	static public inline var UP = 38;
	static public inline var LEFT = 37;
	static public inline var RIGHT = 39;
	static public inline var ARROW_DOWN = 40;
	static public inline var ARROW_UP = 38;
	static public inline var ARROW_LEFT = 37;
	static public inline var ARROW_RIGHT = 39;
	static public inline var SPACE = 32;
	static public inline var G = 71;
	static public inline var ESCAPE = 27;
	static public inline var CONTROL = 17;

	static private var keyState:IntMap<Bool>;
	static private var isInitialized:Bool = false;
	static private var inputLocked:Bool = false;
	static private var pendingOps:Array<{keyCode:Int, isDown:Bool}> = [];

	static public var lastDown:Int;

	static public function init() {
		if (isInitialized) {
			return;
		}

		keyState = new IntMap();
		isInitialized = true;

		js.Browser.window.addEventListener("keydown", onKeyDown);
		js.Browser.window.addEventListener("keyup", onKeyUp);

		/*window.js.Browser.dEventListener("keydown", function(e) {
			if (["Space", "ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight"].indexOf(e.code) > -1) {
				e.preventDefault();
			}
		}, false);*/
	}

	static private function onKeyUp(e:KeyboardEvent):Void {
		if (inputLocked) {
			e.preventDefault();
			return;
		}
		queueKeyOp(e.keyCode, false);
		e.preventDefault();
	}

	static private function onKeyDown(e:KeyboardEvent) {
		if (inputLocked) {
			e.preventDefault();
			return;
		}
		queueKeyOp(e.keyCode, true);
		if (e.keyCode == SPACE || e.keyCode == ARROW_DOWN)
			e.preventDefault();
	}

	static public function setInputLocked(value:Bool):Void {
		inputLocked = value;
		if (value) {
			pendingOps = [];
		}
	}

	static public function beginFrame():Int {
		ensureInitialized();
		if (pendingOps.length == 0) {
			return 0;
		}

		var ops = pendingOps;
		pendingOps = [];
		var applied = 0;
		for (op in ops) {
			if (op.isDown)
				setKeyDown(op.keyCode);
			else
				setKeyUp(op.keyCode);
			applied++;
		}
		return applied;
	}

	static public function setKeyDown(keyCode:Int):Void {
		ensureInitialized();
		keyState.set(keyCode, true);
		lastDown = keyCode;
	}

	static public function setKeyUp(keyCode:Int):Void {
		ensureInitialized();
		keyState.remove(keyCode);
	}

	static public function clearState():Void {
		ensureInitialized();
		keyState = new IntMap();
		pendingOps = [];
		lastDown = 0;
	}

	static public function isDown(keyCode:Int):Bool {
		ensureInitialized();
		return keyState.exists(keyCode);
	}

	static public function isArrowDown():Bool {
		return isDown(ARROW_RIGHT) || isDown(ARROW_UP) || isDown(ARROW_LEFT) || isDown(ARROW_DOWN);
	}

	static private inline function ensureInitialized():Void {
		if (!isInitialized) {
			init();
		}
	}

	static private inline function queueKeyOp(keyCode:Int, isDown:Bool):Void {
		ensureInitialized();
		pendingOps.push({keyCode: keyCode, isDown: isDown});
	}
}
