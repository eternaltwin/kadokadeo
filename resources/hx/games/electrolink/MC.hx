package electrolink;

import pixi.core.Pixi.BlendModes;
import pixi.core.textures.Texture;

/**
 * A Flash MovieClip as the original code uses it: _x / _y stored in twips (Flash truncates them to 1/20 px), scales,
 * alpha and rotation as in Flash, frames chosen by the code or played by the timeline (one frame per Flash frame,
 * looping like a timeline without stop()). A clip created without a sprite only has a timeline: the nested clips
 * the code drives (mc.smc.smc...) whose pictures are drawn by their parent.
 *
 * Display: Electrolink ran at 40 Flash frames/s and KadoKadeo steps 32 times per second, so a step plays 1 or 2
 * Flash frames (Game.update). Every clip shows the state one Flash frame ago, interpolated towards the last one by
 * the fraction of a Flash frame the steps are behind (display): the game moves by exactly 1.25 Flash frames per step
 * (the method of Linea).
 */
class MC {
	public static var all:Array<MC> = [];

	public var spr:ASprite;
	public var parent:MC;
	public var children:Array<MC> = [];
	// DepthManager plan of the clip (Plans), -1 out of a plan
	public var plan:Int = -1;

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

	// button handlers (Buttons calls them like the Flash player)
	public var onPress:Void->Void;
	public var onRollOver:Void->Void;
	public var onRollOut:Void->Void;

	// Col.setColor on a white picture: a flat colour
	public var tint:Int = 0xFFFFFF;
	// blendMode "add"
	public var add:Bool = false;

	var frames:Array<Texture>;
	// texture pixels per Flash pixel
	var res:Float;
	// position scale of the clip in its parent (the scene itself: 2, see Game)
	public var posK:Float = 1;

	// state of the previous Flash frame (display)
	var fresh:Bool = true;
	var snap:Bool = false;
	// placed out of the screen until its first update (Sprite.new): its first real position is not interpolated
	public var placeholder:Bool = false;
	var px:Float = 0;
	var py:Float = 0;
	var pxs:Float = 100;
	var pys:Float = 100;
	var pa:Float = 100;
	var pr:Float = 0;

	// anim: pictures of the sheet; res: texture pixels per Flash pixel (pictures of the sheet: 2; containers: 1, their
	// children keep their size); timeline: a clip without a sprite (only its frames)
	public function new(?anim:String, ?res:Float, ?timeline:Int) {
		this.res = res != null ? res : anim != null ? Game.K : 1;
		if (timeline != null) {
			_totalframes = timeline;
		} else {
			spr = new ASprite();
			if (anim != null)
				setFrames(anim);
		}
		all.push(this);
	}

	public function setFrames(anim:String):Void {
		frames = Tex.get(anim);
		_totalframes = frames.length;
		spr.texture = frames[_currentframe - 1];
		spr.anchor.copyFrom(spr.texture.defaultAnchor);
	}

	// ---------------------------------------------------------------- display list
	public function attach(child:MC):MC {
		child.parent = this;
		children.push(child);
		if (child.spr != null)
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
		if (spr != null) {
			if (spr.parent != null)
				spr.parent.removeChild(spr);
			spr.destroy({children: true});
		}
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

	// a Flash frame: playing timelines advance before the code runs (nested clips play on their own)
	function advance():Void {
		if (playing && _totalframes > 1)
			goto(_currentframe == _totalframes ? 1 : _currentframe + 1);
	}

	// ---------------------------------------------------------------- properties
	function set__x(v:Float):Float {
		return _x = twips(v);
	}

	function set__y(v:Float):Float {
		return _y = twips(v);
	}

	// Flash keeps the rotation in ]-180, 180]
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

	// hit area of a button (the shapes of the clip), in the coordinates of its parent
	public function hitTest(x:Float, y:Float):Bool {
		return false;
	}

	public function setColor(col:Int):Void {
		tint = col;
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
		// (a copy: a frame script can create clips)
		for (m in all.copy())
			if (!m.removed)
				m.advance();
	}

	public static function displayAll(f:Float):Void {
		for (m in all)
			if (!m.removed && m.spr != null)
				m.display(f);
	}

	function display(f:Float):Void {
		var s = spr;
		// created during the last Flash frame: the picture shown is still before it (f = 1: the start of the game);
		// shown from the next step, not interpolated from where it was created
		var hide = fresh && f < 1;
		if (fresh)
			f = 1;
		// the first picture at its real position: shown there at once (Flash drew it at (-100, -100) the frame
		// before, out of the screen), not sliding from the corner
		var jump = placeholder && !fresh;
		if (jump) {
			placeholder = false;
			f = 1;
		}
		s._x = (px + (_x - px) * f) * posK;
		s._y = (py + (_y - py) * f) * posK;
		s._xscale = (pxs + (_xscale - pxs) * f) / res;
		s._yscale = (pys + (_yscale - pys) * f) / res;
		var a = pa + (_alpha - pa) * f;
		s._alpha = a < 0 ? 0 : a > 100 ? 100 : a;
		var dr = ((_rotation - pr + 180) % 360 + 360) % 360 - 180;
		s._rotation = pr + dr * f;
		if (jump)
			s.updateState();
		else if (snap && s._prevState != null)
			s._prevState.copyFrom(s._curState);
		snap = hide;
		s.visible = _visible && !hide;
		s.tint = tint;
		var bm = add ? BlendModes.ADD : BlendModes.NORMAL;
		if (s.blendMode != bm)
			s.blendMode = bm;
		if (frames != null)
			showFrame();
		drawn(f);
	}

	// pictures of the clip that depend on its nested clips (overridden)
	function drawn(f:Float):Void {}

	function showFrame():Void {
		var t = frames[_currentframe - 1];
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

// the depths of the original (mt.DepthManager): one container per plan, clips drawn in the order they were attached
// or swapped into the plan
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

	public function attach(anim:String, plan:Int):MC {
		var mc = new MC(anim);
		mc.playing = mc._totalframes > 1;
		return add(mc, plan);
	}

	public function add<T:MC>(mc:T, plan:Int):T {
		get(plan).attach(mc);
		mc.plan = plan;
		return mc;
	}

	// DepthManager.swap: to the top of another plan (nothing when the clip is already in it)
	public function swap(mc:MC, plan:Int):Void {
		if (mc.plan == plan || mc.removed)
			return;
		var from = get(mc.plan);
		from.children.remove(mc);
		from.spr.removeChild(mc.spr);
		mc.parent = null;
		add(mc, plan);
	}

	// clips of a plan, from the top one (mouse: the button on top receives the events)
	public function topDown(plan:Int):Array<MC> {
		if (plan >= plans.length || plans[plan] == null)
			return [];
		var l = plans[plan].children.copy();
		l.reverse();
		return l;
	}
}
