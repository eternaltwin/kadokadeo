package paradice;

/**
 * A MovieClip attached by the game code (DepthManager.attach): the Flash properties the code reads and writes
 * (_x / _y truncated to twips like Flash, _xscale, _rotation, _alpha...) and the Clip that draws it.
 *
 * Display: Paradice ran at 40 Flash frames/s and KadoKadeo steps 32 times per second, so a step plays 1 or 2 Flash
 * frames (Game.update). Showing the last Flash frame of each step would make everything jerk (1, 1, 1, 2 frames
 * per step); like Linea and Magmax, every clip shows its state one Flash frame ago, interpolated towards the last one
 * by the fraction of a Flash frame the steps are behind (displayAll): the game moves by exactly 1.25 Flash frames per
 * step. The pictures of the timelines are the current ones.
 */
class MC {
	public static var all:Array<MC> = [];

	public var clip(default, null):Clip;

	public var _x(default, set):Float = 0;
	public var _y(default, set):Float = 0;
	public var _xscale:Float = 100;
	public var _yscale:Float = 100;
	public var _rotation(default, set):Float = 0;
	public var _alpha:Float = 100;
	public var _visible:Bool = true;
	public var _currentframe(get, never):Int;
	public var _totalframes(get, never):Int;

	// removeMovieClip() was called (by the code or a frame script): Flash's _name == null
	public var removed(default, null):Bool = false;

	// state of the previous Flash frame (display)
	var fresh:Bool = true;
	var snap:Bool = false;
	var px:Float = 0;
	var py:Float = 0;
	var pxs:Float = 100;
	var pys:Float = 100;
	var prot:Float = 0;
	var pa:Float = 100;

	public function new(name:String) {
		clip = new Clip(name);
		clip.owner = this;
		all.push(this);
	}

	// ---------------------------------------------------------------- Flash properties
	function set__x(v:Float):Float {
		return _x = twips(v);
	}

	function set__y(v:Float):Float {
		return _y = twips(v);
	}

	// Flash keeps the rotation of the matrix, read back in ]-180, 180]
	function set__rotation(v:Float):Float {
		v = v % 360;
		if (v > 180)
			v -= 360;
		else if (v <= -180)
			v += 360;
		return _rotation = v;
	}

	public static inline function twips(v:Float):Float {
		return Std.int(v * 20) / 20;
	}

	function get__currentframe():Int {
		return clip.frame;
	}

	function get__totalframes():Int {
		return clip.def.n;
	}

	// frame number, label or number written as a string (gotoAndStop(string(n)) of the original)
	public function gotoAndStop(f:Dynamic):Void {
		clip.gotoAndStop(f);
	}

	public function gotoAndPlay(f:Dynamic):Void {
		clip.gotoAndPlay(f);
	}

	public function play():Void {
		clip.play();
	}

	public function stop():Void {
		clip.stop();
	}

	// a named nested clip (mc.b, mc.sub, mc.bubble of the original)
	public function sub(name:String):Clip {
		return clip.getClip(name);
	}

	public function removeMovieClip():Void {
		if (removed)
			return;
		removed = true;
		clip.removeMovieClip();
		clip.destroy({children: true});
	}

	// Cs.setPercentColor(mc, prc, col): Color.setTransform({ra: int(100 - prc), rb: int(prc / 100 * r), ...}) on
	// the whole clip: the multiplied colour is a tint, the added colour a white silhouette drawn additively (the clip
	// is exported with its silhouettes); Flash keeps the multiplier in percent and the offset in 0..255.
	// The transform also sets the alpha (aa: 100, ab: 0): the random _alpha of the ball is gone, it is opaque at once
	// like its colour
	public function setPercentColor(prc:Float, col:Int):Void {
		_alpha = pa = 100;
		var m = Std.int(100 - prc);
		var c = prc / 100;
		var g = Std.int(Math.max(0, Math.min(255, Math.round(255 * m / 100))));
		inline function ch(v:Int):Int {
			var r = Std.int(c * v);
			return r < 0 ? 0 : r > 255 ? 255 : r;
		}
		var add = (ch((col >> 16) & 0xFF) << 16) | (ch((col >> 8) & 0xFF) << 8) | ch(col & 0xFF);
		clip.setColour((g << 16) | (g << 8) | g, add);
	}

	// a jump of the clip (a ball wrapping around the row): Flash shows it at once, the display does not slide from
	// the previous Flash frame
	public function teleport():Void {
		px = _x;
		py = _y;
		snap = true;
	}

	// ---------------------------------------------------------------- Flash frames and display
	// a Flash frame starts: the state shown keeps the last one, every timeline advances (before the code runs), then
	// the clips removed by their frame scripts are taken out (their _name is null for the code of this frame)
	public static function frameStart():Void {
		var i = 0;
		while (i < all.length) {
			var m = all[i];
			if (m.removed) {
				all.splice(i, 1);
				continue;
			}
			m.fresh = false;
			m.px = m._x;
			m.py = m._y;
			m.pxs = m._xscale;
			m.pys = m._yscale;
			m.prot = m._rotation;
			m.pa = m._alpha;
			i++;
		}
		for (m in all.copy())
			if (!m.removed)
				m.clip.tick();
		Clip.flushRemoved();
	}

	public static function displayAll(f:Float):Void {
		for (m in all)
			if (!m.removed)
				m.display(f);
	}

	function display(f:Float):Void {
		var s = clip;
		// attached during the last Flash frame: the picture shown is still before it (f = 1: the start of the game);
		// shown from the next step, not interpolated from where it was created
		var hide = fresh && f < 1;
		if (fresh)
			f = 1;
		s._x = px + (_x - px) * f;
		s._y = py + (_y - py) * f;
		s._xscale = pxs + (_xscale - pxs) * f;
		s._yscale = pys + (_yscale - pys) * f;
		var dr = _rotation - prot;
		if (dr > 180)
			dr -= 360;
		else if (dr < -180)
			dr += 360;
		s._rotation = prot + dr * f;
		var a = pa + (_alpha - pa) * f;
		s._alpha = a < 0 ? 0 : a > 100 ? 100 : a;
		if (snap && s._prevState != null)
			s._prevState.copyFrom(s._curState);
		snap = hide;
		s.visible = _visible && !hide && !s.selfRemoved;
	}

	public static function clearAll():Void {
		for (m in all.copy())
			m.removeMovieClip();
		all = [];
	}
}

// the planes of the original DepthManager: one container per plane, the clips in their attach order (a new clip
// is above the others of its plane)
class Plans {
	var root:ASprite;
	var plans:Array<ASprite> = [];

	public function new(root:ASprite) {
		this.root = root;
	}

	function get(plan:Int):ASprite {
		while (plans.length <= plan)
			plans.push(null);
		if (plans[plan] == null) {
			var p = new ASprite();
			var at = 0;
			for (i in 0...plan)
				if (plans[i] != null)
					at = root.getChildIndex(plans[i]) + 1;
			root.addChildAt(p, at);
			plans[plan] = p;
		}
		return plans[plan];
	}

	// dm.attach(name, plan)
	public function attach(name:String, plan:Int):MC {
		return add(new MC(name), plan);
	}

	public function add<T:MC>(mc:T, plan:Int):T {
		get(plan).addChild(mc.clip);
		return mc;
	}
}
