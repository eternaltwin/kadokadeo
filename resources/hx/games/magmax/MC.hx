package magmax;

import pixi.filters.colormatrix.ColorMatrixFilter;

/**
 * A MovieClip attached by the game code (DepthManager.attach): the Flash properties the code reads and writes
 * (_x / _y truncated to twips like Flash, _xscale, _rotation, _alpha...) and the Clip that draws it.
 *
 * Display: Magmax ran at 40 Flash frames/s and KadoKadeo steps 32 times per second, so a step plays 1 or 2 Flash
 * frames (Game.update). Showing the last Flash frame of each step would make everything jerk (1, 1, 1, 2 frames
 * per step); like Linea, every clip shows its state one Flash frame ago, interpolated towards the last one by the
 * fraction of a Flash frame the steps are behind (displayAll): the game moves by exactly 1.25 Flash frames per step.
 * The pictures of the timelines are the current ones.
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

	var colorFilter:ColorMatrixFilter;

	public function new(name:String) {
		setClip(name);
		all.push(this);
	}

	// the clip drawing it (another baked variant: the same frame, the same place in the display list)
	public function setClip(name:String):Void {
		var old = clip;
		clip = new Clip(name);
		clip.owner = this;
		if (old != null) {
			// the same frame and the same playhead state (a shot stopped on its frame stays stopped)
			if (old.playing())
				clip.gotoAndPlay(old.frame);
			else
				clip.gotoAndStop(old.frame);
			var p = old.parent;
			if (p != null) {
				p.addChildAt(clip, p.getChildIndex(old));
				old.removeMovieClip();
			}
			old.destroy({children: true});
			if (colorFilter != null)
				clip.filters = [colorFilter];
		}
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

	public function gotoAndStop(f:Int):Void {
		clip.gotoAndStop(f);
	}

	public function removeMovieClip():Void {
		if (removed)
			return;
		removed = true;
		clip.removeMovieClip();
		clip.destroy({children: true});
	}

	// Color.setTransform({ra: 100, rb: r, ga: 100, gb: g, ba: 100, bb: b, aa: 100, ab: 0}): colour offsets added to
	// every pixel (Flash: on the unpremultiplied colour, clamped), 0 = reset
	public function setColorOffset(r:Int, g:Int, b:Int):Void {
		if (r == 0 && g == 0 && b == 0) {
			if (colorFilter != null) {
				clip.filters = null;
				colorFilter = null;
			}
			return;
		}
		if (colorFilter == null) {
			colorFilter = new ColorMatrixFilter();
			clip.filters = [colorFilter];
		}
		colorFilter.matrix = [1, 0, 0, 0, r / 255, 0, 1, 0, 0, g / 255, 0, 0, 1, 0, b / 255, 0, 0, 0, 1, 0];
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

// the planes of the original DepthManager: one container per plane, the clips in their depth order
class Plans {
	var root:ASprite;
	var plans:Array<ASprite> = [];
	var lists:Array<Array<MC>> = [];

	public function new(root:ASprite) {
		this.root = root;
	}

	function get(plan:Int):ASprite {
		while (plans.length <= plan) {
			plans.push(null);
			lists.push(null);
		}
		if (plans[plan] == null) {
			var p = new ASprite();
			var at = 0;
			for (i in 0...plan)
				if (plans[i] != null)
					at = root.getChildIndex(plans[i]) + 1;
			root.addChildAt(p, at);
			plans[plan] = p;
			lists[plan] = [];
		}
		return plans[plan];
	}

	public function attach<T:MC>(mc:T, plan:Int):T {
		get(plan).addChild(mc.clip);
		lists[plan].push(mc);
		return mc;
	}

	// DepthManager.compact: the removed clips leave the list (the others keep their order)
	public function compact(plan:Int):Void {
		get(plan);
		var l = lists[plan];
		var i = 0;
		while (i < l.length) {
			if (l[i].removed)
				l.splice(i, 1);
			else
				i++;
		}
	}

	// DepthManager.ysort of the original (as compiled in gaunt.swf): an insertion sort on _y swapping depths; ymax
	// is not raised after an element moved
	public function ysort(plan:Int):Void {
		get(plan);
		var l = lists[plan];
		var ymax = -99999999.0;
		var changed = false;
		for (i in 0...l.length) {
			var mc = l[i];
			var y = mc._y;
			if (y >= ymax) {
				ymax = y;
			} else {
				var j = i;
				while (j > 0) {
					var mc2 = l[j - 1];
					if (mc2._y <= y) {
						l[j] = mc;
						break;
					}
					l[j] = mc2;
					changed = true;
					j--;
				}
				if (j == 0)
					l[0] = mc;
			}
		}
		if (changed) {
			var p = plans[plan];
			var k = 0;
			for (mc in l)
				if (!mc.removed && mc.clip.parent == p)
					p.setChildIndex(mc.clip, k++);
		}
	}
}
