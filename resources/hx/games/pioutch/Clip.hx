package pioutch;

import common_haxe_avm1.display.ASprite.TransformState;
import mt.DepthManager;
import pixi.core.Pixi.BlendModes;
import pixi.core.sprites.Sprite as PixiSprite;
import pixi.core.textures.Texture;

// One layer of a clip (written by the asset pipeline, tools/clipexport.py):
//  k: 0 flattened images (one per frame) / 1 image moved by a matrix / 2 nested clip / 3 mask
//  a: animation (k 0, 1, 3) or clip (k 2) name
//  t: image of each frame (0: layer absent) / p: placement of each frame for nested clips (0: absent, new value: new instance)
//  m / m0: [x, y, scaleX, scaleY, rotation (deg), skewX, skewY] of each frame / of all the frames
//  al / al0: alpha, tn / tns: multiplied colour, ad / ads: added colour (white silhouette `a`W drawn additively)
//  nm: instance name, mk: layer masking this one, bl: blend mode of the instance (add, mul, scr)
typedef LayerDef = {
	k:Int,
	a:String,
	?t:Array<Int>,
	?p:Array<Int>,
	?m:Array<Array<Float>>,
	?m0:Array<Float>,
	?al:Array<Float>,
	?al0:Float,
	?tn:Int,
	?tns:Array<Int>,
	?ad:Int,
	?ads:Array<Int>,
	?nm:String,
	?mk:Int,
	?bl:String
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

// transform / visibility of a named instance set by a script or by the code
private typedef Override = {?rot:Float, ?xs:Float, ?ys:Float, ?x:Float, ?y:Float, ?al:Float, ?vis:Bool};

// image of a layer (flattened frames or a single shape), with its additive white silhouette when needed
class Gfx extends ASprite {
	public var frames(default, null):Array<Texture>;

	var anim:String;
	var addSpr:PixiSprite;
	var cur:Int;

	public function new(anim:String) {
		super();
		this.anim = anim;
		frames = Tex.get(anim);
		texture = frames[0];
		anchor.copyFrom(frames[0].defaultAnchor);
		_totalframes = frames.length;
		cur = 1;
	}

	public inline function show(i:Int) {
		var t = frames[i - 1];
		if (texture != t) {
			texture = t;
			cur = i;
			if (addSpr != null)
				addSpr.texture = Tex.get(anim + "W")[i - 1];
		}
	}

	// Flash colour offset: added colour, 0 = none
	public function setAdd(c:Int) {
		if (c == 0) {
			if (addSpr != null)
				addSpr.visible = false;
			return;
		}
		if (addSpr == null) {
			var w = Tex.get(anim + "W");
			addSpr = new PixiSprite(w[cur - 1]);
			addSpr.anchor.copyFrom(w[0].defaultAnchor);
			addSpr.blendMode = BlendModes.ADD;
			addChild(addSpr);
		}
		addSpr.visible = true;
		addSpr.tint = c;
	}
}

// Flash MovieClip replayed from the exported timeline tables: nested clips keep their own playhead, frame scripts
// (stop / play / goto / a few custom ones) run like in the Flash player.
class Clip extends ASprite {
	public static inline var K = 2;

	static var defs:Map<String, ClipDef> = new Map();

	// frame scripts reached by a goto of the game code: run after the code, like the AVM1 action list
	static var later:Array<Void->Void> = [];

	// clips removed by their own frame script during the update of the timelines
	static var removed:Array<Clip> = [];

	public var def(default, null):ClipDef;
	public var clipName(default, null):String;
	public var frame(default, null):Int;

	// the transform was changed by a script of the clip: its parent timeline no longer moves it (Flash rule)
	public var scripted:Bool;

	// frozen picture: no timeline at all
	public var frozen:Bool;

	// called when the clip removes itself (removeMovieClip in a frame script)
	public var onRemoved:Void->Void;

	// a top level clip is in Flash pixels: _xscale / _yscale 100 = textures at their resolution
	public var baseScale(default, null):Float;

	var objs:Array<ASprite>;
	var pids:Array<Int>;
	var deadPid:Array<Int>;
	var overrides:Map<Int, Override>;
	var tintIn:Int;
	var addIn:Int;
	var blendIn:BlendModes;
	var simpleFrames:Array<Texture>;
	var simpleAdd:PixiSprite;

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

	static function blendOf(s:String, inherited:BlendModes):BlendModes {
		return switch (s) {
			case "add": BlendModes.ADD;
			case "mul": BlendModes.MULTIPLY;
			case "scr": BlendModes.SCREEN;
			case _: inherited;
		}
	}

	// frame scripts queued by the code (gotoAndStop / gotoAndPlay of the game): run them
	public static function runLater() {
		var i = 0;
		while (i < later.length)
			later[i++]();
		later = [];
	}

	public static function clearLater() {
		later = [];
		removed = [];
	}

	// removeMovieClip() of the clips that removed themselves (called once the timelines are updated)
	public static function flushRemoved() {
		if (removed.length == 0)
			return;
		var l = removed;
		removed = [];
		for (c in l) {
			c.removeMovieClip();
			if (c.onRemoved != null)
				c.onRemoved();
		}
	}

	// pxPerUnit: pixels of the parent per Flash pixel (1 in the game world, 0 = nested clip placed by its parent)
	public function new(name:String, ?pxPerUnit:Float = 1, ?tint:Int = 0xFFFFFF, ?add:Int = 0, ?blend:BlendModes) {
		super();
		def = getDef(name);
		clipName = name;
		_name = name;
		_totalframes = def.n;
		scripted = false;
		frozen = false;
		tintIn = tint;
		addIn = add;
		blendIn = blend != null ? blend : BlendModes.NORMAL;
		baseScale = pxPerUnit > 0 ? pxPerUnit / (K * def.r) : 1;
		objs = [];
		pids = [];
		deadPid = [];
		overrides = new Map();
		if (def.simple) {
			simpleFrames = Tex.get(def.layers[0].a);
			anchor.copyFrom(simpleFrames[0].defaultAnchor);
			blendMode = blendIn;
			applySimpleColour();
		}
		if (baseScale != 1) {
			_xscale = 100;
			_yscale = 100;
		}
		frame = 0;
		var f = def.start != null ? def.start : 1;
		isPlaying = def.still == null;
		display(f);
		runActions(f, 0, false);
	}

	// top level clip attached at a plan of a depth manager
	public static function attach(dm:DepthManager, name:String, plan:Int):Clip {
		var c = new Clip(name);
		c.attachTo(dm, plan);
		return c;
	}

	public function attachTo(dm:DepthManager, plan:Int):Clip {
		var d = dm.reserve(this, plan);
		dm.getMC().addChild(this);
		_zIndex = d;
		zsort();
		return this;
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
	override public function update() {
		if (frozen) {
			updateState();
			return;
		}
		if (_prevState == null)
			_prevState = new TransformState(this);
		_prevState.copyFrom(_curState);
		for (c in children)
			if (Std.isOfType(c, ASprite))
				(cast c : ASprite).update();
		// a timeline of one frame does not loop (its script runs once)
		if (isPlaying && def.n > 1)
			nextFrame();
	}

	override public function nextFrame() {
		var f = frame + 1;
		if (f > def.n)
			f = 1;
		display(f);
		runActions(f, 0, false);
	}

	override public function prevFrame() {
		if (frame > 1)
			goto(frame - 1, false);
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

	// gotoAndStop / gotoAndPlay of the game code: the frame scripts run after the code (runLater)
	override public function gotoAndStop(f:Dynamic) {
		goto(resolve(f), false, true);
	}

	override public function gotoAndPlay(f:Dynamic) {
		goto(resolve(f), true, true);
	}

	public function resolve(f:Dynamic):Int {
		if (Std.isOfType(f, Int))
			return f;
		var s:String = Std.string(f);
		if (def.lab.exists(s))
			return def.lab.get(s);
		var n = Std.parseInt(s);
		return n == null ? frame : n;
	}

	function goto(f:Int, play:Bool, fromCode:Bool = false) {
		if (f < 1)
			f = 1;
		if (f > def.n)
			f = def.n;
		isPlaying = play && def.still == null;
		if (f == frame)
			return;
		display(f);
		runActions(f, 0, fromCode);
	}

	function runActions(f:Int, depth:Int, deferred:Bool) {
		var acts = def.act[f];
		if (acts == null || depth > 8)
			return;
		if (deferred) {
			// the action list of the frame runs after the code that moved the playhead (AVM1); the playhead may
			// have moved again by then (only the scripts of the frame shown are run)
			later.push(function() {
				if (frame == f && parent != null)
					runActions(f, depth, false);
			});
			return;
		}
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
						runActions(t, depth + 1, false);
					}
				case "x":
					script(a[1]);
				case _:
			}
		}
	}

	// the few frame scripts that do more than moving the playhead
	function script(name:String) {
		switch (name) {
			case "rot5":
				// v._rotation += 5: the vortex of the gate turns
				var v = get("}");
				if (v != null)
					setOverride("}", normRot(v._rotation + 5), null, null);
			case "armsOn" | "armsOff":
				// the pillow bounces with its own arms: the arms of the hero (d, b1, b2, b3) are hidden meanwhile
				var p = Std.downcast(parent, Clip);
				if (p != null)
					for (n in ["+", "=-", "[-", "]-"])
						p.setVisible(n, name == "armsOn");
			case "parentGoto2":
				// end of the fury: _parent.gotoAndStop(2)
				var p = Std.downcast(parent, Clip);
				if (p != null)
					p.goto(2, false);
			case "rmSelf":
				// removeMovieClip(): done after the update of the timelines (removing a clip while its parent loops on its
				// children would skip the update of the next one)
				isPlaying = false;
				if (removed.indexOf(this) < 0)
					removed.push(this);
			case _:
		}
	}

	// Flash _rotation reads back in ]-180, 180]
	static function normRot(r:Float):Float {
		r = r % 360;
		if (r > 180)
			r -= 360;
		if (r <= -180)
			r += 360;
		return r;
	}

	// ---------------------------------------------------------------- display
	function display(f:Int) {
		frame = f;
		untyped this._currentframe = f;
		if (def.simple) {
			var ti = def.layers[0].t[f - 1];
			texture = ti > 0 ? simpleFrames[ti - 1] : Texture.EMPTY;
			if (simpleAdd != null)
				simpleAdd.texture = ti > 0 ? Tex.get(def.layers[0].a + "W")[ti - 1] : Texture.EMPTY;
			return;
		}
		var layers = def.layers;
		for (i in 0...layers.length) {
			var L = layers[i];
			var o = objs[i];
			if (o != null && o.parent != this) {
				// removed by a script: not shown again before a new placement
				deadPid[i] = pids[i];
				objs[i] = o = null;
				overrides.remove(i);
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
				(cast o : Gfx).show(p);
				var ov = overrides.get(i);
				o.visible = ov == null || ov.vis == null || ov.vis;
			}
			place(i, o, f);
			if (fresh)
				o.updateState();
		}
	}

	function createLayer(i:Int):ASprite {
		var L = def.layers[i];
		var o:ASprite;
		var bm = blendOf(L.bl, blendIn);
		if (L.k == 2) {
			o = new Clip(L.a, 0, mulColor(tintIn, layerTint(L, frame)), addColor(addIn, mulColor(tintIn, layerAdd(L, frame))), bm);
		} else {
			o = new Gfx(L.a);
			if (L.k != 3)
				o.blendMode = bm;
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
		overrides.remove(i);
	}

	inline function layerTint(L:LayerDef, f:Int):Int {
		return L.tn != null ? L.tn : (L.tns != null ? L.tns[f - 1] : 0xFFFFFF);
	}

	inline function layerAdd(L:LayerDef, f:Int):Int {
		return L.ad != null ? L.ad : (L.ads != null ? L.ads[f - 1] : 0);
	}

	function place(i:Int, o:ASprite, f:Int) {
		var L = def.layers[i];
		var m = L.m0 != null ? L.m0 : (L.m != null ? L.m[f - 1] : null);
		var c = L.k == 2 ? (cast o : Clip) : null;
		if (m != null && (c == null || !c.scripted)) {
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
		var ov = overrides.get(i);
		if (ov != null) {
			if (ov.x != null)
				o._x = ov.x;
			if (ov.y != null)
				o._y = ov.y;
			if (ov.rot != null)
				o._rotation = ov.rot;
			if (ov.xs != null)
				o._xscale = ov.xs;
			if (ov.ys != null)
				o._yscale = ov.ys;
		}
		o._alpha = (ov != null && ov.al != null) ? ov.al : (L.al0 != null ? L.al0 : (L.al != null ? L.al[f - 1] : 1)) * 100;
		var tn = mulColor(tintIn, layerTint(L, f));
		var ad = addColor(addIn, mulColor(tintIn, layerAdd(L, f)));
		if (c != null) {
			c.setColour(tn, ad);
		} else {
			o.tint = tn;
			if (ad != 0 || L.ad != null || L.ads != null || addIn != 0)
				(cast o : Gfx).setAdd(ad);
		}
	}

	// Flash colour transform without alpha: multiplied colour + added colour (0xRRGGBB)
	public function setColour(mul:Int, add:Int) {
		if (mul == tintIn && add == addIn)
			return;
		tintIn = mul;
		addIn = add;
		if (def.simple) {
			applySimpleColour();
			return;
		}
		for (i in 0...objs.length)
			if (objs[i] != null)
				place(i, objs[i], frame);
	}

	function applySimpleColour() {
		tint = tintIn;
		if (addIn != 0 && simpleAdd == null) {
			var w = Tex.get(def.layers[0].a + "W");
			var ti = frame > 0 ? def.layers[0].t[frame - 1] : 0;
			simpleAdd = new PixiSprite(ti > 0 ? w[ti - 1] : Texture.EMPTY);
			simpleAdd.anchor.copyFrom(w[0].defaultAnchor);
			simpleAdd.blendMode = BlendModes.ADD;
			addChild(simpleAdd);
		}
		if (simpleAdd != null) {
			simpleAdd.visible = addIn != 0;
			simpleAdd.tint = addIn;
		}
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

	static function addColor(a:Int, b:Int):Int {
		if (a == 0)
			return b;
		if (b == 0)
			return a;
		var r = Std.int(Math.min(255, ((a >> 16) & 0xFF) + ((b >> 16) & 0xFF)));
		var g = Std.int(Math.min(255, ((a >> 8) & 0xFF) + ((b >> 8) & 0xFF)));
		var bl = Std.int(Math.min(255, (a & 0xFF) + (b & 0xFF)));
		return (r << 16) | (g << 8) | bl;
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

	function overrideOf(name:String):Override {
		var i = layerIndex(name);
		if (i < 0 || objs[i] == null)
			return null;
		var ov = overrides.get(i);
		if (ov == null) {
			ov = {};
			overrides.set(i, ov);
		}
		return ov;
	}

	// transform of a named instance set by the code (like _rotation, _x... on a Flash clip): kept while the instance
	// lives, ignored when it is not on the current frame
	public function setOverride(name:String, rot:Null<Float>, xs:Null<Float>, ys:Null<Float>, ?x:Null<Float>, ?y:Null<Float>, ?alpha:Null<Float>) {
		var ov = overrideOf(name);
		if (ov == null)
			return;
		if (rot != null)
			ov.rot = rot;
		if (xs != null)
			ov.xs = xs;
		if (ys != null)
			ov.ys = ys;
		if (x != null)
			ov.x = x;
		if (y != null)
			ov.y = y;
		if (alpha != null)
			ov.al = alpha;
		var i = layerIndex(name);
		place(i, objs[i], frame);
	}

	// _visible of a named instance (kept while the instance lives)
	public function setVisible(name:String, v:Bool) {
		var ov = overrideOf(name);
		if (ov == null)
			return;
		ov.vis = v;
		var i = layerIndex(name);
		if (def.layers[i].k == 2)
			objs[i].visible = v;
		else
			objs[i].visible = v && def.layers[i].t[frame - 1] > 0;
	}

	// pixels of the clip per Flash pixel
	public inline function pxPerUnit():Float {
		return K * def.r;
	}

	// the timeline and those of the nested clips are over (stopped, or a single frame)
	public function finished():Bool {
		if (isPlaying && def.n > 1)
			return false;
		for (o in objs) {
			var c = Std.downcast(o, Clip);
			if (c != null && !c.finished())
				return false;
		}
		return true;
	}

	public function freeze() {
		frozen = true;
		isPlaying = false;
		for (o in objs) {
			var c = Std.downcast(o, Clip);
			if (c != null)
				c.freeze();
		}
	}

	override public function removeMovieClip() {
		super.removeMovieClip();
		isPlaying = false;
	}
}
