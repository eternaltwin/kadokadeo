package ktrain;

import haxe.ds.List;

typedef Bg = {idx:Int, frame:Int, type:Int};

// SceneManager.hx of the original: the ground, bitmaps of 300 x 300 scrolling down (desert, snow, grass and the
// transitions between them), into which the decorations and the footprints are drawn
class SceneManager {
	static var bgs:List<MC> = new List();
	static var nbgs:List<Bg> = new List();
	static var newBackIndex:Int = 0;
	static var game:Game = null;
	static var previousType:Int = -1;
	static var initScene:Bool = true;
	static var initDone = false;

	public static var lock = false;

	// port: the statics of the original (the SWF was loaded again for every game)
	public static function reset() {
		bgs = new List();
		nbgs = new List();
		newBackIndex = 0;
		game = null;
		previousType = -1;
		initScene = true;
		initDone = false;
		lock = false;
	}

	public static function init(g:Game) {
		previousType = -1;
		game = g;
		prepare();

		for (i in 0...3) {
			var bg = nbgs.pop();
			var s = getScene(bg);
			var scene = makeNextScene(s, Const.HEIGHT);
			scene._y = scene.y = -Const.HEIGHT * i;
			s.removeMovieClip();
			// (scene.type is never set here: undefined)
			bgs.add(scene);
		}

		initDone = true;
	}

	public static function update(scroll:Float) {
		if (lock)
			return;

		for (scene in bgs) {
			scene.y += scroll;
			scene._y = scene.y;
		}
	}

	public static function clean() {
		if (lock)
			return;

		for (scene in bgs) {
			if (scene._y > Const.HEIGHT && !scene.disposed) {
				var prev = bgs.last();
				addElements(prev.y);
				scene.bmp.dispose();
				scene.disposed = true;
				scene.removeMovieClip();
				scene = null;
				bgs.pop();
				if (nbgs.length < 2) {
					prepare();
				}
			}
		}
	}

	public static function prepare() {
		var type = if (!initDone) 0 else Const.random(2) + 1;
		newBackIndex = Const.SCENE_BASE + Const.random(Const.SCENE_RANDOM);

		for (i in 0...newBackIndex) {
			var bg = {idx: -1, frame: 1, type: type};
			bg.idx = i;

			// transition
			if (i == 0) {
				bg.type = -1;
				if (previousType == -1) {
					switch (type) {
						case 0:
							bg.frame = 5;
						case 1:
							bg.frame = 4;
						case 2:
							bg.frame = 8;
					}
				} else {
					switch (previousType) {
						case 0:
							switch (type) {
								case 0:
									bg.frame = 1;
								case 1:
									bg.frame = 4;
								case 2:
									bg.frame = 8;
							}
						case 1:
							switch (type) {
								case 0:
									bg.frame = 5;
								case 1:
									bg.frame = 2;
								case 2:
									bg.frame = 7;
							}
						case 2:
							switch (type) {
								case 0:
									bg.frame = 9;
								case 1:
									bg.frame = 6;
								case 2:
									bg.frame = 3;
							}
					}
				}
			} else {
				bg.frame = type + 1;
			}

			nbgs.add(bg);
		}

		previousType = type;
	}

	public static function addElements(y = 0.0) {
		var bg = nbgs.pop();
		var s = getScene(bg);
		var scene = makeNextScene(s, Const.HEIGHT);
		scene._y = scene.y = -Const.HEIGHT + y;
		s.removeMovieClip();
		scene.type = bg.type;
		bgs.add(scene);
	}

	static function makeNextScene(mc:MC, h:Int):MC {
		var scene = game.dm.empty(Const.DP_BG);
		scene.bmp = new Bmp(Const.HEIGHT, h);
		scene.attachBitmap(scene.bmp, Const.DP_BG);
		var m = Const.getMatrixFromMc(mc);
		scene.bmp.draw("mcBg", mc._currentframe, m[0], m[1]);
		return scene;
	}

	static function getScene(bg:Bg):MC {
		var s = game.dm.attach("mcBg", Const.DP_BG);
		s.gotoAndStop(bg.frame);
		// (the alpha of a clip only drawn into a bitmap, then removed: not seen; visual random)
		s._alpha = Const.randomVfx(80) + 20;
		return s;
	}

	// a footprint: drawn into the scene under it (compiled form of the tests)
	public static function drawOnScene(mc:MC) {
		for (b in bgs) {
			if (b._y < Const.HEIGHT) {
				if (b._y + Const.HEIGHT > 0) {
					var bh = b._y + Const.HEIGHT;
					if (bh < Const.HEIGHT) {
						if (contains(0, 0, Const.HEIGHT, Std.int(b._y + Const.HEIGHT), mc._x, mc._y)) {
							var m = Const.getMatrixFromMc(mc, 0, -b._y);
							b.bmp.draw(mc.name, mc._currentframe, m[0], m[1]);
						}
						break;
					}
					if (contains(0, Std.int(b._y), Const.HEIGHT, Std.int(Const.HEIGHT - b._y), mc._x, mc._y)) {
						var m = Const.getMatrixFromMc(mc, 0, -b._y);
						b.bmp.draw(mc.name, mc._currentframe, m[0], m[1]);
					}
				}
			}
		}
	}

	// flash.geom.Rectangle(x, y, w, h).contains(px, py)
	static inline function contains(x:Float, y:Float, w:Float, h:Float, px:Float, py:Float):Bool {
		return px >= x && px < x + w && py >= y && py < y + h;
	}

	public static function getSceneType():Int {
		for (b in bgs) {
			if (b._y >= 0 && b._y <= Const.HEIGHT)
				continue;

			switch (b.type) {
				case null:
					continue;
				case -1:
					continue;
				case 0:
					return 1;
				case 1:
					return 2;
				case 2:
					return 1;
				case _:
			}
		}
		return 1;
	}

	public static function getSceneTypeForObject():Null<Int> {
		var prev:Null<Int> = -1;
		for (b in bgs) {
			if (b == null)
				continue;

			if (b._y >= 0 && b._y <= Const.HEIGHT) {
				prev = b.type;
				continue;
			}

			switch (b.type) {
				case null:
					continue;
				case -1:
					return -1;
				case 0:
					return 0;
				case 1:
					return 1;
				case 2:
					return 2;
				case _:
			}
		}

		return prev;
	}

	// the clip drawn into every scene that is not on the screen (it may lie across two of them)
	public static function paste(mc:MC):Float {
		var y = -1.0;
		for (b in bgs) {
			if (b._y >= 0 && b._y <= Const.HEIGHT)
				continue;
			var m = Const.getMatrixFromMc(mc, 0, -b.y);
			b.bmp.draw(mc.name, mc._currentframe, m[0], m[1]);
			y = b._y;
		}
		return y;
	}
}
