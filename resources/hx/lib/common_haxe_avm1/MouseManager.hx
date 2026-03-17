package common_haxe_avm1;

import pixi.core.Application;

typedef MouseCoords = {
	var x:Float;
	var y:Float;
}

class MouseManager {
	static private var app:Application;
	static private var isInitialized:Bool = false;
	static private var pendingCallbacks:Array<Void->Void> = [];

	static public function init(context:Application):Void {
		app = context;
		isInitialized = app != null;
	}

	static public function getMouseX():Float {
		if (!isInitialized) {
			return 0;
		}
		return app.renderer.plugins.interaction.mouse.global.x;
	}

	static public function getMouseY():Float {
		if (!isInitialized) {
			return 0;
		}
		return app.renderer.plugins.interaction.mouse.global.y;
	}

	static public function getMouseCoords():MouseCoords {
		return {
			x: getMouseX(),
			y: getMouseY()
		};
	}

	static public function getApp():Application {
		return app;
	}

	static public function queueInputCallback(callback:Void->Void):Void {
		if (callback == null) {
			return;
		}
		pendingCallbacks.push(callback);
	}

	static public function beginFrame():Int {
		if (pendingCallbacks.length == 0) {
			return 0;
		}

		var callbacks = pendingCallbacks;
		pendingCallbacks = [];
		var applied = 0;
		for (callback in callbacks) {
			callback();
			applied++;
		}
		return applied;
	}
}
