package cyclopean;

import pixi.core.textures.Texture;

/**
 * A Flash MovieClip as the original code uses it: _x / _y stored in twips (Flash truncates them to 1/20 px: the map
 * follows ball.root._x), _rotation kept in -180..180 like Flash's setter, scales and alpha in percent, frames chosen
 * by the code or played by the timeline (one frame per Flash frame, looping like a timeline without stop()), a
 * frame script that removes the clip (removeAt).
 *
 * Display (the MC of the Linea / Hexile ports): Cyclopean ran at 40 Flash frames/s and KadoKadeo steps 32 times per
 * second, so a step plays 1 or 2 Flash frames (Game.update). Showing the last Flash frame of each step would make
 * the scroll jerk (1, 1, 1, 2 frames per step); instead every clip shows the state one Flash frame ago, interpolated
 * towards the last one by the fraction of a Flash frame the steps are behind (display). The rotation is
 * interpolated too (the whole level turns around the ball), by the shortest way.
 */
class MC {
	public static var all:Array<MC> = [];

	public var spr:ASprite;
	public var parent:MC;
	public var children:Array<MC> = [];
	// the Sprite driving the clip (downcast(root).obj)
	public var obj:Sprite;

	public var _x(default, set):Float = 0;
	public var _y(default, set):Float = 0;
	public var _xscale:Float = 100;
	public var _yscale:Float = 100;
	public var _alpha:Float = 100;
	public var _rotation(default, set):Float = 0;
	public var _visible:Bool = true;
	public var _currentframe(default, null):Int = 1;
	public var _totalframes:Int = 1;
	public var removed(default, null):Bool = false;
	public var playing:Bool = false;
	// frame script removeMovieClip() on this frame (0: none): the clip disappears when its playhead reaches it
	public var removeAt:Int = 0;
	// frame script obj.kill() on this frame (0: none: partSpark)
	public var killAt:Int = 0;

	var frames:Array<Texture>;
	// texture pixels per Flash pixel
	var res:Float;
	// position scale of the clip in its parent (the scene itself: 2, see Game)
	public var posK:Float = 1;

	// state of the previous Flash frame (display)
	var fresh:Bool = true;
	var snap:Bool = false;
	// a jump of the picture that shows nothing (a repeating texture moved by its period): added to the state shown
	// before it, see shiftShown
	var shiftX:Float = 0;
	var shiftY:Float = 0;
	var px:Float = 0;
	var py:Float = 0;
	var pxs:Float = 100;
	var pys:Float = 100;
	var pa:Float = 100;
	var pr:Float = 0;

	// res: texture pixels per Flash pixel (pictures of the sheet: 2; containers: 1, their children keep their size)
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
		removed = true;
		for (c in children.copy())
			c.removeMovieClip();
		if (parent != null)
			parent.children.remove(this);
		if (spr.parent != null)
			spr.parent.removeChild(spr);
		spr.destroy({children: true});
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

	// a Flash frame: playing timelines advance before the code runs (nested clips play on their own)
	function advance():Void {
		if (!playing || removed)
			return;
		var f = _currentframe + 1;
		if (removeAt > 0 && f >= removeAt) {
			removeMovieClip();
			return;
		}
		if (f > _totalframes)
			f = 1;
		_currentframe = f;
		if (f == killAt && obj != null) {
			obj.kill();
			return;
		}
		onFrame();
	}

	// the script of the frame the timeline reached
	function onFrame():Void {}

	// ---------------------------------------------------------------- properties
	function set__x(v:Float):Float {
		return _x = twips(v);
	}

	function set__y(v:Float):Float {
		return _y = twips(v);
	}

	// the _rotation setter of Flash: modulo 360, into -180..180
	function set__rotation(v:Float):Float {
		return _rotation = Cs.normRot(v);
	}

	public static inline function twips(v:Float):Float {
		return Std.int(v * 20) / 20;
	}

	// a move made at once (the scene jumping to the ball): shown where it is now, not interpolated
	public function teleport():Void {
		px = _x;
		py = _y;
		pr = _rotation;
		snap = true;
	}

	// the clip jumped by (dx, dy) but looks the same (Game.scrollMap: the background texture repeats every 128 px and
	// its position wraps): the states shown before are moved by the same amount, so that the interpolation goes on
	// the way the picture really moves instead of sliding back across the jump
	public function shiftShown(dx:Float, dy:Float):Void {
		px += dx;
		py += dy;
		shiftX += dx * posK;
		shiftY += dy * posK;
	}

	// ---------------------------------------------------------------- Flash frames and display
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
			m.pa = m._alpha;
			m.pr = m._rotation;
			i++;
		}
		for (m in all.copy())
			m.advance();
	}

	public static function displayAll(f:Float):Void {
		for (m in all)
			if (!m.removed)
				m.display(f);
	}

	function display(f:Float):Void {
		var s = spr;
		// created during the last Flash frame: the picture shown is still before it (f = 1: the start of the game);
		// shown from the next step, not interpolated from where it was created
		var hide = fresh && f < 1;
		if (fresh)
			f = 1;
		s._x = (px + (_x - px) * f) * posK;
		s._y = (py + (_y - py) * f) * posK;
		s._xscale = (pxs + (_xscale - pxs) * f) / res;
		s._yscale = (pys + (_yscale - pys) * f) / res;
		var a = pa + (_alpha - pa) * f;
		s._alpha = a < 0 ? 0 : a > 100 ? 100 : a;
		s._rotation = pr + Cs.hMod(_rotation - pr, 180) * f;
		if (s._prevState != null && (shiftX != 0 || shiftY != 0)) {
			// (the state shown at the last step, in the coordinates before the jump)
			s._prevState.x += shiftX;
			s._prevState.y += shiftY;
		}
		shiftX = shiftY = 0;
		if (snap && s._prevState != null)
			s._prevState.copyFrom(s._curState);
		snap = hide;
		s.visible = _visible && !hide;
		if (frames != null)
			showFrame();
	}

	function showFrame():Void {
		// frames past the pictures: empty frames of the timeline
		var t = _currentframe <= frames.length ? frames[_currentframe - 1] : null;
		if (t == null) {
			spr.renderable = false;
			return;
		}
		spr.renderable = true;
		if (spr.texture != t) {
			spr.texture = t;
			spr.anchor.copyFrom(t.defaultAnchor);
		}
	}

	public static function clearAll():Void {
		for (m in all.copy())
			m.removeMovieClip();
		all = [];
	}
}

// the depths of the original (DepthManager planes): one container per plane, clips drawn in attach order
class Plans {
	public var root:MC;

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

	public function attach(anim:String, plan:Int):MC {
		var mc = new MC(anim);
		mc.playing = mc._totalframes > 1;
		return get(plan).attach(mc);
	}

	public function add<T:MC>(mc:T, plan:Int):T {
		get(plan).attach(mc);
		return mc;
	}

	public function empty(plan:Int):MC {
		return get(plan).attach(new MC());
	}
}
