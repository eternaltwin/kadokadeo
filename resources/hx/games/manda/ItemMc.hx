package manda;

// Clips "fruit" and "bonus" of the SWF: their picture `f` (one frame per kind of fruit / bonus, stopped by the game)
// zooms in ("apparait", frames 1-9), stops at frame 10, zooms out ("disparait", 15-22) and the clip removes itself at
// frame 23. "ombre" (24, fruit only): shadow of a jumping fruit, the fruit in a solid colour.
// The scissors (bonus 1) and the blue potion (bonus 3) are animations of `f` that keep playing.
class ItemMc extends ASprite {
	public static inline var FRUIT = 0;
	public static inline var BONUS = 1;
	public static inline var SHADE = 2;

	public static inline var STANDARD = 9;
	public static inline var DISPARAIT = 15;
	public static inline var OMBRE = 24;

	// scale of f at each frame of the timelines (frames 10 to 15 and 24: 1)
	static var SC_FRUIT = [
		0.1, 0.4361, 0.7111, 0.925, 1.0778, 1.1694, 1.2, 1.1778, 1.0889, 1, 1, 1, 1, 1, 1, 0.9859, 0.9438, 0.8734, 0.775, 0.6484,
		0.4937, 0.3109, 0.1, 1
	];
	static var SC_BONUS = [
		0.1, 0.5278, 0.8778, 1.15, 1.3444, 1.4611, 1.5, 1.4445, 1.2778, 1, 1, 1, 1, 1, 1, 0.9859, 0.9438, 0.8734, 0.775, 0.6484,
		0.4937, 0.3109, 0.1, 1
	];

	// colour of the shadow (multiply 0, add 78, 129, 20)
	static inline var SHADE_COLOR = 0x4E8114;

	public var f(default, null):Pic;
	public var kind(default, null):Int;
	public var frame(default, null):Int;
	// frame of f
	public var fframe(default, null):Int;
	public var alive(default, null):Bool;

	public var game(default, null):Game;
	var playing:Bool;
	// frames played by the animations of f
	var age:Int;
	var sc:Array<Float>;

	public function new(game:Game, kind:Int) {
		super();
		this.game = game;
		this.kind = kind;
		f = new Pic(kind == BONUS ? "bonus" : kind == SHADE ? "fruitW" : "fruit");
		if (kind == SHADE)
			f.tint = SHADE_COLOR;
		addChild(f);
		sc = kind == BONUS ? SC_BONUS : SC_FRUIT;
		frame = 1;
		fframe = 1;
		playing = true;
		age = 0;
		alive = true;
		applyFrame();
		game.mcs.push(this);
	}

	public function goStop(fr:Int) {
		frame = fr;
		playing = false;
		applyFrame();
	}

	public function goPlay(fr:Int) {
		frame = fr;
		playing = true;
		applyFrame();
	}

	// f.gotoAndStop(i)
	public function fGoto(i:Int) {
		fframe = i;
		showF();
	}

	// one frame of the Flash player (start of the step)
	public function advance() {
		if (!alive)
			return;
		age++;
		if (playing) {
			frame++;
			if (frame == 23) {
				// removeMovieClip("") (frame script, before the frame is drawn)
				remove();
				return;
			}
			if (frame == 10)
				playing = false;
			applyFrame();
		}
		if (kind == BONUS && (fframe == 1 || fframe == 3))
			showF();
	}

	public function remove() {
		if (!alive)
			return;
		alive = false;
		game.mcs.remove(this);
		removeMovieClip();
	}

	function applyFrame() {
		var s = sc[frame - 1] * 100;
		f._xscale = s;
		f._yscale = s;
	}

	function showF() {
		if (kind != BONUS) {
			f.show(fframe);
			return;
		}
		// scissors: frames 1-20 (frame 21 goes back to 1 before being drawn), blue potion: frames 1-15
		var anim = fframe == 1 ? "bonus1" : fframe == 3 ? "bonus3" : "bonus";
		if (f.frames != Tex.get(anim))
			f.setAnim(anim);
		f.show(fframe == 1 ? age % 20 + 1 : fframe == 3 ? age % 15 + 1 : fframe);
	}

	// bounds of f in its own space (f.getBounds(mc) / f scale)
	public function fRect(out:Array<Float>) {
		var t = Data.FRUIT, i = fframe - 1;
		if (kind == BONUS) {
			if (fframe == 1) {
				t = Data.BONUS1;
				i = age % 20;
			} else if (fframe == 3) {
				t = Data.BONUS3;
				i = age % 15;
			} else
				t = Data.BONUS;
		}
		for (k in 0...4)
			out[k] = t[i * 4 + k];
	}

	static var tmp = [0.0, 0, 0, 0];

	// Std.hitTest(c, mc): the bounding boxes meet (box: x0, y0, x1, y1 in the game layer)
	public function hitBox(b:Array<Float>):Bool {
		fRect(tmp);
		var fs = sc[frame - 1];
		var sx = _xscale / 100 * fs;
		var sy = _yscale / 100 * fs;
		var x0 = _x + tmp[0] * sx, x1 = _x + tmp[2] * sx;
		var y0 = _y + tmp[1] * sy, y1 = _y + tmp[3] * sy;
		return x0 <= b[2] && b[0] <= x1 && y0 <= b[3] && b[1] <= y1;
	}
}
