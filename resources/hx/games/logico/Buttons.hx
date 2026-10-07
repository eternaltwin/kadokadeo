package logico;

// The Flash player's button events (onRollOver, onRollOut, onDragOut, onPress) of the clips with handlers, from the
// mouse polled by KadoKadeo (recorded in the replay). Flash dispatches them between two frames: here at the start of
// each Flash frame, before the game's update (from the Electrolink port). Rules of the AVM1 player:
//   - the button under the mouse is the top one whose hit area contains it (clips without handlers do not count,
//     hidden clips are not hit); it is looked for again when the mouse moves or a mouse button changes, not when the
//     clips move under a still mouse (checked in Ruffle: a ball given its handlers under the still pointer does not
//     glow before the pointer moves, a ball that leaves it keeps its glow);
//   - button up: entering a button calls onRollOver, leaving it onRollOut;
//   - press: onPress on the button under the mouse, which keeps the mouse until the release (leaving it then calls
//     onDragOut; no other button rolls over while the button is down);
//   - release out of the pressed button (onReleaseOutside): no onRollOut, the button under the mouse rolls over.
// In Logico the press itself takes the handlers of every ball away (Game.select: deactivate).
class Buttons {
	var dm:MC.Plans;
	var plans:Array<Int>;
	public var over(default, null):MC = null;
	var pressed:MC = null;
	var down:Bool = false;
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
			hover(mx, my);
		}
		for (isDown in changes) {
			hover(mx, my);
			if (isDown && !down) {
				down = true;
				pressed = over;
				if (pressed != null && pressed.onPress != null)
					pressed.onPress();
			} else if (!isDown && down) {
				down = false;
				// onRelease / onReleaseOutside: no handler in Logico
				pressed = null;
			}
			hover(mx, my);
		}
	}

	static inline function isButton(mc:MC):Bool {
		return mc.onPress != null || mc.onRollOver != null || mc.onRollOut != null || mc.onDragOut != null;
	}

	function hit(mx:Float, my:Float):MC {
		for (p in plans)
			for (mc in dm.topDown(p))
				if (mc._visible && !mc.removed && isButton(mc) && mc.hitTest(mx, my))
					return mc;
		return null;
	}

	function hover(mx:Float, my:Float):Void {
		// (a button that lost its handlers stays the one under the mouse until the next look: no rollOver if it is
		// found again)
		if (over != null && over.removed)
			over = null;
		if (pressed != null && pressed.removed)
			pressed = null;
		var target = hit(mx, my);
		if (down) {
			// dragOut of the pressed button only
			if (pressed != null) {
				if (over == pressed && target != pressed && pressed.onDragOut != null)
					pressed.onDragOut();
				over = target == pressed ? pressed : null;
			}
			return;
		}
		if (target == over)
			return;
		var old = over;
		over = target;
		if (old != null && old.onRollOut != null)
			old.onRollOut();
		if (target != null && target.onRollOver != null)
			target.onRollOver();
	}

	// the hand cursor: over a button whose useHandCursor is on
	public function handCursor():Bool {
		return over != null && !over.removed && isButton(over) && over.useHandCursor;
	}
}
