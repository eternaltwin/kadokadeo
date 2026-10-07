package oursouinvader;

import pixi.filters.colormatrix.ColorMatrixFilter;

/**
 * A MovieClip attached by the game code (DepthManager.attach / empty): the Flash properties the code reads and writes
 * (_x / _y truncated to twips like Flash, _xscale, _rotation, _alpha...), the filters the code gives it, and the Clip
 * that draws it (cosmocrash.MC without the map).
 *
 * Flash rules the code relies on: a removed clip reads undefined (NaN in a calculation) and ignores what is written
 * to it; a number that is not finite written to _x, _y, _rotation or a scale is ignored (the eyes of the monsters
 * after the hero's death: Math.atan2 of an undefined position).
 *
 * Display: Oursouinvader ran at 40 Flash frames/s and KadoKadeo steps 32 times per second, so a step plays 1 or 2 Flash
 * frames (Game.update). Like Linea, Magmax, Schizo Fuzz and Cosmo Crash, every clip shows its state one Flash frame
 * ago, interpolated towards the last one by the fraction of a Flash frame the steps are behind (displayAll): the game
 * moves by exactly 1.25 Flash frames per step. The pictures of the timelines are the current ones.
 */
class MC {
	public static var all:Array<MC> = [];

	public var clip(default, null):Clip;

	// root.obj of the original (Sprite.new): the sprite of this clip, for its frame scripts (mcSpike: obj.kill())
	public var obj:Sprite;

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

	// filters set by the code (mc.filters = [GlowFilter]) and Cs.setPercentColor (Color.setTransform)
	var glow:FlashGlow;
	var colour:ColorMatrixFilter;

	public function new(name:String) {
		if (name == null) {
			removed = true;
			return;
		}
		clip = new Clip(name);
		clip.owner = this;
		all.push(this);
	}

	// `root = null` of the original (a monster that explodes, the dead hero): Flash reads undefined from it (NaN) and
	// ignores what the code still writes to it during the frame (the sprites of the frame are updated from a copy of
	// the list, Game.moveSprites)
	public static var NONE(default, null):MC = new MC(null);

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
		return removed ? -1 : clip.def.n;
	}

	// a frame number, a label, or a number written as a string (gotoAndStop("2"), gotoAndStop(string(n)))
	public function gotoAndStop(f:Dynamic):Void {
		if (!removed)
			clip.gotoAndStop(f);
	}

	public function gotoAndPlay(f:Dynamic):Void {
		if (!removed)
			clip.gotoAndPlay(f);
	}

	public function play():Void {
		if (!removed)
			clip.play();
	}

	public function stop():Void {
		if (!removed)
			clip.stop();
	}

	// a named nested clip (null when it is not on the current frame, or when this clip is removed): mc.sub
	public function sub(name:String):Clip {
		return removed ? null : clip.getClip(name);
	}

	public function removeMovieClip():Void {
		if (removed)
			return;
		removed = true;
		clip.removeMovieClip();
		clip.destroy({children: true});
	}

	// ---------------------------------------------------------------- filters
	// mc.filters = [GlowFilter(color, alpha, blurX, blurY, strength)] (quality 1, outer): the glow of the clip at run
	// time, its parts move on their own (tentacles, pincers, eyes)
	public function setGlow(color:Int, alpha:Float, blurX:Float, blurY:Float, strength:Float) {
		if (removed)
			return;
		glow = new FlashGlow(blurX, blurY, strength, color, alpha);
		applyFilters();
	}

	// Cs.setPercentColor: Color.setTransform({ra: int(100 - prc), rb: int(prc / 100 * r), ..., aa: 100, ab: 0}) on the
	// whole clip, after its filters (Flash colours the filtered picture); Flash keeps the multiplier in percent and the
	// offset in 0..255. At 0 % it is the identity: no filter
	public function setPercentColor(prc:Float, col:Int) {
		if (removed)
			return;
		if (prc == 0) {
			if (colour != null) {
				colour = null;
				applyFilters();
			}
			return;
		}
		var m = Std.int(100 - prc) / 100;
		var c = prc / 100;
		var r = Std.int(c * (col >> 16)) / 255;
		var g = Std.int(c * ((col >> 8) & 0xFF)) / 255;
		var b = Std.int(c * (col & 0xFF)) / 255;
		var added = colour == null;
		if (added)
			colour = new ColorMatrixFilter();
		colour.matrix = [m, 0, 0, 0, r, 0, m, 0, 0, g, 0, 0, m, 0, b, 0, 0, 0, 1, 0];
		if (added)
			applyFilters();
	}

	function applyFilters() {
		var l:Array<pixi.core.renderers.webgl.filters.Filter> = [];
		if (glow != null)
			l.push(glow);
		if (colour != null)
			l.push(colour);
		clip.filters = l.length > 0 ? cast l : null;
	}

	// ---------------------------------------------------------------- Flash frames and display
	// a Flash frame starts: the state shown keeps the last one, every timeline advances (before the code runs), then
	// the clips removed by their frame scripts are taken out
	public static function frameStart():Void {
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
				m.clip.tick();
		Clip.flushRemoved();
	}

	// the first placement of a sprite (Sprite.new leaves its clip at (-100, -100), off the screen, until the first
	// update of the sprite): Flash shows it there from this frame, the display does not slide in from off the screen
	// (hidden until the display reaches this frame, like a clip attached now)
	public function teleport():Void {
		px = x;
		py = y;
		fresh = true;
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
		s._x = px + (x - px) * f;
		s._y = py + (y - py) * f;
		s._xscale = pxs + (xs - pxs) * f;
		s._yscale = pys + (ys - pys) * f;
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
	}

	public static function clearAll():Void {
		for (m in all.copy())
			m.removeMovieClip();
		all = [];
	}
}

// the planes of the original DepthManager: one container per plane, the clips in the order they were attached (the
// last on top)
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
		var mc = new MC(name);
		get(plan).addChild(mc.clip);
		return mc;
	}

	// DepthManager.empty: an empty clip
	public function empty(plan:Int):MC {
		return attach(Clip.EMPTY, plan);
	}
}
