package puzzlemanda;

// The Flash player's button events (onRollOver, onRelease) of the clips with handlers (the cells of the grid, bg
// behind them), from the mouse polled by KadoKadeo, in live games (the replay has the actions they made: Game.act).
// Flash dispatches them between two frames: here before each Flash frame (Game.flashFrame). Rules of the AVM1 player
// (logico.Buttons):
//   - the button under the mouse is the top one whose shape contains it (clips without handlers do not count, hidden
//     clips are not hit); it is looked for again when the mouse moves or a mouse button changes, not when the clips
//     move under a still mouse;
//   - button up: entering a button calls onRollOver;
//   - press: the button under the mouse keeps the mouse until the release (no other button rolls over while the mouse
//     button is down);
//   - release over the pressed button: onRelease (it stays the one under the mouse); release out of it
//     (onReleaseOutside: no handler here): the button under the mouse rolls over.
// Touch screens (`touch`, set by the first touch: Game.onPointerDown): a finger does not hover, so nothing rolls over (the snake
// follows a finger held on the screen through Cell.tryNeighbour, like a mouse), and only a tap is a click: a finger
// that moved more than TAP Flash pixels before it was lifted releases nothing (the end of a drag would cancel the
// snake, onRelease of bg).
class Buttons {
	static inline var TAP = 8;

	var dm:MC.Plans;
	var plans:Array<Int>;

	public var over(default, null):MC = null;
	public var touch:Bool = false;

	var pressed:MC = null;
	var down:Bool = false;
	var pressX:Float = 0;
	var pressY:Float = 0;
	var dragged:Bool = false;
	// the mouse when the button under it was last looked for
	var lastX:Float = Math.NaN;
	var lastY:Float = Math.NaN;

	// plans: the plans holding buttons, from the top one
	public function new(dm:MC.Plans, plans:Array<Int>) {
		this.dm = dm;
		this.plans = plans;
	}

	// mouse in Flash pixels; changes: the button changes since the last call (in order)
	public function frame(mx:Float, my:Float, changes:Array<Bool>):Void {
		if (mx != lastX || my != lastY) {
			lastX = mx;
			lastY = my;
			if (down && (Math.abs(mx - pressX) > TAP || Math.abs(my - pressY) > TAP))
				dragged = true;
			hover(mx, my);
		}
		for (isDown in changes) {
			hover(mx, my);
			#if debug
			Game.inst.event((isDown ? "down " : "up ") + mx + "," + my + " over " + (over == null ? "-" : over.clip.clipName) + " pressed " + (pressed == null ? "-" : pressed.clip.clipName) + " locked " + Game.locked());
			#end
			if (isDown && !down) {
				down = true;
				pressed = over;
				pressX = mx;
				pressY = my;
				dragged = false;
				// (onPress: no handler in Puzzle-Manda)
			} else if (!isDown && down) {
				down = false;
				var p = pressed;
				pressed = null;
				if (p != null && over == p) {
					if (p.onRelease != null && !(touch && dragged))
						p.onRelease();
				} else {
					// onReleaseOutside: the button under the mouse rolls over
					over = null;
				}
			}
			hover(mx, my);
		}
	}

	function hit(mx:Float, my:Float):MC {
		for (p in plans)
			for (mc in dm.topDown(p))
				if (mc.isButton() && mc.hit(mx - mc._x, my - mc._y))
					return mc;
		return null;
	}

	function hover(mx:Float, my:Float):Void {
		// (a button removed or hidden stays the one under the mouse until the next look: no rollOver if it is found again)
		if (over != null && over.removed)
			over = null;
		if (pressed != null && pressed.removed)
			pressed = null;
		var target = hit(mx, my);
		if (down) {
			if (pressed != null)
				over = target == pressed ? pressed : null;
			return;
		}
		if (target == over)
			return;
		over = target;
		if (target != null && target.onRollOver != null && !touch)
			target.onRollOver();
	}

	// the hand cursor: over a button
	public function handCursor():Bool {
		return over != null && over.isButton();
	}
}
