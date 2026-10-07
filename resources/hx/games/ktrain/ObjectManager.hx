package ktrain;

// ObjectManager.hx of the original: the obstacles beside the track (cactuses, skeletons, rocks, trees, snowmen), the
// tunnels and gates over it, and the decorations pasted into the ground
class ObjectManager {
	public static var lock = false;
	static var game:Game;
	static var cycles:Float;

	// port: the statics of the original (the SWF was loaded again for every game)
	public static function reset() {
		lock = false;
		game = null;
		cycles = 0;
	}

	public static function init(g:Game) {
		game = g;
		cycles = 10;
		for (i in 0...20) {
			placeObject();
		}
	}

	public static function update(scroll:Float) {
		if (lock)
			return;
		if (Const.SPEED <= 0)
			return;

		cycles -= scroll;
		if (cycles <= 0) {
			placeObject();
		}
	}

	static function placeObject() {
		var type = SceneManager.getSceneTypeForObject();
		if (type < 0 || type == null) {
			return;
		}

		switch (type) {
			case 0:
				pattern("mcObjets_terre", 5, 8, 10);

				if (Const.random(10) == 1) {
					pasteObject("mcObjets_terre", if (Const.random(2) == 0) 4 else 7);
				} else if (Const.random(100) < 5) {
					addTunnel(0);
				} else {
					var f = Const.Ea[Const.random(Const.Ea.length)];
					addObject(f, "mcObjets_terre", "mcObjets_terre_ombre");

					if (Const.random(30) == 0) {
						var f = Const.Ga[Const.random(Const.Ga.length)];
						addObject(f, "mcObjets", "mcObjets_ombre");
					}
				}
				return;
			case 1:
				pattern("mcObjets_neige", 5, 5, 10);

				var f = Const.Sa[Const.random(Const.Sa.length)];
				addObject(f, "mcObjets_neige", "mcObjets_neige_ombre");

				if (Const.random(100) < 5) {
					addTunnel(1);
				} else if (Const.random(30) == 0) {
					var f = Const.Ga[Const.random(Const.Ga.length)];
					addObject(f, "mcObjets", "mcObjets_ombre");
				}
				return;
			case 2:
				pattern("mcObjets_herbe", 4, 1, 10);

				if (Const.random(100) < 5) {
					addTunnel(2);
				} else if (Const.random(10) == 0) {
					var f = Const.Ga[Const.random(Const.Ga.length)];
					addObject(f, "mcObjets", "mcObjets_ombre");
				}
				return;
		}
	}

	static function pasteObject(name:String, frame:Int) {
		var o = game.dm.attach(name, Const.DP_OBJECTS);
		o.gotoAndStop(frame);
		placeMc(o);
		SceneManager.paste(o);
		o.removeMovieClip();
		o = null;
	}

	// a decoration and up to max - 1 more around it, pasted into the ground: the first one is placed like an obstacle
	// (it sets the distance to the next object: game state); the others are only pictures (visual random)
	static function pattern(name:String, frames:Int, addFrames:Int, max:Int) {
		var o = game.dm.attach(name, Const.DP_OBJECTS);
		o.gotoAndStop(Const.random(frames) + addFrames);
		placeMc(o);
		SceneManager.paste(o);
		var x = o._x;
		var y = o._y;
		var w = o._width;
		var h = o._height;
		o.removeMovieClip();
		o = null;

		for (i in 0...Const.randomVfx(max)) {
			var p = game.dm.attach(name, Const.DP_OBJECTS);
			p.gotoAndStop(Const.randomVfx(frames) + addFrames);
			p._x = x + Const.randomVfx(Std.int(w));
			p._y = y + Const.randomVfx(Std.int(w));
			SceneManager.paste(p);
			p.removeMovieClip();
			p = null;
		}
	}

	static function addObject(frame:Int, name:String, shadow:String) {
		var o = game.dm.attach(name, Const.DP_OBJECTS);
		o.gotoAndStop(frame);
		placeMc(o);
		if (Station.hitTest(o)) {
			o.removeMovieClip();
			return;
		}
		var s = game.dm.attach(shadow, Const.DP_SHADOW);
		// (the sprite in the shadow symbols is placed in "multiply")
		s.setBlend("multiply");
		s._y = o._y;
		s._x = o._x;
		s.gotoAndStop(frame);
		Scroller.add(s);
		Scroller.add(o);
	}

	static function addTunnel(type:Int) {
		var o = game.dm.attach("mcTunnels", Const.DP_OBJECTS);
		o.gotoAndStop(1 + switch (type) {
			case 0:
				if (Const.random(10) == 0) 0 else 3;
			case 1:
				if (Const.random(10) == 0) 1 else 4;
			case 2:
				if (Const.random(10) == 0) 2 else 3;
			case _:
				0;
		});

		o._x = Const.CENTER_X;
		o.y = o._y = -Const.HEIGHT;
		cycles = Scroller.next(o);

		if (Station.hitTest(o)) {
			o.removeMovieClip();
			return;
		}
		#if debug
		game.stats.tunnels++;
		#end
		Scroller.add(o);
	}

	static function placeMc(mc:MC) {
		mc._x = Scroller.getX(mc);
		mc.y = mc._y = -50;
		cycles = Scroller.next(mc);
	}
}
