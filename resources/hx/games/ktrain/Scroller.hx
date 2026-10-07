package ktrain;

import ktrain.MC.Rect;

// Scroller.hx of the original: the obstacles and the gems going down with the track, their collisions and the depth
// of the driver among the obstacles. Collisions are getBounds rectangles (Const.hit), the hit zones of the obstacles
// (hit1 / hit2) for the driver's feet (man.smc).
class Scroller {
	static var f:Int = 0;
	static var objects:Array<MC>;
	static var gems:Array<MC>;
	static var cleanCount:Int = 10;

	public static var cycles = 0.0;
	public static var lock = false;

	// port: the statics of the original (the SWF was loaded again for every game)
	public static function reset() {
		f = 0;
		objects = null;
		gems = null;
		cleanCount = 10;
		cycles = 0.0;
		lock = false;
	}

	public static function add(mc:MC, y = 0.0) {
		if (objects == null)
			objects = [];
		mc.y = mc._y = if (y != 0.0) y else Const.OBJECTS;
		objects.push(mc);

		Game.game.dm.ysort(Const.DP_OBJECTS);
	}

	public static function addGem(mc:MC, y = 0.0) {
		if (gems == null)
			gems = [];
		mc.y = mc._y = if (y != 0.0) y else Const.OBJECTS;
		gems.push(mc);
	}

	public static function next(mc:MC):Float {
		cycles = mc._height + mc._height * 1.5;
		return cycles;
	}

	public static function scroll(scroll:Float) {
		cycles -= scroll;

		if (Const.SPEED <= 0)
			return;
		if (lock)
			return;
		if (objects == null)
			return;
		if (objects.length < 0)
			return;

		doScroll(objects, scroll);
		doScroll(gems, scroll);
	}

	static function doScroll(objects:Array<MC>, scroll:Float) {
		if (objects == null)
			return;
		for (o in objects) {
			o._visible = true;
			o.y += scroll;
			o._y = o.y;
			if (o._y > Const.HEIGHT + o._height) {
				o.d = true;
			}
		}
	}

	// (hitSmoke: unused, smokoff is never set)

	public static function hideObjects() {
		hide(objects);
		hide(gems);
	}

	public static function showObjects() {
		show(objects);
		show(gems);
	}

	// o.hit1._visible = true: the hit zones are drawn with the blend mode "alpha" (nothing), shown or not
	static function show(list:Array<MC>) {}

	static function hide(list:Array<MC>) {
		if (list == null)
			return;
		for (o in list) {
			if (o._y + o._height < 0) {
				o._visible = false;
				return;
			}

			if (o._y - o._height > Const.HEIGHT) {
				o._visible = false;
				return;
			}
		}
	}

	// ------------------------------------------------------------------------ COLLISIONS
	public static function hitPiouz(mc:MC) {
		if (gems == null)
			return;
		for (o in gems) {
			if (o.piouz) {
				if (Const.hit(mc, o)) {
					Gem.piouzCrash(o);
					return;
				}
			}
		}
	}

	public static function hitGem(mc:MC, f:MC->Void) {
		if (gems == null)
			return;
		for (o in gems) {
			if (o.gem) {
				if (Const.hit(mc, o)) {
					f(o);
				}
			}
		}
	}

	// Collision sur l'objet dans sa globalité
	public static function hitRoot(mc:MC):Bool {
		if (objects != null)
			for (o in objects) {
				if (Const.hit(o, mc))
					return true;
			}

		if (gems != null)
			for (o in gems) {
				if (o.gem) {
					if (Const.hit(mc, o)) {
						return true;
					}
				}
			}
		return false;
	}

	// collision sur les zones de collision de l'objet (r: getBounds of the driver's feet, man.smc)
	public static function hit(r:Rect):Bool {
		if (objects != null)
			for (o in objects) {
				var h1 = o.getSubBounds("hit1");
				if (h1 != null) {
					if (Const.intersects(r, h1)) {
						return true;
					}
				}
				var h2 = o.getSubBounds("hit2");
				if (h2 != null) {
					if (Const.intersects(r, h2)) {
						return true;
					}
				}
			}

		if (gems != null)
			for (o in gems) {
				if (o.gem) {
					if (Const.intersects(o.getBounds(), r)) {
						return true;
					}
				}
			}
		return false;
	}

	// gestion des depths (compiled form of the tests)
	public static function changeDepth(mc:MC):Bool {
		var dm = Game.game.dm;
		if (objects == null)
			return false;
		for (o in objects) {
			var smcY = mc._y + (mc._height / 2);
			var h1 = o.getSubBounds("hit1");
			if (h1 != null) {
				if (Const.intersects(mc.getBounds(), h1)) {
					if (smcY < o._y) {
						if (Math.floor(smcY) != Math.floor(o._y))
							dm.under(mc);
						else
							dm.over(mc);
					} else {
						dm.over(mc);
					}
				}
			}

			// test sur la deuxième zone de collision
			var h2 = o.getSubBounds("hit2");
			if (h2 != null) {
				if (Const.intersects(mc.getBounds(), h2)) {
					if (smcY < o._y) {
						if (Math.floor(smcY) != Math.floor(o._y))
							dm.under(mc);
						else
							dm.over(mc);
					} else {
						dm.over(mc);
					}
				}
			}

			// pas de collision avec les zones de collision mais passage par l'arrière
			if (Const.hit(o, mc)) {
				if (smcY < o._y) {
					dm.under(mc);
				}
			}
		}
		return false;
	}

	// (the length is read once: after a removal the next object moves to the index and waits for the next clean)
	public static function clean() {
		if (cleanCount-- < 0 && objects != null) {
			var n = objects.length;
			for (i in 0...n) {
				var o = objects[i];
				if (o == null || !o.d)
					continue;
				o.removeMovieClip();
				objects.splice(i, 1);
			}
			cleanCount = 10;
		}
	}

	public static function getX(o:MC):Float {
		var left = Const.random(2) == 0;
		var x:Float = 0.0;

		if (!left) {
			x = 170 + o._width + Const.random(Math.floor(Const.HEIGHT - 150 - o._width));
		} else {
			x = o._width / 2 + Const.random(Math.floor(110 - o._width));
		}

		if (x <= o._width / 2)
			x = o._width * 2;
		if (x >= Const.HEIGHT - o._width / 2)
			x = Const.HEIGHT - o._width * 2;

		return x;
	}

	// port: test harness
	public static function debugLists():Dynamic {
		return {objects: objects, gems: gems};
	}
}
