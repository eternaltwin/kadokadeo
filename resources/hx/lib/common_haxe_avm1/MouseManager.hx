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
	static private var hasCapturedCoords:Bool = false;
	static private var capturedX:Float = 0;
	static private var capturedY:Float = 0;
	static private var interactionTrackingRegistered:Bool = false;

	static public function init(context:Application):Void {
		app = context;
		isInitialized = app != null;
		if (isInitialized) {
			registerInteractionTracking();
		}
	}

	static public function getMouseX():Float {
		if (!isInitialized) {
			return 0;
		}
		if (hasCapturedCoords) {
			return capturedX;
		}
		return app.renderer.plugins.interaction.mouse.global.x;
	}

	static public function getMouseY():Float {
		if (!isInitialized) {
			return 0;
		}
		if (hasCapturedCoords) {
			return capturedY;
		}
		return app.renderer.plugins.interaction.mouse.global.y;
	}

	static public function captureInputEvent(event:Dynamic):Void {
		var x = extractCoord(event, true);
		var y = extractCoord(event, false);
		if (x == null || y == null) {
			return;
		}

		hasCapturedCoords = true;
		capturedX = x;
		capturedY = y;
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

	static private function registerInteractionTracking():Void {
		if (interactionTrackingRegistered) {
			return;
		}

		var interaction = app.renderer.plugins.interaction;
		if (interaction == null || !Reflect.hasField(interaction, "on")) {
			return;
		}

		for (eventName in ["pointermove", "mousemove", "touchstart", "touchmove", "touchend", "touchcancel"]) {
			untyped interaction.on(eventName, captureInputEvent);
		}
		interactionTrackingRegistered = true;
	}

	static private function extractCoord(event:Dynamic, forX:Bool):Null<Float> {
		if (event == null) {
			return null;
		}

		var data = Reflect.field(event, "data");
		if (data != null) {
			var global = Reflect.field(data, "global");
			if (global != null) {
				var value = Reflect.field(global, forX ? "x" : "y");
				if (value != null) {
					return value;
				}
			}
		}

		var global = Reflect.field(event, "global");
		if (global != null) {
			var value = Reflect.field(global, forX ? "x" : "y");
			if (value != null) {
				return value;
			}
		}

		var src = Reflect.field(event, "changedTouches");
		if (src == null) {
			src = Reflect.field(event, "touches");
		}
		if (src != null && Reflect.hasField(src, "length") && src.length > 0) {
			var touch = src[0];
			var touchValue = Reflect.field(touch, forX ? "clientX" : "clientY");
			if (touchValue != null) {
				return touchValue;
			}
		}

		var clientValue = Reflect.field(event, forX ? "clientX" : "clientY");
		if (clientValue != null) {
			return clientValue;
		}

		return null;
	}
}
