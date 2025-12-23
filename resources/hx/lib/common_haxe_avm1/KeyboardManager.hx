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
	static public inline var ESCAPE = 27;

	static private var keyState:IntMap<Bool>;

	static public var lastDown:Int;

	static public function init() {
		keyState = new IntMap();

		js.Browser.window.addEventListener("keydown", onKeyDown);
		js.Browser.window.addEventListener("keyup", onKeyUp);

		/*window.js.Browser.dEventListener("keydown", function(e) {
			if (["Space", "ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight"].indexOf(e.code) > -1) {
				e.preventDefault();
			}
		}, false);*/
	}

	static private function onKeyUp(e:KeyboardEvent):Void {
		keyState.remove(e.keyCode);
		e.preventDefault();
	}

	static private function onKeyDown(e:KeyboardEvent) {
		keyState.set(e.keyCode, true);
		lastDown = e.keyCode;
		if (e.keyCode == SPACE || e.keyCode == ARROW_DOWN)
			e.preventDefault();
	}

	static public function isDown(keyCode:Int):Bool {
		return keyState.exists(keyCode);
	}

	static public function isArrowDown():Bool {
		return isDown(ARROW_RIGHT) || isDown(ARROW_UP) || isDown(ARROW_LEFT) || isDown(ARROW_DOWN);
	}
}
