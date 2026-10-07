package chakrebouddha;

import chakrebouddha.FlashFilters;
import pixi.core.renderers.webgl.filters.Filter;
import pixi.core.textures.Texture;

// a filter of the original (flash.filters), as the code sets it: copied when assigned, like Flash's mc.filters
enum FilterDef {
	// GlowFilter, GradientGlowFilter([c, c], alphas [0, 1], ratios [0, 255], "outer") and DropShadowFilter of distance
	// 0: the same picture (the alpha of the clip blurred, times the strength, in the colour, under the clip)
	Glow(blur:Float, strength:Float, color:Int, quality:Int);
	// BlurFilter(blurX, blurY), quality 1
	Blur(bx:Float, by:Float);
}

/**
 * A Flash MovieClip as the original code uses it: _x / _y stored in twips (Flash truncates them to 1/20 px), scales
 * and alpha in percent, rotation in degrees, frames chosen by the code or played by the timeline (one frame per Flash
 * frame, looping: the clips of Chakre Bouddha have no frame script), filters and a colour transform set by the code.
 *
 * Display (the MC of the Linea, Hexile and Klinker Surprise ports): Chakre Bouddha ran at 40 Flash frames/s and
 * KadoKadeo steps 32 times per second, so a step plays 1 or 2 Flash frames (Game.update). Showing the last Flash
 * frame of each step would make the moves jerk (1, 1, 1, 2 frames per step); instead every clip shows the state one
 * Flash frame ago, interpolated towards the last one by the fraction of a Flash frame the steps are behind (display).
 * For the same reason a clip removed by the code stays on screen, frozen, until the display reaches the Flash frame it
 * was removed in, and a clip created in the last Flash frame is not shown before it.
 */
class MC {
	public static var all:Array<MC> = [];
	// removed by the code, still shown until the display reaches the Flash frame they were removed in
	static var dying:Array<MC> = [];

	public var spr:ASprite;
	public var parent:MC;
	public var children:Array<MC> = [];

	public var _x(default, set):Float = 0;
	public var _y(default, set):Float = 0;
	public var _xscale:Float = 100;
	public var _yscale:Float = 100;
	public var _alpha:Float = 100;
	public var _rotation(default, set):Float = 0;
	public var _visible:Bool = true;
	public var _currentframe(default, null):Int = 1;
	public var _totalframes(default, null):Int = 1;
	public var removed(default, null):Bool = false;
	public var playing:Bool = false;
	// mc.filters (a copy, like Flash)
	public var filters(get, set):Array<FilterDef>;
	// the colour transform set by the code (flash.geom.Transform.colorTransform): multipliers and offsets (0..255) of
	// red, green, blue; null: none
	public var cx:Array<Float> = null;

	// shown from the step it is created in (see display)
	public var showNow:Bool = false;
	// shown at the Flash frame nearest to the display, never between two (the shake of the screen)
	public var noLerp:Bool = false;

	var frames:Array<Texture>;
	// texture pixels per Flash pixel (pictures of the sheets at scale 100; containers: 1, their children keep their
	// size)
	var res:Float;
	// position scale of the clip in its parent (the scene itself: 2, see Game)
	public var posK:Float = 1;

	var _filters:Array<FilterDef> = [];
	// the PIXI filters showing _filters and cx (see showFilters)
	var fx:Array<Filter> = [];

	// state of the previous Flash frame (display)
	var fresh:Bool = true;
	var snap:Bool = false;
	var px:Float = 0;
	var py:Float = 0;
	var pxs:Float = 100;
	var pys:Float = 100;
	var pa:Float = 100;
	var pr:Float = 0;

	public function new(?anim:String, ?res:Float) {
		spr = new ASprite();
		this.res = res != null ? res : 1;
		if (anim != null)
			setFrames(anim);
		all.push(this);
	}

	public function setFrames(anim:String):Void {
		frames = Tex.get(anim);
		_totalframes = frames.length;
		if (_currentframe > _totalframes)
			_currentframe = _totalframes;
		showFrame();
	}

	// ---------------------------------------------------------------- display list
	public function attach<T:MC>(child:T):T {
		child.parent = this;
		children.push(child);
		spr.addChild(child.spr);
		return child;
	}

	public function removeMovieClip():Void {
		if (removed)
			return;
		markRemoved();
		if (parent != null)
			parent.children.remove(this);
		dying.push(this);
	}

	function markRemoved():Void {
		removed = true;
		playing = false;
		for (c in children)
			c.markRemoved();
	}

	// ---------------------------------------------------------------- timeline
	public function gotoAndStop(f:Int):Void {
		playing = false;
		_currentframe = f < 1 ? 1 : f > _totalframes ? _totalframes : f;
	}

	public function gotoAndPlay(f:Int):Void {
		_currentframe = f < 1 ? 1 : f > _totalframes ? _totalframes : f;
		playing = true;
	}

	public function play():Void {
		playing = true;
	}

	public function stop():Void {
		playing = false;
	}

	// a Flash frame: playing timelines advance before the code runs
	function advance():Void {
		if (!playing || removed)
			return;
		var f = _currentframe + 1;
		_currentframe = f > _totalframes ? 1 : f;
	}

	// ---------------------------------------------------------------- properties
	function set__x(v:Float):Float {
		// (Flash ignores a NaN: the Conchoid move of Chakra computes a square root of a negative number)
		return Math.isNaN(v) ? _x : _x = twips(v);
	}

	function set__y(v:Float):Float {
		return Math.isNaN(v) ? _y : _y = twips(v);
	}

	// Flash keeps the rotation in -180..180
	function set__rotation(v:Float):Float {
		if (Math.isNaN(v))
			return _rotation;
		v = v % 360;
		if (v > 180)
			v -= 360;
		else if (v < -180)
			v += 360;
		return _rotation = v;
	}

	// the next display is not interpolated from the previous Flash frame (a clip placed for the first time, the ring
	// of a chakra shown again)
	public function snapNext():Void {
		px = _x;
		py = _y;
		pxs = _xscale;
		pys = _yscale;
		pa = _alpha;
		pr = _rotation;
		snap = true;
	}

	public static inline function twips(v:Float):Float {
		return Std.int(v * 20) / 20;
	}

	function get_filters():Array<FilterDef> {
		return _filters.copy();
	}

	function set_filters(v:Array<FilterDef>):Array<FilterDef> {
		_filters = v == null ? [] : v.copy();
		return v;
	}

	// ---------------------------------------------------------------- Flash frames and display
	public static function frameStart():Void {
		flushDying();
		for (m in all) {
			m.fresh = false;
			m.px = m._x;
			m.py = m._y;
			m.pxs = m._xscale;
			m.pys = m._yscale;
			m.pa = m._alpha;
			m.pr = m._rotation;
		}
		for (m in all)
			m.advance();
	}

	// the pictures of the clips removed before this Flash frame go
	static function flushDying():Void {
		if (dying.length == 0)
			return;
		var gone = dying;
		dying = [];
		for (m in gone)
			m.destroyPicture();
		var i = 0;
		while (i < all.length) {
			if (all[i].removed && all[i].spr == null)
				all.splice(i, 1);
			else
				i++;
		}
	}

	function destroyPicture():Void {
		for (c in children)
			c.destroyPicture();
		onDestroy();
		if (spr != null) {
			if (spr.parent != null)
				spr.parent.removeChild(spr);
			spr.filters = null;
			spr.destroy({children: true});
			spr = null;
		}
		for (f in fx)
			FlashFilters.release(f);
		fx = [];
	}

	// frees what a clip owns besides its picture
	function onDestroy():Void {}

	public static function displayAll(f:Float):Void {
		if (f >= 1)
			flushDying();
		for (m in all)
			if (m.spr != null)
				m.display(f);
	}

	function display(f:Float):Void {
		var s = spr;
		// created during the last Flash frame: the picture shown is still before it (f = 1: the start of the game);
		// shown from the next step, not interpolated from where it was created
		var hide = fresh && f < 1 && !showNow;
		if (fresh)
			f = 1;
		if (noLerp) {
			f = f < 0.5 ? 0 : 1;
			snap = true;
		}
		s._x = (px + (_x - px) * f) * posK;
		s._y = (py + (_y - py) * f) * posK;
		s._xscale = (pxs + (_xscale - pxs) * f) / res;
		s._yscale = (pys + (_yscale - pys) * f) / res;
		var a = pa + (_alpha - pa) * f;
		s._alpha = a < 0 ? 0 : a > 100 ? 100 : a;
		// the shortest way between the two angles
		var dr = _rotation - pr;
		if (dr > 180)
			dr -= 360;
		else if (dr < -180)
			dr += 360;
		s._rotation = pr + dr * f;
		if (snap && s._prevState != null)
			s._prevState.copyFrom(s._curState);
		snap = hide;
		s.visible = _visible && !hide;
		if (frames != null)
			showFrame();
		showFilters();
	}

	function showFrame():Void {
		var t = frames[_currentframe - 1];
		if (spr.texture != t) {
			spr.texture = t;
			spr.anchor.copyFrom(t.defaultAnchor);
		}
	}

	// the filters of the clip then its colour transform, as PIXI filters (kept from one display to the next while the
	// list has the same kinds of filters)
	function showFilters():Void {
		if (_filters.length == 0 && cx == null && fx.length == 0)
			return;
		var want:Array<Filter> = [];
		var n = 0;
		// a run of BlurFilters (Phys fadeType 4 adds one at each update): one gaussian blur of the same variance
		var vx = 0.0, vy = 0.0;
		inline function flushBlur() {
			if (vx > 0 || vy > 0) {
				var b:FlashBlur = cast reuse(n++, FlashBlur);
				b.set(vx, vy);
				want.push(b);
			}
			vx = vy = 0;
		}
		for (d in _filters) {
			switch (d) {
				case Blur(bx, by):
					// a box of bx pixels (weights 1/2 at its ends): variance bx^2 / 12
					vx += bx * bx / 12;
					vy += by * by / 12;
				case Glow(blur, strength, color, quality):
					flushBlur();
					var g:FlashGlow = cast reuse(n++, FlashGlow);
					g.set(blur, strength, color, quality);
					want.push(g);
			}
		}
		flushBlur();
		if (cx != null) {
			var c:FlashCx = cast reuse(n++, FlashCx);
			c.set(cx);
			want.push(c);
		}
		for (i in n...fx.length)
			FlashFilters.release(fx[i]);
		fx.resize(n);
		var cur:Array<Filter> = spr.filters;
		var same = cur != null && cur.length == want.length;
		if (same)
			for (i in 0...want.length)
				if (cur[i] != want[i])
					same = false;
		if (!same)
			spr.filters = want.length > 0 ? want : null;
	}

	function reuse(i:Int, cl:Class<Filter>):Filter {
		if (i < fx.length && Std.isOfType(fx[i], cl))
			return fx[i];
		if (i < fx.length)
			FlashFilters.release(fx[i]);
		var f = FlashFilters.take(cl);
		fx[i] = f;
		return f;
	}

	public static function clearAll():Void {
		for (m in dying)
			if (m.spr != null)
				m.destroyPicture();
		for (m in all)
			if (m.spr != null && (m.parent == null || m.parent.spr == null))
				m.destroyPicture();
		all = [];
		dying = [];
	}
}

// the depths of the original (DepthManager planes): one container per plane, clips drawn in attach order
class Plans {
	var root:MC;
	var plans:Array<MC> = [];

	public function new(root:MC) {
		this.root = root;
	}

	public function get(plan:Int):MC {
		for (i in plans.length...plan + 1)
			plans[i] = null;
		if (plans[plan] == null) {
			var p = new MC();
			// in depth order among the existing planes
			var at = 0;
			for (i in 0...plan)
				if (plans[i] != null)
					at = root.spr.getChildIndex(plans[i].spr) + 1;
			p.parent = root;
			root.children.push(p);
			root.spr.addChildAt(p.spr, at);
			plans[plan] = p;
		}
		return plans[plan];
	}

	public function attach(anim:String, plan:Int, ?res:Float):MC {
		return get(plan).attach(new MC(anim, res));
	}

	public function add<T:MC>(mc:T, plan:Int):T {
		get(plan).attach(mc);
		return mc;
	}

	public function empty(plan:Int):MC {
		return get(plan).attach(new MC());
	}
}
