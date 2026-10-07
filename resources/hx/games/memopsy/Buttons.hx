package memopsy;

// The Flash player's onPress events, from the mouse polled by KadoKadeo. Flash dispatches them between two frames:
// here at the start of the first Flash frame of each step, before the game's update. Rules of the AVM1 player:
//   - the button under the mouse is the top clip with a handler whose hit area contains it (clips without handlers
//     do not count and do not hide the buttons under them: the face card over its button, a flip; hidden clips are
//     not hit: a card being flipped has its button invisible);
//   - Memopsy only has onPress handlers (the cards).
class Buttons {
	var root:MC;
	var down:Bool = false;

	// the button under the mouse (the hand cursor)
	public var over(default, null):MC = null;

	public function new(root:MC) {
		this.root = root;
	}

	// mouse in Flash pixels; changes: the button changes since the last call (in order)
	public function frame(mx:Float, my:Float, changes:Array<Bool>):Void {
		for (isDown in changes) {
			if (isDown && !down) {
				down = true;
				var b = find(root, mx, my);
				if (b != null)
					b.onPress();
			} else if (!isDown && down) {
				down = false;
			}
		}
		over = find(root, mx, my);
	}

	function find(mc:MC, x:Float, y:Float):MC {
		var i = mc.children.length;
		while (i-- > 0) {
			var c = mc.children[i];
			if (!c._visible || c.removed)
				continue;
			var lx = (x - c._x) * 100 / c._xscale;
			var ly = (y - c._y) * 100 / c._yscale;
			if (c.onPress != null) {
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
}
