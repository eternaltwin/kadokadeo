package hypercube;

// The Flash player's mouse events, from the mouse polled by KadoKadeo (live games: the replay only records the presses
// that did something, see Game.EV_PRESS / EV_DROP). Flash dispatches them between two frames: here at the start of the
// first Flash frame of each step, before the game's update. Rules of the AVM1 player:
//   - a press calls the Mouse listeners first (Game: flPress = true), then onPress of the button under the mouse
//     (takePiece / takeCub set flPress = false again: the press that took a piece does not put it);
//   - the button under the mouse is the top one whose hit area contains it (clips without handlers do not count, and
//     do not hide the buttons under them; hidden clips are not hit); it is checked again every frame;
//   - a pressed button keeps the mouse until the release (no other button rolls over meanwhile);
//   - a Flash Button (the end button) shows its up / over / down frame by itself.
class Buttons {
	var root:MC;
	public var over(default, null):MC = null;
	var pressed:MC = null;
	var down:Bool = false;

	public var onMouseDown:Void->Void;
	public var onMouseUp:Void->Void;

	public function new(root:MC) {
		this.root = root;
	}

	// mouse in Flash pixels; changes: the button changes since the last call (in order)
	public function frame(mx:Float, my:Float, changes:Array<Bool>):Void {
		hover(mx, my);
		for (isDown in changes) {
			if (isDown && !down) {
				down = true;
				if (onMouseDown != null)
					onMouseDown();
				pressed = over;
				if (pressed != null) {
					state(pressed, 3);
					if (pressed.onPress != null)
						pressed.onPress();
				}
			} else if (!isDown && down) {
				down = false;
				if (onMouseUp != null)
					onMouseUp();
				// (onRelease / onReleaseOutside: gotoAndStop on the end Button, which does nothing)
				if (pressed != null && !pressed.removed)
					state(pressed, pressed == over ? 2 : 1);
				pressed = null;
			}
			hover(mx, my);
		}
	}

	// replay: a press of the replay (Game.EV_PRESS), on the button under the mouse (the same one as in the game: the
	// clips are where they were)
	public function pressAt(mx:Float, my:Float):Void {
		var b = find(root, mx, my);
		if (b != null && b.onPress != null)
			b.onPress();
	}

	function find(mc:MC, x:Float, y:Float):MC {
		var i = mc.children.length;
		while (i-- > 0) {
			var c = mc.children[i];
			if (!c._visible || c.removed)
				continue;
			var lx = (x - c._x) * 100 / c._xscale;
			var ly = (y - c._y) * 100 / c._yscale;
			if (c.onPress != null || c.isButton) {
				if (c.hitTest(lx, ly))
					return c;
			} else {
				var r = find(c, lx, ly);
				if (r != null)
					return r;
			}
		}
		return null;
	}

	function hover(mx:Float, my:Float):Void {
		if (over != null && over.removed)
			over = null;
		if (pressed != null && pressed.removed)
			pressed = null;
		var target = find(root, mx, my);
		if (down) {
			// dragOut / dragOver of the pressed button (a Flash Button shows its over frame out of it)
			if (pressed != null) {
				over = target == pressed ? pressed : null;
				state(pressed, over == pressed ? 3 : 2);
			}
			return;
		}
		if (target == over)
			return;
		var old = over;
		over = target;
		if (old != null && !old.removed)
			state(old, 1);
		if (target != null)
			state(target, 2);
	}

	inline function state(b:MC, f:Int):Void {
		if (b.isButton)
			b.gotoAndStop(f);
	}
}
