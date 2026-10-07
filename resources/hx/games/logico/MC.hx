package logico;

import pixi.core.textures.Texture;

/**
 * A Flash MovieClip as the original code uses it: _x / _y stored in twips (Flash truncates them to 1/20 px), scales
 * and alpha in percent, rotation in ]-180, 180], frames chosen by the code or played by the timeline (one frame per
 * Flash frame, looping: the clips of Logico have no frame script the code depends on).
 *
 * Display (the MC of the Linea, Hexile and Klinker Surprise ports): Logico ran at 40 Flash frames/s and KadoKadeo
 * steps 32 times per second, so a step plays 1 or 2 Flash frames (Game.update). Every clip shows the state one Flash
 * frame ago, interpolated towards the last one by the fraction of a Flash frame the steps are behind (display): the
 * game moves by exactly 1.25 Flash frames per step. For the same reason a clip removed by the code stays on screen,
 * frozen, until the display reaches the Flash frame it was removed in (a ball that bursts is shown until its pieces
 * are), and a clip created in the last Flash frame is not shown before it.
 */
class MC {
	public static var all:Array<MC> = [];
	// removed by the code, still shown until the display reaches the Flash frame they were removed in
	static var dying:Array<MC> = [];

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

	// button handlers (Buttons calls them like the Flash player); hitR: radius of the hit area (a disc on the origin)
	public var onPress:Void->Void;
	public var onRollOver:Void->Void;
	public var onRollOut:Void->Void;
	public var onDragOut:Void->Void;
	public var useHandCursor:Bool = false;
	public var hitR:Float = 0;

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
	var pr:Float = 0;

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
		onPress = onRollOver = onRollOut = onDragOut = null;
		for (c in children)
			c.markRemoved();
	}

	// ---------------------------------------------------------------- timeline
	public function gotoAndStop(f:Int):Void {
		playing = false;
		goto(f);
	}

	public function gotoAndPlay(f:Int):Void {
		goto(f);
		playing = true;
	}

	public function play():Void {
		playing = true;
	}

	function goto(f:Int):Void {
		_currentframe = f < 1 ? 1 : f > _totalframes ? _totalframes : f;
	}

	// a Flash frame: playing timelines advance before the code runs (nested clips play on their own)
	function advance():Void {
		if (playing && !removed && _totalframes > 1)
			goto(_currentframe == _totalframes ? 1 : _currentframe + 1);
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

	// Flash keeps the rotation in ]-180, 180]
	function set__rotation(v:Float):Float {
		v = v % 360;
		if (v > 180)
			v -= 360;
		else if (v <= -180)
			v += 360;
		return _rotation = v;
	}

	// a move made at once (a clip placed for the first time): not interpolated
	public function teleport(x:Float, y:Float):Void {
		_x = x;
		_y = y;
		px = _x;
		py = _y;
		snap = true;
	}

	// hit area of a button, in the coordinates of its parent
	public function hitTest(x:Float, y:Float):Bool {
		var dx = x - _x, dy = y - _y;
		return dx * dx + dy * dy <= hitR * hitR;
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
		if (frames != null)
			showFrame();
		drawn(f);
	}

	// pictures of the clip that depend on more than its frame (overridden)
	function drawn(f:Float):Void {}

	function showFrame():Void {
		setTexture(frames[_currentframe - 1]);
	}

	function setTexture(t:Texture):Void {
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

// the depths of the original (mt.DepthManager): one container per plan, clips drawn in the order they were attached
// or brought over the others
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
		return add(new MC(anim), plan);
	}

	public function add<T:MC>(mc:T, plan:Int):T {
		get(plan).attach(mc);
		mc.plan = plan;
		return mc;
	}

	public function empty(plan:Int):MC {
		return add(new MC(), plan);
	}

	// DepthManager.over: to the top of its plan
	public function over(mc:MC):Void {
		if (mc.removed || mc.plan < 0)
			return;
		var p = get(mc.plan);
		p.children.remove(mc);
		p.children.push(mc);
		p.spr.removeChild(mc.spr);
		p.spr.addChild(mc.spr);
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
