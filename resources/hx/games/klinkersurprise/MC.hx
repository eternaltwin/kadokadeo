package klinkersurprise;

import pixi.core.Pixi.BlendModes;
import pixi.core.textures.Texture;

/**
 * A Flash MovieClip as the original code uses it: _x / _y stored in twips (Flash truncates them to 1/20 px), scales
 * and alpha in percent, frames chosen by the code or played by the timeline (one frame per Flash frame, looping: the
 * clips of Klinker Surprise have no frame script).
 *
 * Display (the MC of the Linea and Hexile ports): Klinker Surprise ran at 40 Flash frames/s and KadoKadeo steps 32
 * times per second, so a step plays 1 or 2 Flash frames (Game.update). Showing the last Flash frame of each step would
 * make the scrolling jerk (1, 1, 1, 2 frames per step); instead every clip shows the state one Flash frame ago,
 * interpolated towards the last one by the fraction of a Flash frame the steps are behind (display). For the same
 * reason a clip removed by the code stays on screen, frozen, until the display reaches the Flash frame it was removed
 * in (the old map at a level change is shown until the new one is), and a clip created in the last Flash frame is not
 * shown before it.
 *
 * The map wraps (a torus of zw x zh pixels): the map, and the clips placed relative to the selector, jump by a period
 * when the selector goes round. A clip with a `wrap` period is interpolated the shortest way modulo that period.
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
	public var _rotation:Float = 0;
	public var _visible:Bool = true;
	public var _currentframe(default, null):Int = 1;
	public var _totalframes(default, null):Int = 1;
	public var removed(default, null):Bool = false;
	public var playing:Bool = false;
	// colour of the picture (a solid colour transform on a white picture: Col.setPercentColor(mc, 100, col))
	public var tint:Int = 0xFFFFFF;

	// shown from the step it is created in (see display)
	public var showNow:Bool = false;
	// period of the positions (0: none), see the class comment
	public var wrap:Float = 0;
	// frees what the clip owns (textures) when its picture is destroyed
	public var onDestroy:Void->Void;

	var frames:Array<Texture>;
	// texture pixels per Flash pixel (pictures of the sheet: 2 at scale 100; containers: 1, their children keep their
	// size)
	var res:Float;
	// position scale of the clip in its parent (the scene itself: 2, see Game)
	public var posK:Float = 1;

	// state of the previous Flash frame (display)
	var fresh:Bool = true;
	var snap:Bool = false;
	var px:Float = 0;
	var py:Float = 0;
	var pxs:Float = 100;
	var pys:Float = 100;
	var pa:Float = 100;

	public function new(?anim:String, ?res:Float) {
		spr = new ASprite();
		this.res = res != null ? res : anim != null ? Game.K : 1;
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

	// blendMode = "add"
	public function setAdd():Void {
		spr.blendMode = BlendModes.ADD;
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
		return _x = twips(v);
	}

	function set__y(v:Float):Float {
		return _y = twips(v);
	}

	public static inline function twips(v:Float):Float {
		return Std.int(v * 20) / 20;
	}

	// a move made at once (a clip placed for the first time): not interpolated
	public function teleport(x:Float, y:Float):Void {
		_x = x;
		_y = y;
		px = _x;
		py = _y;
		snap = true;
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
		if (onDestroy != null) {
			onDestroy();
			onDestroy = null;
		}
		if (spr != null) {
			if (spr.parent != null)
				spr.parent.removeChild(spr);
			spr.destroy({children: true});
			spr = null;
		}
	}

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
		var dx = _x - px;
		var dy = _y - py;
		if (wrap > 0) {
			dx = Lib.Num.hMod(dx, wrap * 0.5);
			dy = Lib.Num.hMod(dy, wrap * 0.5);
		}
		s._x = (px + dx * f) * posK;
		s._y = (py + dy * f) * posK;
		s._xscale = (pxs + (_xscale - pxs) * f) / res;
		s._yscale = (pys + (_yscale - pys) * f) / res;
		var a = pa + (_alpha - pa) * f;
		s._alpha = a < 0 ? 0 : a > 100 ? 100 : a;
		s._rotation = _rotation;
		if (wrap > 0 && s._prevState != null) {
			// the picture of the previous step on the same side of the period
			var w = wrap * posK;
			var cs = s._curState, ps = s._prevState;
			ps.x += w * Math.round((cs.x - ps.x) / w);
			ps.y += w * Math.round((cs.y - ps.y) / w);
		}
		if (snap && s._prevState != null)
			s._prevState.copyFrom(s._curState);
		snap = hide;
		s.visible = _visible && !hide;
		if (frames != null)
			showFrame();
		if (s.tint != tint)
			s.tint = tint;
	}

	function showFrame():Void {
		var t = frames[_currentframe - 1];
		if (spr.texture != t) {
			spr.texture = t;
			spr.anchor.copyFrom(t.defaultAnchor);
		}
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
