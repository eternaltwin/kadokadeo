package punchin;

/**
 * A MovieClip attached by the game code (DepthManager.attach): the Flash properties the code reads and writes (_x / _y
 * truncated to twips like Flash, _xscale...) and the Clip that draws it (digestomax.MC).
 *
 * Flash rules the code relies on: a removed clip reads undefined (NaN in a calculation) and ignores what is written
 * to it; a number that is not finite written to _x, _y, _rotation or a scale is ignored.
 *
 * Display: Punch-In ran at 40 Flash frames/s and KadoKadeo steps 32 times per second, so a step plays 1 or 2 Flash
 * frames (Game.update). Like Cosmo Crash and Digestomax, every clip shows its state one Flash frame ago, interpolated
 * towards the last one by the fraction of a Flash frame the steps are behind (displayAll): the game moves by exactly
 * 1.25 Flash frames per step. The pictures of the timelines (and the colour the code gives) are the current ones.
 */
class MC {
	public static var all:Array<MC> = [];

	public var clip(default, null):Clip;

	public var _x(get, set):Float;
	public var _y(get, set):Float;
	public var _xscale(get, set):Float;
	public var _yscale(get, set):Float;
	public var _rotation(get, set):Float;
	public var _alpha(get, set):Float;
	public var _visible(get, set):Bool;
	public var _currentframe(get, never):Int;
	public var _totalframes(get, never):Int;

	// removeMovieClip() was called (by the code or a frame script): Flash's _name == null
	public var removed(default, null):Bool = false;

	var x:Float = 0;
	var y:Float = 0;
	var xs:Float = 100;
	var ys:Float = 100;
	var rot:Float = 0;
	var alpha:Float = 100;
	var vis:Bool = true;

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
	function get__x():Float {
		return removed ? Math.NaN : x;
	}

	function set__x(v:Float):Float {
		if (!removed && Math.isFinite(v))
			x = twips(v);
		return v;
	}

	function get__y():Float {
		return removed ? Math.NaN : y;
	}

	function set__y(v:Float):Float {
		if (!removed && Math.isFinite(v))
			y = twips(v);
		return v;
	}

	function get__xscale():Float {
		return removed ? Math.NaN : xs;
	}

	function set__xscale(v:Float):Float {
		if (!removed && Math.isFinite(v))
			xs = v;
		return v;
	}

	function get__yscale():Float {
		return removed ? Math.NaN : ys;
	}

	function set__yscale(v:Float):Float {
		if (!removed && Math.isFinite(v))
			ys = v;
		return v;
	}

	function get__rotation():Float {
		return removed ? Math.NaN : rot;
	}

	// Flash keeps the rotation of the matrix, read back in ]-180, 180]
	function set__rotation(v:Float):Float {
		if (removed || !Math.isFinite(v))
			return v;
		v = v % 360;
		if (v > 180)
			v -= 360;
		else if (v <= -180)
			v += 360;
		rot = v;
		return v;
	}

	function get__alpha():Float {
		return removed ? Math.NaN : alpha;
	}

	function set__alpha(v:Float):Float {
		if (!removed && Math.isFinite(v))
			alpha = v;
		return v;
	}

	function get__visible():Bool {
		return !removed && vis;
	}

	function set__visible(v:Bool):Bool {
		if (!removed)
			vis = v;
		return v;
	}

	public static inline function twips(v:Float):Float {
		return Std.int(v * 20) / 20;
	}

	// (undefined for a removed clip: -1 is never equal to a frame)
	function get__currentframe():Int {
		return removed ? -1 : clip.frame;
	}

	function get__totalframes():Int {
		return clip.def.n;
	}

	public function gotoAndStop(f:Dynamic):Void {
		if (!removed)
			clip.gotoAndStop(f);
	}

	public function gotoAndPlay(f:Dynamic):Void {
		if (!removed)
			clip.gotoAndPlay(f);
	}

	// a move that is not shown as a move (a sprite parked off screen placed by its first update): not interpolated
	public function teleport(nx:Float, ny:Float):Void {
		if (removed)
			return;
		_x = nx;
		_y = ny;
		px = x;
		py = y;
		snap = true;
	}

	// mt.bumdum.Col.setPercentColor(mc, prc, col): new Color(mc).setTransform({ra, ga, ba: int(100 - prc), aa: 100,
	// rb, gb, bb: int(prc / 100 * channel), ab: 0}): the pictures multiplied by a grey, plus their white silhouettes
	// tinted with the offsets (Flash adds the offsets where the picture is drawn)
	public function setPercentColor(prc:Float, col:Int):Void {
		if (removed)
			return;
		var m = Std.int(100 - prc);
		var g = Std.int(Math.round(Math.max(0, Math.min(100, m)) / 100 * 255));
		var c = prc / 100;
		var rb = clamp(Std.int(c * ((col >> 16) & 0xFF)));
		var gb = clamp(Std.int(c * ((col >> 8) & 0xFF)));
		var bb = clamp(Std.int(c * (col & 0xFF)));
		clip.setColour((g << 16) | (g << 8) | g, (rb << 16) | (gb << 8) | bb);
	}

	static inline function clamp(v:Int):Int {
		return v < 0 ? 0 : v > 255 ? 255 : v;
	}

	// (the display is one Flash frame late: the clip stays on the screen, as it was, until the next Flash frame starts;
	// a clip attached in the same frame is not shown before it either)
	public function removeMovieClip():Void {
		if (removed)
			return;
		removed = true;
		clip.stop();
		dead.push(this);
	}

	function destroyClip() {
		if (untyped clip._destroyed)
			return;
		clip.removeMovieClip();
		clip.destroy({children: true});
	}

	static var dead:Array<MC> = [];

	static function flushDead() {
		var l = dead;
		dead = [];
		for (m in l)
			m.destroyClip();
	}

	// a Flash frame: the playhead advances (port: a clip the game draws itself plays its own timeline)
	function tick():Void {
		clip.tick();
	}

	// port: what a clip the game draws itself shows, after its position (its text, its gauge)
	function show(f:Float):Void {}

	// ---------------------------------------------------------------- Flash frames and display
	// a Flash frame starts: the state shown keeps the last one, every timeline advances (before the code runs), then
	// the clips removed by their frame scripts are taken out
	public static function frameStart():Void {
		flushDead();
		var i = 0;
		while (i < all.length) {
			var m = all[i];
			if (m.removed) {
				all.splice(i, 1);
				continue;
			}
			m.fresh = false;
			m.px = m.x;
			m.py = m.y;
			m.pxs = m.xs;
			m.pys = m.ys;
			m.prot = m.rot;
			m.pa = m.alpha;
			i++;
		}
		for (m in all.copy())
			if (!m.removed)
				m.tick();
		Clip.flushRemoved();
	}

	public static function displayAll(f:Float):Void {
		for (m in all)
			if (!m.removed)
				m.display(f);
		// removed during the last Flash frame: shown as they were (before it, interpolated), hidden if they were attached
		// in it
		for (m in dead)
			if (!(untyped m.clip._destroyed)) {
				if (m.fresh)
					m.clip.visible = false;
				else
					m.display(f);
			}
	}

	function display(f:Float):Void {
		var s = clip;
		// attached during the last Flash frame: the picture shown is still before it (f = 1: the start of the game);
		// shown from the next step, not interpolated from where it was created
		var hide = fresh && f < 1;
		if (fresh)
			f = 1;
		s._x = px + (x - px) * f;
		s._y = py + (y - py) * f;
		// a scale that changes its sign is a flip (the boxers turned round by initAnim), instant in Flash: interpolated,
		// the picture would be squeezed flat for a step
		var fs = pxs * xs < 0 || pys * ys < 0 ? 1 : f;
		s._xscale = pxs + (xs - pxs) * fs;
		s._yscale = pys + (ys - pys) * fs;
		var dr = rot - prot;
		if (dr > 180)
			dr -= 360;
		else if (dr < -180)
			dr += 360;
		s._rotation = prot + dr * f;
		var a = pa + (alpha - pa) * f;
		s._alpha = a < 0 ? 0 : a > 100 ? 100 : a;
		if (snap && s._prevState != null)
			s._prevState.copyFrom(s._curState);
		snap = hide;
		s.visible = vis && !hide && !s.selfRemoved;
		show(f);
	}

	public static function clearAll():Void {
		for (m in all.copy())
			m.removeMovieClip();
		flushDead();
		all = [];
	}
}

// the planes of the original DepthManager (mt.DepthManager of Flash 8): one container per plane, the clips in the
// order they were attached (the last on top)
class Plans {
	var root:common_haxe_avm1.display.ASprite;
	var plans:Array<common_haxe_avm1.display.ASprite> = [];

	public function new(root:common_haxe_avm1.display.ASprite) {
		this.root = root;
	}

	public function get(plan:Int):common_haxe_avm1.display.ASprite {
		while (plans.length <= plan)
			plans.push(null);
		if (plans[plan] == null) {
			var p = new common_haxe_avm1.display.ASprite();
			var at = 0;
			for (i in 0...plan)
				if (plans[i] != null)
					at = root.getChildIndex(plans[i]) + 1;
			root.addChildAt(p, at);
			plans[plan] = p;
		}
		return plans[plan];
	}

	public function attach(name:String, plan:Int):MC {
		return add(new MC(name), plan);
	}

	// a clip the game draws itself (mcStamina, mcChrono, mcText), attached like the others
	public function add<T:MC>(mc:T, plan:Int):T {
		get(plan).addChild(mc.clip);
		return mc;
	}
}
