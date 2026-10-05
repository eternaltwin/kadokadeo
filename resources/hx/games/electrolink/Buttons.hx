package electrolink;

// The Flash player's button events (onRollOver, onRollOut, onPress) of the clips with handlers, from the mouse polled
// by KadoKadeo (recorded in the replay). Flash dispatches them between two frames: here at the start of each Flash
// frame, before the game's update. Rules of the AVM1 player:
//   - the button under the mouse is the top one whose hit area contains it (clips without handlers do not count,
//     hidden clips are not hit); it is checked again every frame (a clip moving under a still mouse rolls over);
//   - button up: entering a button calls onRollOver, leaving it onRollOut;
//   - press: onPress on the button under the mouse, which keeps the mouse until the release (leaving it then is a
//     dragOut, coming back a dragOver: no handler here; no other button rolls over while the button is down);
//   - release out of the pressed button (onReleaseOutside): no onRollOut, the button under the mouse rolls over.
class Buttons {
	var dm:MC.Plans;
	var plans:Array<Int>;
	var over:MC = null;
	var pressed:MC = null;
	var down:Bool = false;

	// plans: the plans holding buttons, from the top one
	public function new(dm:MC.Plans, plans:Array<Int>) {
		this.dm = dm;
		this.plans = plans;
	}

	// mouse in Flash pixels; changes: the button changes since the last call (in order)
	public function frame(mx:Float, my:Float, changes:Array<Bool>):Void {
		hover(mx, my);
		for (isDown in changes) {
			if (isDown && !down) {
				down = true;
				pressed = over;
				if (pressed != null && pressed.onPress != null)
					pressed.onPress();
			} else if (!isDown && down) {
				down = false;
				// onRelease / onReleaseOutside: no handler in Electrolink
				pressed = null;
			}
			hover(mx, my);
		}
	}

	function hit(mx:Float, my:Float):MC {
		for (p in plans)
			for (mc in dm.topDown(p))
				if (mc._visible && !mc.removed && (mc.onPress != null || mc.onRollOver != null || mc.onRollOut != null)
					&& mc.hitTest(mx, my))
					return mc;
		return null;
	}

	function hover(mx:Float, my:Float):Void {
		if (over != null && over.removed)
			over = null;
		if (pressed != null && pressed.removed)
			pressed = null;
		var target = hit(mx, my);
		if (down) {
			// dragOut / dragOver of the pressed button only
			if (pressed != null)
				over = target == pressed ? pressed : null;
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
}
