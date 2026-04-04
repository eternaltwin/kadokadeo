package kado;

import haxe.ds.IntMap;
import js.Browser;
import js.html.CanvasElement;
import js.html.DivElement;
import js.html.Element;
import js.html.PointerEvent;
import kado.TouchControlsConfig.TouchButtonConfig;
import kado.TouchControlsConfig.TouchControlsConfig;
import kado.TouchControlsConfig.TouchControlsMode;
import kado.TouchControlsConfig.TouchJoystickConfig;

typedef TouchControlsCallbacks = {
	@:optional var onKeyDown:Int->Void;
	@:optional var onKeyUp:Int->Void;
	@:optional var onJoystick:(Float, Float, Bool) -> Void;
	@:optional var onAction:String->Void;
}

class TouchControlsOverlay {
	var canvas:CanvasElement;
	var root:DivElement;
	var controls:Array<DivElement> = [];
	var callbacks:TouchControlsCallbacks;
	var pressedKeys:IntMap<Int> = new IntMap();
	var activeJoystickPointer:Null<Int>;
	var joystickZone:DivElement;
	var joystickBase:DivElement;
	var joystickKnob:DivElement;
	var joyCenterX:Float = 0;
	var joyCenterY:Float = 0;
	var joyRadius:Float = 72;
	var joyDeadZone:Float = 0.18;
	var joyDynamic:Bool = false;

	public function new(canvas:CanvasElement, config:TouchControlsConfig, callbacks:TouchControlsCallbacks) {
		this.canvas = canvas;
		this.callbacks = callbacks;

		if (config == null || config.mode == TouchControlsMode.NONE) {
			return;
		}

		if (canvas.parentElement == null) {
			return;
		}

		root = Browser.document.createDivElement();
		root.className = "kk-touch-controls";
		root.style.position = "absolute";
		root.style.left = "0";
		root.style.top = "0";
		root.style.right = "0";
		root.style.bottom = "0";
		root.style.pointerEvents = "none";
		root.style.zIndex = "1000";
		root.style.touchAction = "none";
		root.style.setProperty("padding-left", "env(safe-area-inset-left)");
		root.style.setProperty("padding-right", "env(safe-area-inset-right)");
		root.style.setProperty("padding-top", "env(safe-area-inset-top)");
		root.style.setProperty("padding-bottom", "env(safe-area-inset-bottom)");

		canvas.style.setProperty("touch-action", "none");

		Browser.document.body.appendChild(root);

		switch (config.mode) {
			case TouchControlsMode.KEYBOARD:
				initButtons(config.buttons);
			case TouchControlsMode.JOYSTICK:
				initJoystick(config.joystick);
				initButtons(config.buttons);
			case TouchControlsMode.NONE:
		}
	}

	public function destroy():Void {
		releaseAllKeys();
		endJoystick();
		if (root != null && root.parentElement != null) {
			root.parentElement.removeChild(root);
		}
		root = null;
		canvas = null;
		controls = [];
	}

	function initButtons(buttons:Array<TouchButtonConfig>):Void {
		if (buttons == null) {
			return;
		}

		for (cfg in buttons) {
			var size = cfg.size != null ? cfg.size : 72;
			var button = Browser.document.createDivElement();
			button.className = "kk-touch-button kk-touch-button-" + cfg.id;
			button.style.position = "absolute";
			button.style.left = pct(cfg.x);
			button.style.top = pct(cfg.y);
			button.style.width = px(size);
			button.style.height = px(size);
			button.style.marginLeft = px(-size * 0.5);
			button.style.marginTop = px(-size * 0.5);
			button.style.borderRadius = "999px";
			button.style.border = "2px solid rgba(255,255,255,0.6)";
			button.style.background = "rgba(20,35,45,0.35)";
			button.style.color = "#eef7ff";
			button.style.display = "flex";
			button.style.alignItems = "center";
			button.style.justifyContent = "center";
			button.style.fontFamily = "Arial";
			button.style.fontWeight = "700";
			button.style.fontSize = px(Math.max(13, size * 0.27));
			button.style.userSelect = "none";
			button.style.pointerEvents = "auto";
			button.style.touchAction = "none";
			button.innerText = cfg.label;

			button.addEventListener("pointerdown", (evt:PointerEvent) -> {
				evt.preventDefault();
				if (cfg.keyCode != null) {
					pressedKeys.set(evt.pointerId, cfg.keyCode);
					if (callbacks.onKeyDown != null) {
						callbacks.onKeyDown(cfg.keyCode);
					}
				}
				if (cfg.action != null && callbacks.onAction != null) {
					callbacks.onAction(cfg.action);
				}
				button.style.background = "rgba(58,104,128,0.62)";
			});

			var release = (evt:PointerEvent) -> {
				evt.preventDefault();
				var keyCode = pressedKeys.get(evt.pointerId);
				if (keyCode != null) {
					pressedKeys.remove(evt.pointerId);
					if (callbacks.onKeyUp != null) {
						callbacks.onKeyUp(keyCode);
					}
				}
				button.style.background = "rgba(20,35,45,0.35)";
			};

			button.addEventListener("pointerup", release);
			button.addEventListener("pointercancel", release);
			button.addEventListener("pointerout", release);

			root.appendChild(button);
			controls.push(button);
		}
	}

	function initJoystick(config:TouchJoystickConfig):Void {
		if (config != null) {
			joyRadius = config.radius != null ? config.radius : joyRadius;
			joyDeadZone = config.deadZone != null ? config.deadZone : joyDeadZone;
			joyDynamic = config.dynamicCenter == true;
		}

		joystickZone = Browser.document.createDivElement();
		joystickZone.className = "kk-touch-joystick-zone";
		joystickZone.style.position = "absolute";
		joystickZone.style.left = "0";
		joystickZone.style.bottom = "0";
		joystickZone.style.width = "58%";
		joystickZone.style.height = "58%";
		joystickZone.style.pointerEvents = "auto";
		joystickZone.style.touchAction = "none";

		var joyX = config != null && config.x != null ? config.x : 0.18;
		var joyY = config != null && config.y != null ? config.y : 0.8;

		joystickBase = Browser.document.createDivElement();
		joystickBase.className = "kk-touch-joystick-base";
		joystickBase.style.position = "absolute";
		joystickBase.style.width = px(joyRadius * 2);
		joystickBase.style.height = px(joyRadius * 2);
		joystickBase.style.marginLeft = px(-joyRadius);
		joystickBase.style.marginTop = px(-joyRadius);
		joystickBase.style.borderRadius = "999px";
		joystickBase.style.border = "2px solid rgba(255,255,255,0.5)";
		joystickBase.style.background = "rgba(18,30,38,0.2)";
		joystickBase.style.left = pct(joyX);
		joystickBase.style.top = pct(joyY);

		joystickKnob = Browser.document.createDivElement();
		joystickKnob.className = "kk-touch-joystick-knob";
		joystickKnob.style.position = "absolute";
		joystickKnob.style.width = px(joyRadius * 0.9);
		joystickKnob.style.height = px(joyRadius * 0.9);
		joystickKnob.style.marginLeft = px(-(joyRadius * 0.45));
		joystickKnob.style.marginTop = px(-(joyRadius * 0.45));
		joystickKnob.style.borderRadius = "999px";
		joystickKnob.style.border = "2px solid rgba(255,255,255,0.7)";
		joystickKnob.style.background = "rgba(78,136,166,0.48)";
		joystickKnob.style.left = "50%";
		joystickKnob.style.top = "50%";
		joystickBase.appendChild(joystickKnob);

		joystickZone.addEventListener("pointerdown", onJoystickDown);
		joystickZone.addEventListener("pointermove", onJoystickMove);
		joystickZone.addEventListener("pointerup", onJoystickUp);
		joystickZone.addEventListener("pointercancel", onJoystickUp);
		joystickZone.addEventListener("pointerout", onJoystickUp);

		root.appendChild(joystickZone);
		root.appendChild(joystickBase);
		controls.push(joystickZone);
		controls.push(joystickBase);
	}

	function onJoystickDown(evt:PointerEvent):Void {
		evt.preventDefault();
		activeJoystickPointer = evt.pointerId;
		if (joyDynamic) {
			setJoystickCenter(evt.clientX, evt.clientY);
		}
		updateJoystick(evt.clientX, evt.clientY, true);
	}

	function onJoystickMove(evt:PointerEvent):Void {
		if (activeJoystickPointer == null || evt.pointerId != activeJoystickPointer) {
			return;
		}
		evt.preventDefault();
		updateJoystick(evt.clientX, evt.clientY, true);
	}

	function onJoystickUp(evt:PointerEvent):Void {
		if (activeJoystickPointer == null || evt.pointerId != activeJoystickPointer) {
			return;
		}
		evt.preventDefault();
		endJoystick();
	}

	function endJoystick():Void {
		activeJoystickPointer = null;
		if (joystickKnob != null) {
			joystickKnob.style.left = "50%";
			joystickKnob.style.top = "50%";
		}
		if (callbacks != null && callbacks.onJoystick != null) {
			callbacks.onJoystick(0, 0, false);
		}
	}

	function setJoystickCenter(clientX:Float, clientY:Float):Void {
		var bounds = root.getBoundingClientRect();
		if (bounds == null || bounds.width <= 0 || bounds.height <= 0) {
			return;
		}
		var x = ((clientX - bounds.left) / bounds.width) * 100;
		var y = ((clientY - bounds.top) / bounds.height) * 100;
		joystickBase.style.left = pct(x / 100);
		joystickBase.style.top = pct(y / 100);
	}

	function updateJoystick(clientX:Float, clientY:Float, active:Bool):Void {
		var bounds = joystickBase.getBoundingClientRect();
		if (bounds == null) {
			return;
		}

		joyCenterX = bounds.left + bounds.width * 0.5;
		joyCenterY = bounds.top + bounds.height * 0.5;

		var dx = clientX - joyCenterX;
		var dy = clientY - joyCenterY;
		var dist = Math.sqrt(dx * dx + dy * dy);
		var clamped = Math.min(dist, joyRadius);
		var nx = 0.0;
		var ny = 0.0;
		var magnitude = joyRadius > 0 ? clamped / joyRadius : 0;
		if (dist > 0) {
			nx = (dx / dist) * magnitude;
			ny = (dy / dist) * magnitude;
		}
		if (magnitude < joyDeadZone) {
			nx = 0;
			ny = 0;
			magnitude = 0;
		}
		nx = Math.max(-1, Math.min(1, nx));
		ny = Math.max(-1, Math.min(1, ny));

		if (dist > 0) {
			var knobX = (dx / dist) * clamped;
			var knobY = (dy / dist) * clamped;
			joystickKnob.style.left = "calc(50% + " + px(knobX) + ")";
			joystickKnob.style.top = "calc(50% + " + px(knobY) + ")";
		}

		if (callbacks != null && callbacks.onJoystick != null) {
			callbacks.onJoystick(nx, ny, active && magnitude > 0);
		}
	}

	function releaseAllKeys():Void {
		if (callbacks == null || callbacks.onKeyUp == null) {
			pressedKeys = new IntMap();
			return;
		}

		for (pointerId in pressedKeys.keys()) {
			var keyCode = pressedKeys.get(pointerId);
			if (keyCode != null) {
				callbacks.onKeyUp(keyCode);
			}
		}
		pressedKeys = new IntMap();
	}

	inline function pct(v:Float):String {
		return Std.string(v * 100) + "%";
	}

	inline function px(v:Float):String {
		return Std.string(Std.int(Math.round(v))) + "px";
	}
}
