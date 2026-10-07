package digestomax;

import pixi.core.Pixi.BlendModes;

/**
 * A MovieClip attached by the game code (DepthManager.attach / empty): the Flash properties the code reads and writes
 * (_x / _y truncated to twips like Flash, _xscale, _rotation, _alpha...) and the Clip that draws it (cosmocrash.MC).
 *
 * Flash rules the code relies on: a removed clip reads undefined (NaN in a calculation) and ignores what is written
 * to it; a number that is not finite written to _x, _y, _rotation or a scale is ignored.
 *
 * Display: Digestomax ran at 40 Flash frames/s and KadoKadeo steps 32 times per second, so a step plays 1 or 2 Flash
 * frames (Game.update). Like Cosmo Crash, every clip shows its state one Flash frame ago, interpolated towards the last
 * one by the fraction of a Flash frame the steps are behind (displayAll): the game moves by exactly 1.25 Flash frames
 * per step. The pictures of the timelines are the current ones.
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

	// removeMovieClip() was called (by the code, a frame script or the removal of its parent): Flash's _name == null
	public var removed(default, null):Bool = false;

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
	var jump:Bool = false;
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

	// (the display is one Flash frame late: the clip stays on the screen, as it was, until the next Flash frame starts;
	// the clips attached in the same frame are not shown before it either)
	public function removeMovieClip():Void {
		if (removed)
			return;
		removed = true;
		if (kids != null)
			for (k in kids)
				k.removeMovieClip();
		clip.stop();
		dead.push(this);
	}

	function destroyClip() {
		if (untyped clip._destroyed)
			return;
		clip.removeMovieClip();
		clip.destroy({children: true});
	}

	// port: removed and no longer shown in this Flash frame (a swallowed fruit: the hero's animation draws it in his
	// beak from this frame on, shown as it was it would be there twice)
	public function removeNow():Void {
		removeMovieClip();
		fresh = true;
	}

	// port: shown where it is now, interpolated neither from the last Flash frame nor from the last step (the hero
	// moving onto the fruit he swallows: the animation, current, draws him from his old cell; interpolated, he would
	// be drawn behind it)
	public function showNow():Void {
		px = x;
		py = y;
		jump = true;
	}

	static var dead:Array<MC> = [];

	static function flushDead() {
		var l = dead;
		dead = [];
		for (m in l)
			m.destroyClip();
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
				m.clip.tick();
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
		// a scale that changes its sign is a flip (Piou: _xscale = sens * 100), instant in Flash: interpolated, the
		// picture would be squeezed flat for a step
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
		if ((snap || jump) && s._prevState != null)
			s._prevState.copyFrom(s._curState);
		snap = hide;
		jump = false;
		s.visible = vis && !hide && !s.selfRemoved;
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
	var owner:MC;
	var plans:Array<common_haxe_avm1.display.ASprite> = [];

	public function new(root:common_haxe_avm1.display.ASprite, ?owner:MC) {
		this.root = root;
		this.owner = owner;
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
		if (owner != null)
			owner.addKid(mc);
		return mc;
	}

	// DepthManager.empty: an empty clip
	public function empty(plan:Int):MC {
		return attach(Clip.EMPTY, plan);
	}

	// DepthManager.over: the clip on top of its plane (a removed clip or undefined: nothing)
	public function over(mc:MC) {
		if (mc == null || mc.removed)
			return;
		var p = mc.clip.parent;
		if (p != null && plans.indexOf(cast p) >= 0)
			p.setChildIndex(mc.clip, p.children.length - 1);
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
