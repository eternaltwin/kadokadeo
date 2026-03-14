package common_haxe_avm1;

import pixi.core.Application;

typedef MouseCoords = {
	var x:Float;
	var y:Float;
}

class MouseManager {
	static private var app:Application;
	static private var isInitialized:Bool = false;

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
}
