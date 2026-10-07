package hypercube;

import pixi.core.Pixi.BlendModes;
import pixi.core.textures.Texture;

/**
 * A Flash MovieClip as the original code uses it: _x / _y stored in twips (Flash truncates them to 1/20 px), _alpha
 * stored in 1/256 (Flash truncates it: `_alpha += 1` from 0 gives 0.78125, then 1.5625...), scales and rotation as in
 * Flash, frames chosen by the code or played by the timeline (one frame per Flash frame, looping like a timeline
 * without stop()); `script` runs the frame scripts of the timeline after the playhead moved. A clip created without
 * pictures is a container (DepthManager plans, Piece roots...).
 *
 * Display (the MC of Electrolink): Hypercube ran at 40 Flash frames/s and KadoKadeo steps 32 times per second, so a
 * step plays 1 or 2 Flash frames (Game.update). Every clip shows the state one Flash frame ago, interpolated towards
 * the last one by the fraction of a Flash frame the steps are behind (display): the game moves by exactly 1.25 Flash
 * frames per step.
 */
class MC {
	public static var all:Array<MC> = [];

	public var spr:ASprite;
	public var parent:MC;
	public var children:Array<MC> = [];
	// depth in the parent (children are kept in depth order: Std.attachMC, DepthManager)
	public var depth:Int = 0;

	public var _x(default, set):Float = 0;
	public var _y(default, set):Float = 0;
	public var _xscale:Float = 100;
	public var _yscale:Float = 100;
	public var _alpha(default, set):Float = 100;
	public var _rotation(default, set):Float = 0;
	public var _visible:Bool = true;
	public var _currentframe(default, null):Int = 1;
	public var _totalframes(default, null):Int = 1;
	public var removed(default, null):Bool = false;
	public var playing:Bool = false;
	// frame scripts of the timeline (after the playhead moved: the new frame)
	public var script:Int->Void;

	// button: onPress handler and hit area (rectangles xmin, xmax, ymin, ymax in the clip, with those of its children)
	public var onPress:Void->Void;
	public var hitRects:Array<Array<Float>>;
	// a Flash Button (its up / over / down frames are shown by Buttons)
	public var isButton:Bool = false;

	// colour: tint (multiplier of the picture) and blendMode "add"
	public var tint:Int = 0xFFFFFF;
	public var add:Bool = false;

	var frames:Array<Texture>;
	// texture pixels per Flash pixel
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
	var pr:Float = 0;

	// anim: pictures of the sheet; res: texture pixels per Flash pixel (pictures of the sheet: 2; containers: 1, their
	// children keep their size)
	public function new(?anim:String, ?res:Float) {
		this.res = res != null ? res : anim != null ? Game.K : 1;
		spr = new ASprite();
		if (anim != null)
			setFrames(anim);
		all.push(this);
	}

	public function setFrames(anim:String):Void {
		frames = Tex.get(anim);
		_totalframes = frames.length;
		if (_currentframe > _totalframes)
			_currentframe = _totalframes;
		spr.texture = frames[_currentframe - 1];
		spr.anchor.copyFrom(spr.texture.defaultAnchor);
	}

	// a timeline without pictures of its own (its frames drive its children, see script)
	public function setTimeline(n:Int):Void {
		_totalframes = n;
	}

	// ---------------------------------------------------------------- display list
	public function attach(child:MC):MC {
		var d = children.length == 0 ? 0 : children[children.length - 1].depth + 1;
		return attachAt(child, d);
	}

	// attachMovie at a depth: in depth order, replacing the clip already at that depth (Flash removes it)
	public function attachAt(child:MC, d:Int):MC {
		var i = 0;
		while (i < children.length && children[i].depth < d)
			i++;
		if (i < children.length && children[i].depth == d)
			children[i].removeMovieClip();
		child.parent = this;
		child.depth = d;
		children.insert(i, child);
		spr.addChildAt(child.spr, i);
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
		goto(f);
	}

	public function gotoAndPlay(f:Int):Void {
		playing = true;
		goto(f);
	}

	function goto(f:Int):Void {
		_currentframe = f < 1 ? 1 : f > _totalframes ? _totalframes : f;
	}

	public function play():Void {
		playing = true;
	}

	public function stop():Void {
		playing = false;
	}

	// a Flash frame: playing timelines advance, then their frame scripts run
	function advance():Void {
		if (playing && _totalframes > 1) {
			goto(_currentframe == _totalframes ? 1 : _currentframe + 1);
			if (script != null)
				script(_currentframe);
		}
	}

	// ---------------------------------------------------------------- properties
	function set__x(v:Float):Float {
		// (Flash ignores a NaN: the clip stays where it is)
		return Math.isNaN(v) ? _x : _x = twips(v);
	}

	function set__y(v:Float):Float {
		return Math.isNaN(v) ? _y : _y = twips(v);
	}

	function set__alpha(v:Float):Float {
		return Math.isNaN(v) ? _alpha : _alpha = Std.int(v * 2.56) / 2.56;
	}

	// Flash keeps the rotation in ]-180, 180]
	function set__rotation(v:Float):Float {
		if (Math.isNaN(v))
			return _rotation;
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

	// hit area of the clip and its children (the point in the clip's coordinates); hidden clips are not hit
	public function hitTest(x:Float, y:Float):Bool {
		if (!_visible || removed)
			return false;
		if (hitRects != null)
			for (r in hitRects)
				if (x >= r[0] && x <= r[1] && y >= r[2] && y <= r[3])
					return true;
		for (c in children)
			if (c.hitTest((x - c._x) * 100 / c._xscale, (y - c._y) * 100 / c._yscale))
				return true;
		return false;
	}

	// Color.setTransform (multiplier m of r, g, b, offsets in 0..255): on a white picture (the time ring) it is exactly a
	// tint; the cubes override it (Gfx.Cube)
	public function setColorTransform(m:Float, rb:Int, gb:Int, bb:Int):Void {
		inline function ch(o:Int):Int {
			var v = Math.round(255 * m + o);
			return v < 0 ? 0 : v > 255 ? 255 : v;
		}
		tint = ch(rb) << 16 | ch(gb) << 8 | ch(bb);
	}

	// ---------------------------------------------------------------- Flash frames and display
	// the state shown during the next Flash frame (display): taken before the frame changes anything
	public static function snapshotAll():Void {
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
	}

	public static function advanceAll():Void {
		// (a copy: a frame script can remove clips)
		for (m in all.copy())
			if (!m.removed)
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
		var dr = ((_rotation - pr + 180) % 360 + 360) % 360 - 180;
		s._rotation = pr + dr * f;
		if (snap && s._prevState != null)
			s._prevState.copyFrom(s._curState);
		snap = hide;
		s.visible = _visible && !hide;
		s.tint = tint;
		var bm = add ? BlendModes.ADD : BlendModes.NORMAL;
		if (s.blendMode != bm)
			s.blendMode = bm;
		if (frames != null) {
			var t = frames[_currentframe - 1];
			if (s.texture != t) {
				s.texture = t;
				s.anchor.copyFrom(t.defaultAnchor);
			}
		}
	}

	public static function clearAll():Void {
		for (m in all.copy())
			m.removeMovieClip();
		all = [];
	}
}

// the depths of the original (mt.DepthManager): one container per plan, clips drawn in the order they were attached
class Plans {
	var root:MC;
	var plans:Array<MC> = [];

	public function new(root:MC) {
		this.root = root;
	}

	public function get(plan:Int):MC {
		var p = plans[plan];
		if (p == null) {
			p = new MC();
			root.attachAt(p, plan);
			plans[plan] = p;
		}
		return p;
	}

	public function attach(anim:String, plan:Int):MC {
		var mc = new MC(anim);
		mc.playing = mc._totalframes > 1;
		return add(mc, plan);
	}

	public function add<T:MC>(mc:T, plan:Int):T {
		get(plan).attach(mc);
		return mc;
	}

	// DepthManager.empty
	public function empty(plan:Int):MC {
		return add(new MC(), plan);
	}
}
