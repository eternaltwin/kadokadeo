package mt.flash;

import haxe.ds.IntMap;
import js.html.KeyboardEvent;

class Key {
	static public inline var ARROW_DOWN = 40;
	static public inline var ARROW_UP = 38;
	static public inline var ARROW_LEFT = 37;
	static public inline var ARROW_RIGHT = 39;
	static public inline var SPACE = 32;
	static public inline var ESCAPE = 27;

	static private var keyState:IntMap<Bool>;

	static public var lastDown:Int;

	static var ktime:Int = 0; // FIXME
	static var kcodes = new Array<Null<Int>>();

	static public function init() {
		keyState = new IntMap();

		js.Browser.window.addEventListener("keydown", onKeyDown);
		js.Browser.window.addEventListener("keyup", onKeyUp);
	}

	static private function onKeyUp(e:KeyboardEvent):Void {
		keyState.remove(e.keyCode);
		kcodes[e.keyCode] = null;
	}

	static private function onKeyDown(e:KeyboardEvent) {
		keyState.set(e.keyCode, true);
		lastDown = e.keyCode;
		kcodes[e.keyCode] = ktime;
	}

	static public function isArrowDown():Bool {
		return isDown(ARROW_RIGHT) || isDown(ARROW_UP) || isDown(ARROW_LEFT) || isDown(ARROW_DOWN);
	}

	public static function isDown(c) {
		return kcodes[c] != null;
	}

	public static function isToggled(c) {
		return kcodes[c] == ktime;
	}

	static function onEnterFrame(_) {
		ktime++;
	}
}
