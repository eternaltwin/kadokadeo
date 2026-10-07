package memopsy;

import pixi.core.textures.Texture;

/**
 * A Flash MovieClip as the original code uses it (Toy Maniak's MC plus the _rotation of Julianus's): _x / _y stored
 * in twips (Flash truncates them to 1/20 px), _rotation kept in -180..180 like Flash's setter, frames chosen by the
 * code or played by the timeline (one frame per Flash frame, looping like a timeline without stop());
 * `frameChanged` runs when the frame changes and `script` runs the frame scripts of the timeline after the playhead
 * moved. A clip created without pictures is a container. A removed clip ignores every call, like a dead Flash
 * reference (Card.main calls flip.nextFrame() right after removing it).
 *
 * Display: Memopsy ran at 40 Flash frames/s and KadoKadeo steps 32 times per second, so a step plays 1 or 2 Flash
 * frames (Game.update). Every clip shows the state one Flash frame ago, interpolated towards the last one by the
 * fraction of a Flash frame the steps are behind (display): the game moves by exactly 1.25 Flash frames per step.
 * A state that jumps (another picture placed elsewhere, a clip attached and sent to its last frame) is shown at
 * once through jump() / the `fresh` flag, never interpolated across the jump. A clip created during the last Flash
 * frame is shown at once too (not hidden until the next one): it replaces a picture that went away at once (the flip
 * in place of a card hidden by the same code), hiding it would leave a hole for one step.
 */
class MC {
	public static var all:Array<MC> = [];

	public var spr:ASprite;
	public var parent:MC;
	public var children:Array<MC> = [];
	// depth in the parent (children are kept in depth order: DepthManager planes)
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

	// button: onPress handler, hand cursor over it, hit area (a function of a point of the clip; with those of its
	// children)
	public var onPress:Void->Void;
	public var useHandCursor:Bool = true;
	public var hitFn:Float->Float->Bool;

	// colour: tint (multiplier of the picture: the flip darkens its card)
	public var tint:Int = 0xFFFFFF;

	var frames:Array<Texture>;
	// texture pixels per Flash pixel
	var res:Float;
	// position scale of the clip in its parent (the scene itself: 2, see Game)
	public var posK:Float = 1;

	// state of the previous Flash frame (display)
	var fresh:Bool = true;
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

	// a timeline without pictures of its own (its frames drive its children, see frameChanged)
	public function setTimeline(n:Int):Void {
		_totalframes = n;
	}

	// ---------------------------------------------------------------- display list
	public function attach<T:MC>(child:T):T {
		var d = children.length == 0 ? 0 : children[children.length - 1].depth + 1;
		return attachAt(child, d);
	}

	// attachMovie at a depth: in depth order, replacing the clip already at that depth (Flash removes it)
	public function attachAt<T:MC>(child:T, d:Int):T {
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

	public function play():Void {
		playing = true;
	}

	public function stop():Void {
		playing = false;
	}

	public function nextFrame():Void {
		playing = false;
		goto(_currentframe + 1);
	}

	public function prevFrame():Void {
		playing = false;
		goto(_currentframe - 1);
	}

	function goto(f:Int):Void {
		// (a removed clip ignores the call, like a dead Flash reference)
		if (removed)
			return;
		var old = _currentframe;
		// (Flash stays inside the timeline when asked for a frame beyond it)
		_currentframe = f < 1 ? 1 : f > _totalframes ? _totalframes : f;
		if (_currentframe != old)
			frameChanged(old);
	}

	// the timeline placed / moved / removed its children (old: the frame before)
	function frameChanged(old:Int):Void {}

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

	// the _rotation setter of Flash: modulo 360, into -180..180
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

	public static inline function twips(v:Float):Float {
		return Std.int(v * 20) / 20;
	}

	// hit area of the clip and its children (the point in the clip's coordinates); hidden clips are not hit
	public function hitTest(x:Float, y:Float):Bool {
		if (!_visible || removed)
			return false;
		if (hitFn != null && hitFn(x, y))
			return true;
		for (c in children)
			if (c.hitTest((x - c._x) * 100 / c._xscale, (y - c._y) * 100 / c._yscale))
				return true;
		return false;
	}

	// ---------------------------------------------------------------- Flash frames and display
	// a change that is not a move (another picture placed elsewhere): shown at once, not interpolated
	public function jump():Void {
		px = _x;
		py = _y;
		pxs = _xscale;
		pys = _yscale;
		pa = _alpha;
		pr = _rotation;
	}

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
			m.jump();
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
		// created during the last Flash frame: shown at once as it is, not interpolated from where it was created
		if (fresh)
			f = 1;
		s._x = (px + (_x - px) * f) * posK;
		s._y = (py + (_y - py) * f) * posK;
		s._xscale = (pxs + (_xscale - pxs) * f) / res;
		s._yscale = (pys + (_yscale - pys) * f) / res;
		var a = pa + (_alpha - pa) * f;
		s._alpha = a < 0 ? 0 : a > 100 ? 100 : a;
		// the shortest way between the two angles (the background turns forever)
		var dr = (_rotation - pr) % 360;
		if (dr > 180)
			dr -= 360;
		else if (dr < -180)
			dr += 360;
		s._rotation = pr + dr * f;
		s.visible = _visible;
		s.tint = tint;
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

	// dmanager.attach(name, plan): the exported symbols are stopped on their frame 1 (the code picks the frames)
	public function attach(anim:String, plan:Int):MC {
		return get(plan).attach(new MC(anim));
	}

	public function add<T:MC>(mc:T, plan:Int):T {
		get(plan).attach(mc);
		return mc;
	}
}
