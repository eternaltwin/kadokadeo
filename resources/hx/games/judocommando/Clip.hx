package judocommando;

import common_haxe_avm1.display.ASprite.TransformState;
import pixi.core.textures.Texture;

// One layer of a clip (written by the asset pipeline, tools/clipexport.py):
//  k: 0 flattened images (one per frame) / 1 image moved by a matrix / 2 nested clip / 3 mask / 4 marker (an invisible
//     clip whose position the code reads: hm, [_x, _y, _rotation] of each frame, null where it is absent)
//  a: animation (k 0, 1, 3) or clip (k 2) name
//  t: image of each frame (0: layer absent) / p: placement of each frame for nested clips (0: absent, new value: new instance)
//  m / m0: [x, y, scaleX, scaleY, rotation (deg), skewX, skewY] of each frame / of all the frames
//  al / al0: alpha, tn / tns: multiplied colour
//  nm: instance name, mk: layer masking this one
typedef LayerDef = {
	k:Int,
	?a:String,
	?t:Array<Int>,
	?p:Array<Int>,
	?m:Array<Array<Float>>,
	?m0:Array<Float>,
	?al:Array<Float>,
	?al0:Float,
	?tn:Int,
	?tns:Array<Int>,
	?nm:String,
	?mk:Int,
	?hm:Array<Array<Float>>
};

// n: frames, r: resolution of the textures (1 = 2 px per Flash pixel), start / still: frozen on a frame
typedef ClipDef = {
	n:Int,
	r:Float,
	layers:Array<LayerDef>,
	?acts:Dynamic,
	?labels:Dynamic,
	?start:Int,
	?still:Int,
	// built at load time
	?act:Array<Array<Array<Dynamic>>>,
	?lab:Map<String, Int>,
	?simple:Bool
};

// image of a layer (flattened frames or a single shape)
class Gfx extends ASprite {
	public var frames(default, null):Array<Texture>;

	// _visible = false set by the game code on this instance
	public var hidden:Bool = false;

	public function new(anim:String) {
		super();
		frames = Tex.get(anim);
		texture = frames[0];
		anchor.copyFrom(frames[0].defaultAnchor);
		_totalframes = frames.length;
		// pixel art: drawn on whole pixels of the canvas (the textures are sampled without smoothing)
		untyped this.roundPixels = true;
	}

	public inline function show(i:Int) {
		var t = frames[i - 1];
		if (texture != t)
			texture = t;
	}

	override public function updateGraphics(a:Float) {
		Clip.noFlipLerp(this);
		super.updateGraphics(a);
	}
}

/**
 * Flash MovieClip replayed from the exported timeline tables (kslash.Clip, schizofuzz.Clip): nested clips keep their
 * own playhead, frame scripts (stop / play / goto / a few custom ones) run like in the Flash player.
 *
 * Judo Commando ran at 40 Flash frames per second (the rate of the SWF): the playheads do not move with the steps of
 * KadoKadeo (32 per second) but with the Flash frames the game plays (Game.update calls MC.frameStart, which ticks
 * every clip). The playheads are part of the game state: the code reads the markers hold / center of the
 * animations of the hero, whose position changes with their frame.
 */
class Clip extends ASprite {
	public static inline var K = 2;

	static var defs:Map<String, ClipDef> = new Map();
	static var removed:Array<Clip> = [];
	static var parts:Array<Clip> = [];

	public var def(default, null):ClipDef;
	public var clipName(default, null):String;
	public var frame(default, null):Int;

	// the MC moved by the game code, for a top level clip
	public var owner:MC;

	// removed by a frame script (removeMovieClip, obj.kill()): taken out by flushRemoved
	public var selfRemoved(default, null):Bool = false;

	public var frozen:Bool;

	// variables set on the clip by the code (Mon.setType: _hfr, _bfr, _gfr on root.smc; Hero: _afr on root), read
	// by the frame scripts of the head / body / gun of the soldiers and of the monster in the arm lock
	public var vars:Map<String, Int>;

	var pendingStart:Bool = false;

	// a top level clip is in Flash pixels: _xscale / _yscale 100 = textures at their resolution
	public var baseScale(default, null):Float;

	var objs:Array<ASprite>;
	var pids:Array<Int>;
	var deadPid:Array<Int>;
	var tintIn:Int;
	var simpleFrames:Array<Texture>;

	public static function getDef(name:String):ClipDef {
		var d = defs.get(name);
		if (d == null) {
			d = Reflect.field(Data.clips(), name);
			if (d == null)
				throw 'unknown clip ' + name;
			d.act = [for (i in 0...d.n + 1) null];
			if (d.acts != null)
				for (k in Reflect.fields(d.acts))
					d.act[Std.parseInt(k)] = Reflect.field(d.acts, k);
			d.lab = new Map();
			if (d.labels != null)
				for (k in Reflect.fields(d.labels))
					d.lab.set(k, Reflect.field(d.labels, k));
			d.simple = d.layers.length == 1 && d.layers[0].k == 0;
			defs.set(name, d);
		}
		return d;
	}

	// pxPerUnit: pixels of the parent per Flash pixel (1 in the game, 0 = nested clip placed by its parent)
	public function new(name:String, ?pxPerUnit:Float = 1, ?tint:Int = 0xFFFFFF) {
		super();
		def = getDef(name);
		clipName = name;
		_name = name;
		_totalframes = def.n;
		frozen = false;
		tintIn = tint;
		baseScale = pxPerUnit > 0 ? pxPerUnit / (K * def.r) : 1;
		objs = [];
		pids = [];
		deadPid = [];
		if (def.simple) {
			simpleFrames = Tex.get(def.layers[0].a);
			anchor.copyFrom(simpleFrames[0].defaultAnchor);
			this.tint = tintIn;
			untyped this.roundPixels = true;
		}
		if (baseScale != 1) {
			_xscale = 100;
			_yscale = 100;
		}
		frame = 0;
		var f = def.start != null ? def.start : 1;
		isPlaying = def.still == null;
		display(f);
		// a clip placed by the timeline of its parent runs the script of its first frame once placed (Flash: the
		// instance gets its matrix, then its actions run)
		if (pxPerUnit > 0)
			runActions(f, 0);
		else
			pendingStart = true;
	}

	// placed by its parent: first frame actions
	function start() {
		if (pendingStart) {
			pendingStart = false;
			runActions(frame, 0);
		}
	}

	// A scale that changes its sign is a flip: in Flash it is instant, interpolated between two steps it would show
	// the picture squeezed flat
	public static inline function noFlipLerp(s:ASprite) {
		var p = s._prevState;
		if (p != null) {
			var c = s._curState;
			if (p.xscale * c.xscale < 0)
				p.xscale = c.xscale;
			if (p.yscale * c.yscale < 0)
				p.yscale = c.yscale;
		}
	}

	override public function updateGraphics(a:Float) {
		noFlipLerp(this);
		super.updateGraphics(a);
	}

	// clips that removed themselves (frame script) since the last call
	public static function flushRemoved() {
		var l = removed;
		removed = [];
		for (c in l) {
			if (c.owner != null) {
				// obj.kill(): the Sprite of the clip dies (removed from the sprite list and from the display)
				if (c.killObj && c.owner.obj != null)
					c.owner.obj.kill();
				else
					c.owner.removeMovieClip();
			} else
				c.removeMovieClip();
		}
	}

	// the frame scripts of the parts that read a variable of a parent (Flash runs the first frame scripts of the clips
	// the code creates once the code of the frame is over: Mon.setType sets _hfr after attaching the monster)
	public static function flushParts() {
		var l = parts;
		parts = [];
		for (c in l)
			if (!c.selfRemoved && c.parent != null)
				c.readVar();
	}

	public static function reset() {
		removed = [];
		parts = [];
	}

	override public function get__xscale():Float {
		return _curState.xscale * 100 / baseScale;
	}

	override public function set__xscale(v:Float) {
		_curState.xscale = v / 100 * baseScale;
		return v;
	}

	override public function get__yscale():Float {
		return _curState.yscale * 100 / baseScale;
	}

	override public function set__yscale(v:Float) {
		_curState.yscale = v / 100 * baseScale;
		return v;
	}

	// ---------------------------------------------------------------- playhead
	// a step of KadoKadeo: only the state shown before it is kept for the interpolation (the playheads move in tick)
	override public function update() {
		if (_prevState == null)
			_prevState = new TransformState(this);
		_prevState.copyFrom(_curState);
		for (c in children)
			if (Std.isOfType(c, ASprite))
				(cast c : ASprite).update();
	}

	// a Flash frame: the nested clips advance, then this one (playheads move before the code runs)
	public function tick() {
		if (frozen || selfRemoved)
			return;
		var l = children.copy();
		for (c in l) {
			var cc = Std.downcast(c, Clip);
			if (cc != null && cc.parent == this)
				cc.tick();
		}
		if (isPlaying)
			advance();
	}

	function advance() {
		// a timeline of one frame does not run its frame script again
		if (def.n == 1)
			return;
		var f = frame + 1;
		if (f > def.n)
			f = 1;
		display(f);
		runActions(f, 0);
	}

	// Flash nextFrame(): the next frame, stopped (the last frame stays)
	public function stepFrame() {
		goto(frame + 1, false);
	}

	override public function play() {
		if (def.still == null)
			isPlaying = true;
	}

	override public function stop() {
		isPlaying = false;
	}

	public inline function playing():Bool {
		return isPlaying;
	}

	override public function gotoAndStop(f:Dynamic) {
		var n = resolve(f);
		if (n != null)
			goto(n, false);
	}

	override public function gotoAndPlay(f:Dynamic) {
		var n = resolve(f);
		if (n != null)
			goto(n, true);
	}

	// Flash: a number (or a string holding one) is a frame, another string a label; an unknown label does nothing
	public function resolve(f:Dynamic):Null<Int> {
		if (Std.isOfType(f, Int))
			return f;
		var s:String = Std.string(f);
		var n = Std.parseInt(s);
		if (n != null)
			return n;
		return def.lab.exists(s) ? def.lab.get(s) : null;
	}

	function goto(f:Int, play:Bool) {
		// Flash: a frame past the end is the last frame
		if (f < 1)
			f = 1;
		if (f > def.n)
			f = def.n;
		isPlaying = play && def.still == null;
		if (f == frame)
			return;
		display(f);
		runActions(f, 0);
	}

	function runActions(f:Int, depth:Int) {
		var acts = def.act[f];
		if (acts == null || depth > 8)
			return;
		for (a in acts) {
			switch (a[0]) {
				case "s":
					isPlaying = false;
				case "p":
					isPlaying = def.still == null;
				case "g":
					var t:Int = a[1];
					isPlaying = a[2] == 1;
					if (t != frame) {
						display(t);
						runActions(t, depth + 1);
					}
				case "x":
					script(a[1]);
				case _:
			}
		}
	}

	var killObj:Bool = false;
	var varName:String;

	// the frame scripts that do more than moving the playhead
	function script(name:String) {
		switch (name) {
			case "rmSelf":
				// removeMovieClip(): hidden now, taken out once every clip has played its frame (removing it in the middle
				// of the loop over the clips would make the next one skip this frame)
				removeLater(this);
			case "kill":
				// obj.kill() (mcExplosion, fxSpark): the mt.bumdum.Phys of the clip
				killObj = true;
				removeLater(this);
			case "pstop1":
				// _parent.gotoAndStop(1) (end of the hero's "land": "stand")
				var p = parentClip();
				if (p != null) {
					if (p.owner != null)
						p.owner.gotoAndStop(1);
					else
						p.gotoAndStop(1);
				}
			case "hfr", "bfr", "gfr", "afr":
				varName = name;
				parts.push(this);
			case _:
		}
	}

	inline function parentClip():Clip {
		return Std.downcast(parent, Clip);
	}

	// var mc = _parent; for (i in 0...6) { if (mc._bfr != null) { gotoAndStop(mc._bfr); break; } mc = mc._parent; }
	// (the monster in the arm lock: gotoAndStop(_parent._parent._afr), undefined: frame 1)
	function readVar() {
		var mc = parentClip();
		if (varName == "afr") {
			var p = mc != null ? mc.parentClip() : null;
			var v = p != null && p.vars != null ? p.vars.get(varName) : null;
			gotoAndStop(v != null ? v : 1);
			return;
		}
		for (i in 0...6) {
			if (mc == null)
				return;
			if (mc.vars != null && mc.vars.exists(varName)) {
				gotoAndStop(mc.vars.get(varName));
				return;
			}
			mc = mc.parentClip();
		}
	}

	public function setVar(name:String, v:Int) {
		if (vars == null)
			vars = new Map();
		vars.set(name, v);
	}

	static function removeLater(c:Clip) {
		if (c.selfRemoved)
			return;
		c.selfRemoved = true;
		c.isPlaying = false;
		c.visible = false;
		removed.push(c);
	}

	// ---------------------------------------------------------------- display
	function display(f:Int) {
		frame = f;
		untyped this._currentframe = f;
		if (def.simple) {
			var ti = def.layers[0].t[f - 1];
			texture = ti > 0 ? simpleFrames[ti - 1] : Texture.EMPTY;
			return;
		}
		var layers = def.layers;
		for (i in 0...layers.length) {
			var L = layers[i];
			if (L.k == 4)
				continue;
			var o = objs[i];
			if (o != null && o.parent != this) {
				// removed by a script: not shown again before a new placement
				deadPid[i] = pids[i];
				objs[i] = o = null;
			}
			var p = L.k == 2 ? L.p[f - 1] : L.t[f - 1];
			if (p == 0) {
				if (o != null) {
					if (L.k == 2) {
						removeLayer(i);
					} else {
						o.visible = false;
					}
				}
				continue;
			}
			if (L.k == 2) {
				if (o != null && pids[i] != p) {
					removeLayer(i);
					o = null;
				}
				if (o == null && deadPid[i] == p)
					continue;
			}
			var fresh = false;
			if (o == null) {
				o = createLayer(i);
				pids[i] = p;
				deadPid[i] = 0;
				fresh = true;
			}
			if (L.k != 2) {
				var g:Gfx = cast o;
				g.show(p);
				// (_visible set by the code stays, like on a Flash instance)
				o.visible = !g.hidden;
			}
			place(i, o, f);
			if (fresh && L.k == 2)
				(cast o : Clip).start();
			if (fresh)
				o.updateState();
		}
	}

	function createLayer(i:Int):ASprite {
		var L = def.layers[i];
		var o:ASprite;
		if (L.k == 2) {
			o = new Clip(L.a, 0, mulColor(tintIn, layerTint(L, frame)));
		} else {
			o = new Gfx(L.a);
		}
		if (L.nm != null)
			o._name = L.nm;
		untyped o._zIndex = i;
		var idx = 0;
		for (j in 0...i)
			if (objs[j] != null)
				idx++;
		addChildAt(o, Std.int(Math.min(idx, children.length)));
		objs[i] = o;
		if (L.k == 3) {
			// mask: hides the layers that reference it
			for (j in 0...def.layers.length)
				if (def.layers[j].mk == i && objs[j] != null)
					objs[j].mask = o;
		} else if (L.mk != null && objs[L.mk] != null) {
			o.mask = objs[L.mk];
		}
		return o;
	}

	function removeLayer(i:Int) {
		var o = objs[i];
		if (o == null)
			return;
		if (def.layers[i].k == 3)
			for (j in 0...objs.length)
				if (objs[j] != null && objs[j].mask == o)
					objs[j].mask = null;
		o.removeMovieClip();
		o.destroy({children: true});
		objs[i] = null;
	}

	inline function layerTint(L:LayerDef, f:Int):Int {
		return L.tn != null ? L.tn : (L.tns != null ? L.tns[f - 1] : 0xFFFFFF);
	}

	function place(i:Int, o:ASprite, f:Int) {
		var L = def.layers[i];
		var m = L.m0 != null ? L.m0 : (L.m != null ? L.m[f - 1] : null);
		var c = L.k == 2 ? (cast o : Clip) : null;
		if (m != null) {
			o._x = m[0];
			o._y = m[1];
			o._xscale = m[2] * 100;
			o._yscale = m[3] * 100;
			o._rotation = m[4];
			if (m.length > 5)
				o.skew.set(m[5], m[6]);
			else if (o.skew.x != 0 || o.skew.y != 0)
				o.skew.set(0, 0);
		}
		o._alpha = (L.al0 != null ? L.al0 : (L.al != null ? L.al[f - 1] : 1)) * 100;
		var tn = mulColor(tintIn, layerTint(L, f));
		if (c != null)
			c.setTint(tn);
		else
			o.tint = tn;
	}

	// Flash colour transform of a clip of white pictures (sparks, the blinking pixels): a multiplied colour
	public function setTint(mul:Int) {
		if (mul == tintIn)
			return;
		tintIn = mul;
		if (def.simple) {
			tint = tintIn;
			return;
		}
		for (i in 0...objs.length)
			if (objs[i] != null)
				place(i, objs[i], frame);
	}

	static function mulColor(a:Int, b:Int):Int {
		if (a == 0xFFFFFF)
			return b;
		if (b == 0xFFFFFF)
			return a;
		var r = ((a >> 16) & 0xFF) * ((b >> 16) & 0xFF) / 255;
		var g = ((a >> 8) & 0xFF) * ((b >> 8) & 0xFF) / 255;
		var bl = (a & 0xFF) * (b & 0xFF) / 255;
		return (Math.round(r) << 16) | (Math.round(g) << 8) | Math.round(bl);
	}

	// ---------------------------------------------------------------- named instances
	function layerIndex(name:String):Int {
		var found = -1;
		for (i in 0...def.layers.length)
			if (def.layers[i].nm == name) {
				if (objs[i] != null)
					return i;
				if (found < 0)
					found = i;
			}
		return found;
	}

	// current instance of a named layer (null when it is not on the current frame)
	public function get(name:String):ASprite {
		var i = layerIndex(name);
		return i < 0 ? null : objs[i];
	}

	public function getClip(name:String):Clip {
		return Std.downcast(get(name), Clip);
	}

	// a marker of the current frame ([_x, _y, _rotation] of the invisible clip `name`, null when it is absent)
	public function marker(name:String):Array<Float> {
		if (selfRemoved)
			return null;
		for (L in def.layers)
			if (L.k == 4 && L.nm == name) {
				var v = L.hm[frame - 1];
				if (v != null)
					return v;
			}
		return null;
	}

	override public function removeMovieClip() {
		super.removeMovieClip();
		isPlaying = false;
	}
}
