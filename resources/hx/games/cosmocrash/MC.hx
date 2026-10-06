package cosmocrash;

import pixi.core.Pixi.BlendModes;

/**
 * A MovieClip attached by the game code (DepthManager.attach / empty): the Flash properties the code reads and writes
 * (_x / _y truncated to twips like Flash, _xscale, _rotation, _alpha...) and the Clip that draws it.
 *
 * Flash rules the code relies on: a removed clip reads undefined (NaN in a calculation) and ignores what is written
 * to it; a number that is not finite written to _x, _y, _rotation or a scale is ignored.
 *
 * Display: Cosmo Crash ran at 40 Flash frames/s and KadoKadeo steps 32 times per second, so a step plays 1 or 2 Flash
 * frames (Game.update). Like Linea, Magmax and Schizo Fuzz, every clip shows its state one Flash frame ago,
 * interpolated towards the last one by the fraction of a Flash frame the steps are behind (displayAll): the game moves
 * by exactly 1.25 Flash frames per step. The pictures of the timelines are the current ones.
 *
 * The map: the original drew the map (2000 x 450, its end joined to its start) into the 300 x 300 bitmap of the
 * screen at -camera, and a second time one map width further when the screen crosses the end of the map
 * (Game.display). The clips of the map (`map`) are placed on the screen directly: at their position minus the camera,
 * on the copy of the map nearest to the screen, hidden when they are out of it.
 */
class MC {
	public static var all:Array<MC> = [];

	// the camera shown (Game.displayCamera), for the clips of the map
	public static var camX:Float = 0;
	public static var camY:Float = 0;

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

	// removeMovieClip() was called (by the code, a frame script or the removal of its parent): Flash's _name == null
	public var removed(default, null):Bool = false;

	// a clip of the map (see above), its centre (from its position) and half size: out of the screen, it is hidden
	public var map:Bool = false;
	public var cx0:Float = 0;
	public var cullR:Float = 110;

	// a plane that jumps by a whole period (stars, decor of the horizon): the jump is not interpolated
	public var wrapX:Float = 0;
	public var wrapY:Float = 0;

	// the rotation is shown as it is, not interpolated (the hero turns by steps of 10 degrees)
	public var stepRot:Bool = false;

	// clips attached in this one (a DepthManager on it): removed with it
	var kids:Array<MC> = null;

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

	// port: the same timeline with other pictures (a colour copy of the clip, see Folk.new)
	public function setDef(name:String) {
		if (!removed)
			clip.setDef(name);
	}

	// mc.sub != null
	public function hasSub(name:String):Bool {
		return !removed && clip.get(name) != null;
	}

	// mc.sub._x = ... (Flash pixels of this clip)
	public function setSub(name:String, ?x:Float, ?y:Float, ?xscale:Float, ?yscale:Float, ?rotation:Float) {
		if (!removed)
			clip.setSub(name, x, y, xscale, yscale, rotation);
	}

	public function subX(name:String):Float {
		return removed ? Math.NaN : clip.subX(name);
	}

	public function subY(name:String):Float {
		return removed ? Math.NaN : clip.subY(name);
	}

	// mc.sub._visible = v
	public function setSubVisible(name:String, v:Bool) {
		if (!removed)
			clip.setVisible(name, v);
	}

	// mc.blendMode = "add"
	public function blendAdd() {
		if (!removed)
			clip.setBlend(BlendModes.ADD);
	}

	public function removeMovieClip():Void {
		if (removed)
			return;
		removed = true;
		if (kids != null)
			for (k in kids)
				k.removeMovieClip();
		clip.removeMovieClip();
		clip.destroy({children: true});
	}

	public function addKid(m:MC) {
		if (kids == null)
			kids = [];
		kids.push(m);
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

	public static function displayAll(f:Float):Void {
		for (m in all)
			if (!m.removed)
				m.display(f);
	}

	static inline function hmod(n:Float, mod:Float):Float {
		while (n > mod)
			n -= mod * 2;
		while (n < -mod)
			n += mod * 2;
		return n;
	}

	function display(f:Float):Void {
		var s = clip;
		// attached during the last Flash frame: the picture shown is still before it (f = 1: the start of the game);
		// shown from the next step, not interpolated from where it was created
		var hide = fresh && f < 1;
		if (fresh)
			f = 1;
		var dx = x - px;
		var dy = y - py;
		var perX:Float = map ? Cs.lw : wrapX;
		if (perX > 0)
			dx = hmod(dx, perX / 2);
		if (wrapY > 0)
			dy = hmod(dy, wrapY / 2);
		var ix = px + dx * f;
		var iy = py + dy * f;
		var inView = true;
		if (map) {
			// on the copy of the map nearest to the screen
			var sx = hmod(ix - camX + cx0 - Cs.mcw * 0.5, Cs.lw / 2) + Cs.mcw * 0.5 - cx0;
			var sy = iy - camY;
			inView = sx + cx0 > -cullR && sx + cx0 < Cs.mcw + cullR && sy > -cullR && sy < Cs.mch + cullR;
			ix = sx;
			iy = sy;
		}
		s._x = ix;
		s._y = iy;
		// the position shown jumped by a period since the last step: the state PIXI interpolates from jumps with it,
		// else the clip slides across the screen
		if (s._prevState != null) {
			if (perX > 0) {
				var ds = s._curState.x - s._prevState.x;
				if (ds > perX / 2)
					s._prevState.x += perX;
				else if (ds < -perX / 2)
					s._prevState.x -= perX;
			}
			if (wrapY > 0) {
				var ds = s._curState.y - s._prevState.y;
				if (ds > wrapY / 2)
					s._prevState.y += wrapY;
				else if (ds < -wrapY / 2)
					s._prevState.y -= wrapY;
			}
		}
		s._xscale = pxs + (xs - pxs) * f;
		s._yscale = pys + (ys - pys) * f;
		if (stepRot) {
			s._rotation = rot;
			if (s._prevState != null)
				s._prevState.rotation = s._curState.rotation;
		} else {
			var dr = rot - prot;
			if (dr > 180)
				dr -= 360;
			else if (dr < -180)
				dr += 360;
			s._rotation = prot + dr * f;
		}
		var a = pa + (alpha - pa) * f;
		s._alpha = a < 0 ? 0 : a > 100 ? 100 : a;
		if (snap && s._prevState != null)
			s._prevState.copyFrom(s._curState);
		snap = hide;
		s.visible = vis && !hide && !s.selfRemoved && inView;
	}

	public static function clearAll():Void {
		for (m in all.copy())
			m.removeMovieClip();
		all = [];
	}
}

// the planes of the original DepthManager (mt.DepthManager of Flash 8): one container per plane, the clips in the
// order they were attached (the last on top); `map`: the clips attached are clips of the map
class Plans {
	var root:common_haxe_avm1.display.ASprite;
	var owner:MC;
	var map:Bool;
	var plans:Array<common_haxe_avm1.display.ASprite> = [];

	public function new(root:common_haxe_avm1.display.ASprite, ?owner:MC, ?map:Bool = false) {
		this.root = root;
		this.owner = owner;
		this.map = map;
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
		mc.map = map;
		get(plan).addChild(mc.clip);
		if (owner != null)
			owner.addKid(mc);
		return mc;
	}

	// DepthManager.empty: an empty clip
	public function empty(plan:Int):MC {
		return attach(Clip.EMPTY, plan);
	}

	// DepthManager.clear: removes every clip of the plane
	public function clear(plan:Int) {
		if (plan >= plans.length || plans[plan] == null)
			return;
		for (c in plans[plan].children.copy()) {
			var cl = Std.downcast(c, Clip);
			if (cl != null && cl.owner != null)
				cl.owner.removeMovieClip();
		}
	}
}
