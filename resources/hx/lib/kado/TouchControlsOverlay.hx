package kado;

import haxe.ds.IntMap;
import js.Browser;
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import js.html.DivElement;
import js.html.Element;
import js.html.Event;
import js.html.PointerEvent;
import kado.TouchControlsConfig.TouchButtonConfig;
import kado.TouchControlsConfig.TouchButtonShape;
import kado.TouchControlsConfig.TouchControlsConfig;
import kado.TouchControlsConfig.TouchControlsMode;
import kado.TouchControlsConfig.TouchJoystickConfig;
import kado.TouchControlsConfig.TouchSwipeConfig;

typedef TouchControlsCallbacks = {
	@:optional var onKeyDown:Int->Void;
	@:optional var onKeyUp:Int->Void;
	@:optional var onJoystick:(Float, Float, Bool) -> Void;
	@:optional var onAction:String->Void;
	@:optional var onPointerDown:(Int, Int) -> Void;
	@:optional var onPointerMove:(Int, Int) -> Void;
	@:optional var onPointerUp:(Int, Int) -> Void;
}

typedef TouchJoystickState = {
	// analog direction, length 0..1 (0 inside the dead zone)
	var nx:Float;
	var ny:Float;
	var active:Bool;
	// digital direction (-1, 0, 1), snapped on 8 (or 4) directions with some hysteresis
	var dirX:Int;
	var dirY:Int;
}

private typedef TouchButtonState = {
	var cfg:TouchButtonConfig;
	var size:Float;
	var x:Float;
	var y:Float;
	var pressedCount:Int;
}

private typedef TouchSwipePointerState = {
	var startX:Float;
	var startY:Float;
	var startMs:Float;
}

private typedef TouchPendingTapState = {
	var keyCode:Null<Int>;
	var action:Null<String>;
}

class TouchControlsOverlay {
	var canvas:CanvasElement;
	var overlay:CanvasElement;
	var context:CanvasRenderingContext2D;
	var callbacks:TouchControlsCallbacks;

	var viewWidth:Float = 0;
	var viewHeight:Float = 0;
	var safeInsetLeft:Float = 0;
	var safeInsetRight:Float = 0;
	var safeInsetTop:Float = 0;
	var safeInsetBottom:Float = 0;
	var layoutX:Float = 0;
	var layoutY:Float = 0;
	var layoutWidth:Float = 0;
	var layoutHeight:Float = 0;
	var safeAreaProbe:DivElement;

	var buttonStates:Array<TouchButtonState> = [];
	var buttonPointerById:IntMap<Int> = new IntMap();
	var pressedKeys:IntMap<Int> = new IntMap();

	var joystickEnabled:Bool = false;
	var activeJoystickPointer:Null<Int>;
	var joyZoneX:Float = 0;
	var joyZoneY:Float = 0;
	var joyZoneW:Float = 0;
	var joyZoneH:Float = 0;
	var joyBaseNormX:Float = 0.18;
	var joyBaseNormY:Float = 0.8;
	var joyCenterX:Float = 0;
	var joyCenterY:Float = 0;
	var joyKnobOffsetX:Float = 0;
	var joyKnobOffsetY:Float = 0;
	var joyInputX:Float = 0;
	var joyInputY:Float = 0;
	var joyInputActive:Bool = false;
	var joyRadius:Float = 72;
	var joyDeadZone:Float = 0.18;
	var joyDynamic:Bool = false;
	var joyFollow:Bool = false;
	var joyRestNormX:Float = 0.18;
	var joyRestNormY:Float = 0.8;
	var joyDirections:Int = 8;
	var joySector:Int = -1;
	var joyDirX:Int = 0;
	var joyDirY:Int = 0;

	var swipeEnabled:Bool = false;
	var swipeLeftAction:Null<String>;
	var swipeRightAction:Null<String>;
	var swipeUpAction:Null<String>;
	var swipeDownAction:Null<String>;
	var swipeMinDistance:Float = 48;
	var swipeMaxDurationMs:Float = 300;
	var swipePointers:IntMap<TouchSwipePointerState> = new IntMap();
	var pendingTapPointers:IntMap<TouchPendingTapState> = new IntMap();
	var passthroughPointer:Null<Int>;
	var passthroughX:Int = 0;
	var passthroughY:Int = 0;

	public function new(canvas:CanvasElement, config:TouchControlsConfig, callbacks:TouchControlsCallbacks) {
		this.canvas = canvas;
		this.callbacks = callbacks;

		if (config == null || config.mode == TouchControlsMode.NONE) {
			return;
		}

		var parent:Element = canvas.parentElement;
		if (parent == null) {
			return;
		}
		if (parent.style.position == null || parent.style.position == "") {
			parent.style.position = "relative";
		}
		hardenInteractionSurface(parent);

		overlay = Browser.document.createCanvasElement();
		overlay.className = "kk-touch-controls-canvas";
		overlay.style.position = "absolute";
		overlay.style.left = "0";
		overlay.style.top = "0";
		overlay.style.width = "100%";
		overlay.style.height = "100%";
		overlay.style.pointerEvents = "auto";
		overlay.style.zIndex = "1000";
		overlay.style.touchAction = "none";
		overlay.style.userSelect = "none";
		overlay.style.setProperty("-webkit-user-select", "none");
		overlay.style.setProperty("-webkit-touch-callout", "none");
		hardenInteractionSurface(overlay);

		canvas.style.setProperty("touch-action", "none");
		hardenInteractionSurface(canvas);

		parent.appendChild(overlay);
		context = cast overlay.getContext("2d");
		if (context == null) {
			if (overlay.parentElement != null) {
				overlay.parentElement.removeChild(overlay);
			}
			overlay = null;
			return;
		}

		switch (config.mode) {
			case TouchControlsMode.KEYBOARD:
				initButtons(config.buttons);
				initSwipe(config.swipe);
			case TouchControlsMode.JOYSTICK:
				initJoystick(config.joystick);
				initButtons(config.buttons);
				initSwipe(config.swipe);
			case TouchControlsMode.NONE:
		}

		overlay.addEventListener("pointerdown", onPointerDown);
		overlay.addEventListener("pointermove", onPointerMove);
		overlay.addEventListener("pointerup", onPointerUp);
		overlay.addEventListener("pointercancel", onPointerCancel);
		overlay.addEventListener("pointerout", onPointerOut);
		overlay.addEventListener("lostpointercapture", onPointerCancel);
		Browser.window.addEventListener("resize", onResize);

		refreshLayout();
		render();
	}

	public function destroy():Void {
		releasePassthroughPointer();
		releaseAllKeys();
		endJoystick();
		if (overlay != null) {
			overlay.removeEventListener("pointerdown", onPointerDown);
			overlay.removeEventListener("pointermove", onPointerMove);
			overlay.removeEventListener("pointerup", onPointerUp);
			overlay.removeEventListener("pointercancel", onPointerCancel);
			overlay.removeEventListener("pointerout", onPointerOut);
			overlay.removeEventListener("lostpointercapture", onPointerCancel);
		}
		Browser.window.removeEventListener("resize", onResize);
		if (overlay != null && overlay.parentElement != null) {
			overlay.parentElement.removeChild(overlay);
		}
		overlay = null;
		context = null;
		if (safeAreaProbe != null && safeAreaProbe.parentElement != null) {
			safeAreaProbe.parentElement.removeChild(safeAreaProbe);
		}
		safeAreaProbe = null;
		canvas = null;
		buttonStates = [];
		buttonPointerById = new IntMap();
		swipePointers = new IntMap();
		pendingTapPointers = new IntMap();
	}

	public function getJoystickState():Null<TouchJoystickState> {
		if (!joystickEnabled) {
			return null;
		}
		return {
			nx: joyInputX,
			ny: joyInputY,
			active: joyInputActive,
			dirX: joyDirX,
			dirY: joyDirY
		};
	}

	function initButtons(buttons:Array<TouchButtonConfig>):Void {
		buttonStates = [];
		if (buttons == null || buttons.length == 0) {
			return;
		}

		for (cfg in buttons) {
			var size = cfg.size != null ? cfg.size : 72;
			buttonStates.push({
				cfg: cfg,
				size: size,
				x: 0,
				y: 0,
				pressedCount: 0
			});
		}
	}

	function layoutButtons():Void {
		for (state in buttonStates) {
			if (state.cfg.leftPx != null) {
				state.x = layoutX + state.cfg.leftPx;
			} else if (state.cfg.rightPx != null) {
				state.x = layoutX + layoutWidth - state.cfg.rightPx - state.size;
			} else {
				state.x = layoutX + (layoutWidth - state.size) * 0.5;
			}

			if (state.cfg.topPx != null) {
				state.y = layoutY + state.cfg.topPx;
			} else if (state.cfg.bottomPx != null) {
				state.y = layoutY + layoutHeight - state.cfg.bottomPx - state.size;
			} else {
				state.y = layoutY + (layoutHeight - state.size) * 0.5;
			}
		}
	}

	function initJoystick(config:TouchJoystickConfig):Void {
		joystickEnabled = true;
		if (config != null) {
			joyRadius = config.radius != null ? config.radius : joyRadius;
			joyDeadZone = config.deadZone != null ? config.deadZone : joyDeadZone;
			joyDynamic = config.dynamicCenter == true;
			joyFollow = config.follow != null ? config.follow : joyDynamic;
			joyDirections = config.directions == 4 ? 4 : 8;
			joyBaseNormX = config.x != null ? config.x : joyBaseNormX;
			joyBaseNormY = config.y != null ? config.y : joyBaseNormY;
		}
		joyRestNormX = joyBaseNormX;
		joyRestNormY = joyBaseNormY;
	}

	function initSwipe(config:TouchSwipeConfig):Void {
		swipeEnabled = false;
		swipeLeftAction = null;
		swipeRightAction = null;
		swipeUpAction = null;
		swipeDownAction = null;
		swipePointers = new IntMap();

		if (joystickEnabled || config == null) {
			return;
		}

		swipeLeftAction = config.leftAction;
		swipeRightAction = config.rightAction;
		swipeUpAction = config.upAction;
		swipeDownAction = config.downAction;

		var hasAnyAction = !isNullOrEmpty(swipeLeftAction) || !isNullOrEmpty(swipeRightAction) || !isNullOrEmpty(swipeUpAction)
			|| !isNullOrEmpty(swipeDownAction);
		if (!hasAnyAction) {
			return;
		}

		if (config.minDistance != null && config.minDistance > 0) {
			swipeMinDistance = config.minDistance;
		}
		if (config.maxDurationMs != null && config.maxDurationMs > 0) {
			swipeMaxDurationMs = config.maxDurationMs;
		}

		swipeEnabled = true;
	}

	function layoutJoystick(resetCenter:Bool):Void {
		if (joyDynamic) {
			// floating joystick: the whole left half of the screen
			joyZoneX = layoutX;
			joyZoneY = layoutY;
			joyZoneW = layoutWidth * 0.5;
			joyZoneH = layoutHeight;
		} else {
			joyZoneX = layoutX;
			joyZoneW = layoutWidth * 0.58;
			joyZoneH = layoutHeight * 0.58;
			joyZoneY = layoutY + layoutHeight - joyZoneH;
		}

		if (resetCenter || activeJoystickPointer == null || !joyDynamic) {
			joyCenterX = layoutX + layoutWidth * joyBaseNormX;
			joyCenterY = layoutY + layoutHeight * joyBaseNormY;
		}
	}

	function onPointerDown(evt:PointerEvent):Void {
		if (overlay == null) {
			return;
		}

		evt.preventDefault();
		try {
			overlay.setPointerCapture(evt.pointerId);
		} catch (_:Dynamic) {
		}

		var bounds = overlay.getBoundingClientRect();
		var x = evt.clientX - bounds.left;
		var y = evt.clientY - bounds.top;

		var buttonIdx = findButtonAt(x, y);
		if (buttonIdx != null) {
			var state = buttonStates[buttonIdx];
			var deferTapForSwipe = swipeEnabled && state.cfg.invisible == true;
			if (deferTapForSwipe) {
				pendingTapPointers.set(evt.pointerId, {
					keyCode: state.cfg.keyCode,
					action: state.cfg.action
				});
				swipePointers.set(evt.pointerId, {
					startX: x,
					startY: y,
					startMs: Date.now().getTime()
				});
				return;
			}

			state.pressedCount++;
			buttonPointerById.set(evt.pointerId, buttonIdx);
			if (state.cfg.keyCode != null) {
				pressedKeys.set(evt.pointerId, state.cfg.keyCode);
				if (callbacks.onKeyDown != null) {
					callbacks.onKeyDown(state.cfg.keyCode);
				}
			}
			if (state.cfg.action != null && callbacks.onAction != null) {
				callbacks.onAction(state.cfg.action);
			}
			render();
			return;
		}

		if (joystickEnabled && activeJoystickPointer == null && isInJoystickZone(x, y)) {
			activeJoystickPointer = evt.pointerId;
			if (joyDynamic) {
				setJoystickCenter(x, y);
			}
			updateJoystick(x, y, true);
			render();
			return;
		}

		if (swipeEnabled) {
			swipePointers.set(evt.pointerId, {
				startX: x,
				startY: y,
				startMs: Date.now().getTime()
			});
			return;
		}

		startPassthroughPointer(evt);
	}

	function onPointerMove(evt:PointerEvent):Void {
		if (overlay == null) {
			return;
		}
		if (passthroughPointer == evt.pointerId) {
			evt.preventDefault();
			updatePassthroughPointer(evt);
			return;
		}
		if (activeJoystickPointer == null || evt.pointerId != activeJoystickPointer) {
			return;
		}
		evt.preventDefault();
		var bounds = overlay.getBoundingClientRect();
		var x = evt.clientX - bounds.left;
		var y = evt.clientY - bounds.top;
		updateJoystick(x, y, true);
		render();
	}

	function onPointerUp(evt:PointerEvent):Void {
		if (overlay == null) {
			return;
		}
		evt.preventDefault();
		releasePointerState(evt.pointerId, evt, true);
	}

	function onPointerCancel(evt:Event):Void {
		var pe:PointerEvent = cast evt;
		releasePointerState(pe.pointerId, pe, false);
	}

	function onPointerOut(evt:PointerEvent):Void {
		if (overlay == null) {
			return;
		}
		if (activeJoystickPointer == evt.pointerId || passthroughPointer == evt.pointerId) {
			releasePointerState(evt.pointerId, evt, false);
		}
	}

	function releasePointerState(pointerId:Int, evt:PointerEvent, allowGestureDispatch:Bool):Void {
		if (passthroughPointer == pointerId) {
			updatePassthroughPosition(evt);
			releasePassthroughPointer();
			return;
		}

		var swipeState = swipePointers.get(pointerId);
		if (swipeState != null) {
			swipePointers.remove(pointerId);
		}
		var pendingTap = pendingTapPointers.get(pointerId);
		if (pendingTap != null) {
			pendingTapPointers.remove(pointerId);
		}

		var buttonIdx = buttonPointerById.get(pointerId);
		if (buttonIdx != null) {
			buttonPointerById.remove(pointerId);
			var state = buttonStates[buttonIdx];
			if (state != null && state.pressedCount > 0) {
				state.pressedCount--;
			}
			var keyCode = pressedKeys.get(pointerId);
			if (keyCode != null) {
				pressedKeys.remove(pointerId);
				if (callbacks.onKeyUp != null) {
					callbacks.onKeyUp(keyCode);
				}
			}
			render();
		}

		if (activeJoystickPointer != null && pointerId == activeJoystickPointer) {
			endJoystick();
			render();
			return;
		}

		if (!allowGestureDispatch) {
			return;
		}

		var didSwipe = false;
		if (swipeEnabled && swipeState != null) {
			didSwipe = handleSwipeEnd(swipeState, evt);
		}

		if (!didSwipe && pendingTap != null) {
			if (pendingTap.keyCode != null) {
				if (callbacks != null && callbacks.onKeyDown != null) {
					callbacks.onKeyDown(pendingTap.keyCode);
				}
				if (callbacks != null && callbacks.onKeyUp != null) {
					callbacks.onKeyUp(pendingTap.keyCode);
				}
			}
			if (!isNullOrEmpty(pendingTap.action) && callbacks != null && callbacks.onAction != null) {
				callbacks.onAction(pendingTap.action);
			}
		}
	}

	function startPassthroughPointer(evt:PointerEvent):Void {
		if (passthroughPointer != null || callbacks == null || callbacks.onPointerDown == null) {
			return;
		}
		var position = getCanvasPointerPosition(evt);
		if (position == null) {
			return;
		}
		passthroughPointer = evt.pointerId;
		passthroughX = position.x;
		passthroughY = position.y;
		callbacks.onPointerDown(passthroughX, passthroughY);
	}

	function updatePassthroughPointer(evt:PointerEvent):Void {
		if (!updatePassthroughPosition(evt) || callbacks == null || callbacks.onPointerMove == null) {
			return;
		}
		callbacks.onPointerMove(passthroughX, passthroughY);
	}

	function updatePassthroughPosition(evt:PointerEvent):Bool {
		var position = getCanvasPointerPosition(evt);
		if (position == null) {
			return false;
		}
		passthroughX = position.x;
		passthroughY = position.y;
		return true;
	}

	function releasePassthroughPointer():Void {
		if (passthroughPointer == null) {
			return;
		}
		passthroughPointer = null;
		if (callbacks != null && callbacks.onPointerUp != null) {
			callbacks.onPointerUp(passthroughX, passthroughY);
		}
	}

	function getCanvasPointerPosition(evt:PointerEvent):Null<{x:Int, y:Int}> {
		if (canvas == null || evt == null) {
			return null;
		}
		var bounds = canvas.getBoundingClientRect();
		if (bounds == null || bounds.width <= 0 || bounds.height <= 0) {
			return null;
		}
		return {
			x: Std.int((evt.clientX - bounds.left) * canvas.width / bounds.width),
			y: Std.int((evt.clientY - bounds.top) * canvas.height / bounds.height)
		};
	}

	function handleSwipeEnd(state:TouchSwipePointerState, evt:PointerEvent):Bool {
		if (overlay == null) {
			return false;
		}

		var bounds = overlay.getBoundingClientRect();
		var endX = evt.clientX - bounds.left;
		var endY = evt.clientY - bounds.top;

		var dx = endX - state.startX;
		var dy = endY - state.startY;
		var elapsed = Date.now().getTime() - state.startMs;

		if (elapsed > swipeMaxDurationMs) {
			return false;
		}

		var dist = Math.sqrt(dx * dx + dy * dy);
		if (dist < swipeMinDistance) {
			return false;
		}

		var action:Null<String> = null;
		if (Math.abs(dx) >= Math.abs(dy)) {
			action = dx >= 0 ? swipeRightAction : swipeLeftAction;
		} else {
			action = dy >= 0 ? swipeDownAction : swipeUpAction;
		}

		if (!isNullOrEmpty(action) && callbacks != null && callbacks.onAction != null) {
			callbacks.onAction(action);
			return true;
		}
		return false;
	}

	function endJoystick():Void {
		activeJoystickPointer = null;
		joyKnobOffsetX = 0;
		joyKnobOffsetY = 0;
		joyInputX = 0;
		joyInputY = 0;
		joyInputActive = false;
		joySector = -1;
		joyDirX = 0;
		joyDirY = 0;
		if (joyDynamic) {
			// back to its rest position
			joyBaseNormX = joyRestNormX;
			joyBaseNormY = joyRestNormY;
			joyCenterX = layoutX + layoutWidth * joyBaseNormX;
			joyCenterY = layoutY + layoutHeight * joyBaseNormY;
		}
		if (callbacks != null && callbacks.onJoystick != null) {
			callbacks.onJoystick(0, 0, false);
		}
	}

	// 8 (or 4) directions; the current one is kept until the finger is clearly in another one
	static inline var DIRECTION_HYSTERESIS = 0.14; // radians (8 degrees)
	static var SECTOR_X_8 = [1, 1, 0, -1, -1, -1, 0, 1];
	static var SECTOR_Y_8 = [0, 1, 1, 1, 0, -1, -1, -1];

	function updateDigitalDirection(dx:Float, dy:Float, active:Bool):Void {
		if (!active) {
			joySector = -1;
			joyDirX = 0;
			joyDirY = 0;
			return;
		}
		var count = joyDirections == 4 ? 4 : 8;
		var step = Math.PI * 2 / count;
		var angle = Math.atan2(dy, dx);
		var sector = ((Math.round(angle / step) % count) + count) % count;
		if (joySector >= 0 && joySector != sector) {
			var diff = angle - joySector * step;
			while (diff > Math.PI)
				diff -= Math.PI * 2;
			while (diff < -Math.PI)
				diff += Math.PI * 2;
			if (Math.abs(diff) < step * 0.5 + DIRECTION_HYSTERESIS) {
				sector = joySector;
			}
		}
		joySector = sector;
		var i = count == 4 ? sector * 2 : sector;
		joyDirX = SECTOR_X_8[i];
		joyDirY = SECTOR_Y_8[i];
	}

	function moveJoystickCenter(x:Float, y:Float):Void {
		joyCenterX = clamp(x, layoutX, layoutX + layoutWidth);
		joyCenterY = clamp(y, layoutY, layoutY + layoutHeight);
		if (layoutWidth > 0) {
			joyBaseNormX = (joyCenterX - layoutX) / layoutWidth;
		}
		if (layoutHeight > 0) {
			joyBaseNormY = (joyCenterY - layoutY) / layoutHeight;
		}
	}

	function setJoystickCenter(x:Float, y:Float):Void {
		// exactly under the finger (even near an edge): touching does not move yet
		joyCenterX = clamp(x, layoutX, layoutX + layoutWidth);
		joyCenterY = clamp(y, layoutY, layoutY + layoutHeight);
		if (layoutWidth > 0) {
			joyBaseNormX = (joyCenterX - layoutX) / layoutWidth;
		}
		if (layoutHeight > 0) {
			joyBaseNormY = (joyCenterY - layoutY) / layoutHeight;
		}
	}

	function updateJoystick(x:Float, y:Float, active:Bool):Void {
		if (!joystickEnabled) {
			return;
		}

		var dx = x - joyCenterX;
		var dy = y - joyCenterY;
		var dist = Math.sqrt(dx * dx + dy * dy);
		if (joyFollow && dist > joyRadius) {
			// the joystick follows the finger: the finger stays on its edge, in the same direction
			var pull = (dist - joyRadius) / dist;
			moveJoystickCenter(joyCenterX + dx * pull, joyCenterY + dy * pull);
			dx = x - joyCenterX;
			dy = y - joyCenterY;
			dist = Math.sqrt(dx * dx + dy * dy);
		}
		var clamped = Math.min(dist, joyRadius);
		var nx = 0.0;
		var ny = 0.0;
		var magnitude = joyRadius > 0 ? clamped / joyRadius : 0;
		// dead zone, then the full range: no jump when leaving the dead zone
		magnitude = magnitude <= joyDeadZone ? 0 : (magnitude - joyDeadZone) / (1 - joyDeadZone);
		if (dist > 0) {
			nx = (dx / dist) * magnitude;
			ny = (dy / dist) * magnitude;
		}
		nx = Math.max(-1, Math.min(1, nx));
		ny = Math.max(-1, Math.min(1, ny));
		updateDigitalDirection(dx, dy, magnitude > 0);

		if (dist > 0) {
			joyKnobOffsetX = (dx / dist) * clamped;
			joyKnobOffsetY = (dy / dist) * clamped;
		} else {
			joyKnobOffsetX = 0;
			joyKnobOffsetY = 0;
		}

		joyInputX = nx;
		joyInputY = ny;
		joyInputActive = active && magnitude > 0;

		if (callbacks != null && callbacks.onJoystick != null) {
			callbacks.onJoystick(nx, ny, joyInputActive);
		}
	}

	function refreshLayout(?resetJoystickCenter:Bool = false):Void {
		if (overlay == null || context == null) {
			return;
		}

		var bounds = overlay.getBoundingClientRect();
		if (bounds == null || bounds.width <= 0 || bounds.height <= 0) {
			return;
		}

		viewWidth = bounds.width;
		viewHeight = bounds.height;
		updateSafeAreaInsets();
		layoutX = safeInsetLeft;
		layoutY = safeInsetTop;
		layoutWidth = Math.max(0, viewWidth - safeInsetLeft - safeInsetRight);
		layoutHeight = Math.max(0, viewHeight - safeInsetTop - safeInsetBottom);

		var dpr = Browser.window.devicePixelRatio;
		if (dpr == null || dpr <= 0) {
			dpr = 1;
		}

		overlay.width = Std.int(Math.round(viewWidth * dpr));
		overlay.height = Std.int(Math.round(viewHeight * dpr));
		context.setTransform(dpr, 0, 0, dpr, 0, 0);

		layoutButtons();
		if (joystickEnabled) {
			layoutJoystick(resetJoystickCenter);
		}
	}

	function render():Void {
		if (context == null || viewWidth <= 0 || viewHeight <= 0) {
			return;
		}

		context.clearRect(0, 0, viewWidth, viewHeight);

		for (state in buttonStates) {
			if (state.cfg.invisible == true) {
				continue;
			}

			var radius = state.size * 0.5;
			var cx = state.x + radius;
			var cy = state.y + radius;

			context.beginPath();
			if (state.cfg.shape == TouchButtonShape.SQUARE) {
				context.rect(state.x, state.y, state.size, state.size);
			} else {
				context.arc(cx, cy, radius, 0, Math.PI * 2);
			}
			context.fillStyle = state.pressedCount > 0 ? "rgba(58,104,128,0.62)" : "rgba(20,35,45,0.35)";
			context.fill();
			context.lineWidth = 2;
			context.strokeStyle = "rgba(255,255,255,0.6)";
			context.stroke();

			if (state.cfg.label != null && state.cfg.label != "") {
				context.fillStyle = "#eef7ff";
				context.font = "700 " + px(Math.max(13, state.size * 0.27)) + " Arial";
				context.textAlign = "center";
				context.textBaseline = "middle";
				context.fillText(state.cfg.label, cx, cy);
			}
		}

		if (joystickEnabled) {
			renderJoystick();
		}
	}

	function renderJoystick():Void {
		var active = activeJoystickPointer != null;
		context.save();
		// at rest: a faint hint of where it is; held: under the finger
		context.globalAlpha = active ? 1 : 0.55;

		context.beginPath();
		context.arc(joyCenterX, joyCenterY, joyRadius, 0, Math.PI * 2);
		context.fillStyle = "rgba(12,24,34,0.3)";
		context.fill();
		context.lineWidth = 2;
		context.strokeStyle = "rgba(255,255,255,0.55)";
		context.stroke();

		// direction given to the game: its slice of the joystick lights up
		if (active && joySector >= 0) {
			var count = joyDirections == 4 ? 4 : 8;
			var step = Math.PI * 2 / count;
			var a = joySector * step;
			context.beginPath();
			context.moveTo(joyCenterX, joyCenterY);
			context.arc(joyCenterX, joyCenterY, joyRadius, a - step * 0.5, a + step * 0.5);
			context.closePath();
			context.fillStyle = "rgba(255,214,90,0.32)";
			context.fill();
			context.beginPath();
			context.arc(joyCenterX, joyCenterY, joyRadius, a - step * 0.5, a + step * 0.5);
			context.lineWidth = 5;
			context.lineCap = "round";
			context.strokeStyle = "rgba(255,214,90,0.95)";
			context.stroke();
		}

		var knobRadius = joyRadius * 0.42;
		context.beginPath();
		context.arc(joyCenterX + joyKnobOffsetX, joyCenterY + joyKnobOffsetY, knobRadius, 0, Math.PI * 2);
		context.fillStyle = active ? "rgba(240,248,255,0.85)" : "rgba(240,248,255,0.5)";
		context.fill();
		context.lineWidth = 2;
		context.strokeStyle = "rgba(255,255,255,0.95)";
		context.stroke();
		context.restore();
	}

	function findButtonAt(x:Float, y:Float):Null<Int> {
		var i = buttonStates.length - 1;
		while (i >= 0) {
			var state = buttonStates[i];
			if (x >= state.x && x <= state.x + state.size && y >= state.y && y <= state.y + state.size) {
				return i;
			}
			i--;
		}
		return null;
	}

	function isInJoystickZone(x:Float, y:Float):Bool {
		return x >= joyZoneX && x <= joyZoneX + joyZoneW && y >= joyZoneY && y <= joyZoneY + joyZoneH;
	}

	function releaseAllKeys():Void {
		if (callbacks == null || callbacks.onKeyUp == null) {
			pressedKeys = new IntMap();
			buttonPointerById = new IntMap();
			swipePointers = new IntMap();
			pendingTapPointers = new IntMap();
			for (state in buttonStates) {
				state.pressedCount = 0;
			}
			return;
		}

		for (pointerId in pressedKeys.keys()) {
			var keyCode = pressedKeys.get(pointerId);
			if (keyCode != null) {
				callbacks.onKeyUp(keyCode);
			}
		}
		pressedKeys = new IntMap();
		buttonPointerById = new IntMap();
		swipePointers = new IntMap();
		pendingTapPointers = new IntMap();
		for (state in buttonStates) {
			state.pressedCount = 0;
		}
	}

	function onResize(_evt:Event):Void {
		refreshLayout();
		render();
	}

	function updateSafeAreaInsets():Void {
		var body = Browser.document.body;
		if (body == null) {
			safeInsetLeft = 0;
			safeInsetRight = 0;
			safeInsetTop = 0;
			safeInsetBottom = 0;
			return;
		}

		if (safeAreaProbe == null) {
			safeAreaProbe = Browser.document.createDivElement();
			safeAreaProbe.style.position = "fixed";
			safeAreaProbe.style.left = "0";
			safeAreaProbe.style.top = "0";
			safeAreaProbe.style.width = "0";
			safeAreaProbe.style.height = "0";
			safeAreaProbe.style.pointerEvents = "none";
			safeAreaProbe.style.visibility = "hidden";
			safeAreaProbe.style.paddingLeft = "env(safe-area-inset-left)";
			safeAreaProbe.style.paddingRight = "env(safe-area-inset-right)";
			safeAreaProbe.style.paddingTop = "env(safe-area-inset-top)";
			safeAreaProbe.style.paddingBottom = "env(safe-area-inset-bottom)";
			body.appendChild(safeAreaProbe);
		}

		var cs = Browser.window.getComputedStyle(safeAreaProbe);
		safeInsetLeft = parsePx(cs.paddingLeft);
		safeInsetRight = parsePx(cs.paddingRight);
		safeInsetTop = parsePx(cs.paddingTop);
		safeInsetBottom = parsePx(cs.paddingBottom);
	}

	function preventContextMenu(el:Element):Void {
		if (el == null) {
			return;
		}
		el.addEventListener("contextmenu", (evt:Event) -> {
			evt.preventDefault();
		});
	}

	function hardenInteractionSurface(el:Element):Void {
		if (el == null) {
			return;
		}
		el.style.setProperty("user-select", "none");
		el.style.setProperty("-webkit-user-select", "none");
		el.style.setProperty("-webkit-touch-callout", "none");
		el.style.setProperty("-webkit-tap-highlight-color", "transparent");
		el.addEventListener("selectstart", (evt:Event) -> {
			evt.preventDefault();
		});
		el.addEventListener("dragstart", (evt:Event) -> {
			evt.preventDefault();
		});
		preventContextMenu(el);
	}

	inline function px(v:Float):String {
		return Std.string(Std.int(Math.round(v))) + "px";
	}

	function parsePx(value:String):Float {
		if (value == null || value == "") {
			return 0;
		}
		var parsed = Std.parseFloat(value);
		if (Math.isNaN(parsed)) {
			return 0;
		}
		return parsed;
	}

	inline function clamp(v:Float, min:Float, max:Float):Float {
		var low = Math.min(min, max);
		var high = Math.max(min, max);
		if (v < low) {
			return low;
		}
		if (v > high) {
			return high;
		}
		return v;
	}

	inline function isNullOrEmpty(value:Null<String>):Bool {
		return value == null || value == "";
	}
}
