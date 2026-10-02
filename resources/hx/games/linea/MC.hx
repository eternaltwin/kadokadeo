package linea;

import pixi.core.textures.Texture;
import pixi.filters.blur.BlurFilter;

/**
 * A Flash MovieClip as the original code uses it: _x / _y stored in twips (Flash truncates them to 1/20 px, and
 * the collisions read them back), scales and alpha in percent, frames chosen by the code or played by the timeline
 * (one frame per Flash frame, looping like a timeline without stop()).
 *
 * Display: Linea ran at 40 Flash frames/s and KadoKadeo steps 32 times per second, so a step plays 1 or 2 Flash
 * frames (Game.update). Showing the last Flash frame of each step would make the scroll jerk (1, 1, 1, 2 frames
 * per step); instead every clip shows the state one Flash frame ago, interpolated towards the last one by the
 * fraction of a Flash frame the steps are behind (display): the game moves by exactly 1.25 Flash frames per step.
 */
class MC {
	public static var all:Array<MC> = [];

	public var spr:ASprite;
	public var parent:MC;
	public var children:Array<MC> = [];
	public var name:String;
	public var obj:Sprite;

	public var _x(default, set):Float = 0;
	public var _y(default, set):Float = 0;
	public var _xscale:Float = 100;
	public var _yscale:Float = 100;
	public var _alpha:Float = 100;
	public var _rotation:Float = 0;
	public var _visible:Bool = true;
	public var _currentframe(default, null):Int = 1;
	public var _totalframes(default, null):Int = 1;
	public var _width(get, never):Float;
	public var _height(get, never):Float;
	public var removed(default, null):Bool = false;

	// Flash colour transform, for the white pictures it is used on: a flat colour (see setColor)
	public var tint:Int = 0xFFFFFF;
	// fields Game.fxFlash puts on the clip
	public var _flhPrc:Float;
	public var _flhCoef:Float;
	public var _flhCol:Int;

	// symbol size at 100 % (the _width / _height the code reads; measured in the SWF, see Data)
	var w:Float = 0;
	var h:Float = 0;
	var frames:Array<Texture>;
	public var playing:Bool = false;
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

	var blurs:Float = 0;
	var blurFilter:BlurFilter;

	// res: texture pixels per Flash pixel (pictures of the sheet: 2; containers: 1, their children keep their size)
	public function new(?anim:String, ?res:Float) {
		spr = new ASprite();
		this.res = res != null ? res : anim != null ? Game.K : 1;
		if (anim != null)
			setFrames(anim);
		all.push(this);
	}

	// the pictures of the clip (the same clip under another colour transform: another baked picture)
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

	public function play():Void {
		playing = true;
	}

	public function stop():Void {
		playing = false;
	}

	// a Flash frame: playing timelines advance before the code runs (nested clips play on their own)
	function advance():Void {
		if (playing && _totalframes > 1)
			_currentframe = _currentframe == _totalframes ? 1 : _currentframe + 1;
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

	function get__width():Float {
		return w * Math.abs(_xscale) / 100;
	}

	function get__height():Float {
		return h * Math.abs(_yscale) / 100;
	}

	public function setSize(w:Float, h:Float):Void {
		this.w = w;
		this.h = h;
	}

	// Col.setColor: offset col - 255 on each channel: a white picture becomes col
	public function setColor(col:Int):Void {
		tint = col;
	}

	// Col.setPercentColor(mc, prc, col): multipliers int(100 - prc) %, offsets int(prc / 100 * channel), replacing the
	// previous transform (Flash Color.setTransform): on a white picture, a flat colour
	public function setPercentColor(prc:Float, col:Int):Void {
		var m = Std.int(100 - prc);
		var c = prc / 100;
		inline function ch(v:Int):Int {
			var r = Std.int(255 * m / 100 + Std.int(c * v));
			return r < 0 ? 0 : r > 255 ? 255 : r;
		}
		tint = (ch((col >> 16) & 0xFF) << 16) | (ch((col >> 8) & 0xFF) << 8) | ch(col & 0xFF);
	}

	// Filt.blur(mc, n, 0) of the original pushes one more horizontal box blur on the clip each call: they pile up,
	// drawn as one blur of the same spread
	public function addBlur(n:Float):Void {
		blurs += n * n;
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
			i++;
		}
		for (m in all)
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
		s._rotation = _rotation;
		if (snap && s._prevState != null)
			s._prevState.copyFrom(s._curState);
		snap = hide;
		s.visible = _visible && !hide;
		s.tint = tint;
		if (frames != null)
			showFrame();
		if (blurs > 0) {
			if (blurFilter == null) {
				blurFilter = new BlurFilter();
				untyped blurFilter.quality = 2;
				blurFilter.blurY = 0;
				s.filters = [blurFilter];
			}
			// a box blur of width n has a deviation n / sqrt(12); PIXI's 5 taps one blurX apart: about blurX
			blurFilter.blurX = Math.sqrt(blurs / 12) * Game.K;
		}
	}

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
