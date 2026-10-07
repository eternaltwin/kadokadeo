package phagocytoz;

import common_haxe_avm1.display.ASprite;
import pixi.core.sprites.Sprite as PSprite;
import pixi.core.textures.Texture;
import pixi.core.Pixi.BlendModes;

/**
 * flash.display.MovieClip of a library symbol (Data.symbols, from Happy Pti Tank's MovieClip.hx): its timeline, played
 * one frame per Flash frame (advanceAll, before the code of the frame) unless stopped, and the frame scripts of its
 * class (Data: stop, gotoAndPlay) or added by the code (addFrameScript). AS3 order: the scripts of the frames the
 * playheads entered run after the code of the frame (runScripts), the one of a frame reached by a goto of a script at
 * once; a clip created by the code or by a timeline runs the script of its first frame with the others.
 */
class MovieClip extends Sprite {
	public var sym(default, null):Int;
	public var currentFrame(get, never):Int;
	public var totalFrames(get, never):Int;

	var def:Dynamic;
	var frames:Array<Dynamic>;
	var idx:Array<Int>;
	var cf:Int = 0;
	var playing:Bool;
	// frame scripts added by the code (addFrameScript), by frame (1-based)
	var codeScripts:Map<Int, Void->Void> = null;

	// clips whose entered frame has a script to run (runScripts)
	static var pending:Array<MovieClip> = [];
	var pendingFrame:Int = 0;

	public function new(sym:Int) {
		super();
		this.sym = sym;
		if (sym < 0) {
			// a MovieClip of the code: no symbol, one empty frame
			frames = [[]];
			idx = [0];
		} else {
			def = Reflect.field(Data.get().symbols, Std.string(sym));
			if (def == null)
				throw "no symbol " + sym;
			frames = def.frames;
			idx = def.idx;
		}
		playing = idx.length > 1;
		goto(1);
		queueScript();
	}

	function get_currentFrame():Int {
		return cf;
	}

	function get_totalFrames():Int {
		return idx.length;
	}

	public function gotoAndStop(f:Int) {
		playing = false;
		if (goto(f))
			runScript();
	}

	public function gotoAndPlay(f:Int) {
		playing = true;
		if (goto(f))
			runScript();
	}

	public function stop() {
		playing = false;
	}

	public function play() {
		playing = true;
	}

	// addFrameScript(index, fn): index 0-based
	public function addFrameScript(index:Int, fn:Void->Void) {
		if (codeScripts == null)
			codeScripts = new Map();
		codeScripts.set(index + 1, fn);
	}

	function hasScript(f:Int):Bool {
		if (codeScripts != null && codeScripts.exists(f))
			return true;
		return def != null && Reflect.hasField(def.scripts, Std.string(f));
	}

	function queueScript() {
		if (!hasScript(cf))
			return;
		if (pendingFrame == 0)
			pending.push(this);
		pendingFrame = cf;
	}

	// the script of the current frame
	function runScript() {
		pendingFrame = 0;
		var f = cf;
		if (codeScripts != null && codeScripts.exists(f)) {
			codeScripts.get(f)();
			return;
		}
		if (def == null)
			return;
		var ops:Array<Dynamic> = Reflect.field(def.scripts, Std.string(f));
		if (ops == null)
			return;
		for (op in ops) {
			if (op == "s")
				stop();
			else if (op[0] == "g")
				gotoAndPlay(op[1]);
			else if (op[0] == "r") {
				// (gotoAndPlay(Math.floor(Math.random() * 50 + 1)): the worm's start, a picture only)
				var lo:Int = op[1];
				var hi:Int = op[2];
				gotoAndPlay(lo + Seed.randomVfx(hi - lo + 1));
			}
		}
	}

	// the scripts of the frames entered during this Flash frame (after its code)
	public static function runScripts() {
		while (pending.length > 0) {
			var list = pending;
			pending = [];
			for (m in list)
				if (m.pendingFrame != 0 && m.pendingFrame == m.cf)
					m.runScript();
				else
					m.pendingFrame = 0;
		}
	}

	public static function resetAll() {
		pending = [];
	}

	// the timeline's display list of frame f: kept instances updated, the others removed, the new ones created
	function goto(f:Int):Bool {
		var n = totalFrames;
		if (f < 1)
			f = 1;
		if (f > n)
			f = n;
		if (f == cf)
			return false;
		cf = f;
		var list:Array<Array<Dynamic>> = frames[idx[f - 1]];
		var keys = new Map<Int, Bool>();
		for (e in list)
			keys.set(e[2], true);
		for (c in children.copy())
			if (c.tlKey >= 0 && !keys.exists(c.tlKey)) {
				if (c.name != null && Reflect.field(this, c.name) == c)
					Reflect.setField(this, c.name, null);
				removeChild(c);
			}
		var J = Data.get();
		for (e in list) {
			var key:Int = e[2];
			var c:DisplayObject = null;
			for (ch in children)
				if (ch.tlKey == key) {
					c = ch;
					break;
				}
			var ci:Int = e[9];
			var cx:Array<Float> = ci >= 0 ? J.cx[ci] : null;
			if (c == null) {
				c = create(e);
				c.tlKey = key;
				c.tlDepth = Std.int(key / 1000);
				// timeline children in the order of their depths, under the ones the code added
				var at = 0;
				for (i in 0...children.length) {
					var ch = children[i];
					if (ch.tlKey >= 0 && ch.tlDepth < c.tlDepth)
						at = i + 1;
				}
				c.setFromTimeline(e[3], e[4], e[5], e[6], e[7], e[8], cx);
				var ni:Int = e[10];
				if (ni >= 0) {
					c.name = J.names[ni];
					Reflect.setField(this, c.name, c);
				}
				c.fx = e[12];
				addChildAt(c, at);
			} else {
				c.setFromTimeline(e[3], e[4], e[5], e[6], e[7], e[8], cx);
				c.fx = e[12];
			}
		}
		return true;
	}

	function create(e:Array<Dynamic>):DisplayObject {
		switch (e[0]) {
			case "M":
				var fn = Gfx.factories.get(e[1]);
				return fn != null ? fn() : new MovieClip(e[1]);
			case "L":
				return new Leaf(e[1]);
			case "F":
				return new TextField(e[1]);
			default:
				return new Sprite();
		}
	}

	// one frame of the timeline (Flash: the playhead moves before the code of the frame)
	function nextFrame() {
		var n = totalFrames;
		if (goto(cf >= n ? 1 : cf + 1))
			queueScript();
	}

	// every playing clip of the tree advances (the clips created meanwhile start on the next frame)
	public static function advanceAll(root:Sprite) {
		var list:Array<MovieClip> = [];
		collect(root, list);
		for (m in list)
			m.nextFrame();
	}

	static function collect(s:Sprite, list:Array<MovieClip>) {
		var m = Std.downcast(s, MovieClip);
		if (m != null && m.playing && m.totalFrames > 1)
			list.push(m);
		for (c in s.children) {
			var cs = Std.downcast(c, Sprite);
			if (cs != null)
				collect(cs, list);
		}
	}
}

/**
 * A picture of the SWF (a shape, or a frame of the worm): drawn with the picture whose resolution fits the size it is
 * shown at (lods: the cells go from a few pixels to more than the screen), or a solid rectangle.
 */
class Leaf extends DisplayObject {
	public var leaf(default, null):String;

	var L:Dynamic;
	var pic:PSprite = null;
	var shown:String = null;

	public function new(leaf:String) {
		super();
		this.leaf = leaf;
		L = Reflect.field(Data.get().leaves, leaf);
	}

	static function pic0(name:String, res:Float):PSprite {
		var t = Tex.get(name)[0];
		var s = new PSprite(t);
		s.anchor.copyFrom(t.defaultAnchor);
		s.scale.set(1 / res, 1 / res);
		return s;
	}

	// the picture of the resolution that fits: px canvas pixels per unit of the leaf
	function pictureFor(px:Float):String {
		var lods:Array<Array<Dynamic>> = L.lods;
		if (lods == null)
			return leaf;
		for (l in lods)
			if ((l[0] : Float) >= px * 0.9)
				return l[1];
		return lods[lods.length - 1][1];
	}

	function show(name:String) {
		if (shown == name)
			return;
		shown = name;
		var v = view;
		v.removeChildren();
		if (L.solid != null) {
			pic = new PSprite(Texture.WHITE);
			pic.x = L.ox;
			pic.y = L.oy;
			pic.width = L.w;
			pic.height = L.h;
			v.addChild(pic);
			return;
		}
		var res:Float = L.res;
		if (L.lods != null) {
			var lods:Array<Array<Dynamic>> = L.lods;
			for (l in lods)
				if (l[1] == name)
					res = l[0];
		}
		pic = pic0(name, res);
		v.addChild(pic);
	}

	override public function syncLeaf(f:Float, m:Array<Float>, a:Array<Float>, add:Bool) {
		var name = leaf;
		// canvas pixels per unit of the leaf, as it is shown (the membrane drawn 2 / k wide: from the scale of the last
		// frame, a cell shrinking a lot in one frame showed a membrane as wide as the cell before)
		var k = L.lods != null || L.hair != null ? shownScale(f) : 2.0;
		if (L.lods != null)
			name = pictureFor(k);
		show(name);
		var base:Int = L.solid != null ? L.solid : 0xFFFFFF;
		var r = ((base >> 16) & 0xFF) / 255 * m[0] + a[0] / 255;
		var g = ((base >> 8) & 0xFF) / 255 * m[1] + a[1] / 255;
		var b = (base & 0xFF) / 255 * m[2] + a[2] / 255;
		pic.tint = (c8(r) << 16) | (c8(g) << 8) | c8(b);
		pic.blendMode = add ? BlendModes.ADD : BlendModes.NORMAL;
		if (L.hair != null)
			drawHair(k, pic.tint, pic.blendMode);
	}

	// the outline thinner than a pixel (the membranes): Flash draws it one pixel wide at any scale (1 stage pixel, 2
	// canvas pixels), redrawn when the scale changes
	var hair:pixi.core.graphics.Graphics = null;
	var hairWidth:Float = 0;

	function drawHair(k:Float, tint:Int, blend:BlendModes) {
		if (k <= 0)
			return;
		var w = 2 / k;
		if (hair == null) {
			hair = new pixi.core.graphics.Graphics();
			view.addChild(hair);
		} else if (hair.parent != view)
			view.addChild(hair);
		if (Math.abs(w - hairWidth) > hairWidth * 0.08) {
			hairWidth = w;
			var H:Dynamic = L.hair;
			var ops:Array<Array<Dynamic>> = H.path;
			hair.clear();
			hair.lineTextureStyle({width: w, color: H.color, alpha: H.alpha, cap: "round", join: "round"});
			for (op in ops) {
				switch (op[0]) {
					case "M":
						hair.moveTo(op[1], op[2]);
					case "L":
						hair.lineTo(op[1], op[2]);
					case "Q":
						hair.quadraticCurveTo(op[1], op[2], op[3], op[4]);
					case "Z":
						hair.closePath();
				}
			}
		}
		hair.tint = tint;
		hair.blendMode = blend;
	}

	static inline function c8(v:Float):Int {
		return v <= 0 ? 0 : v >= 1 ? 255 : Std.int(v * 255 + 0.5);
	}
}

/**
 * A text field of the SWF (DefineEditText): `text` written by the code, drawn with the glyphs of its embedded font
 * (Glyphs.hx: the score, the phase).
 */
class TextField extends DisplayObject {
	public var text(default, set):String = "";
	public var edit(default, null):Int;

	var shownText:String = null;
	var shownRes:Float = -1;

	public function new(edit:Int) {
		super();
		this.edit = edit;
	}

	function set_text(s:String):String {
		text = s;
		return s;
	}

	override public function syncLeaf(f:Float, m:Array<Float>, a:Array<Float>, add:Bool) {
		var res = Glyphs.resFor(edit, screenScale());
		if (shownText == text && shownRes == res)
			return;
		shownText = text;
		shownRes = res;
		Glyphs.layout(view, edit, text, res);
	}
}

/**
 * flash.display.Bitmap of the background (Game.initBg: a BitmapData drawn once, here the baked picture BG), drawn
 * without smoothing (Bitmap.smoothing is false by default: the zoom of bgScroller shows its pixels).
 */
class Bitmap extends DisplayObject {
	var anim:String;

	public function new(anim:String) {
		super();
		this.anim = anim;
	}

	override public function makeView():ASprite {
		var v = new ASprite();
		var t = Tex.get(anim)[0];
		t.baseTexture.scaleMode = pixi.core.Pixi.ScaleModes.NEAREST;
		var s = new PSprite(t);
		s.anchor.copyFrom(t.defaultAnchor);
		// (one pixel per unit, like the BitmapData of the original: the code shows it at 1 / 2)
		v.addChild(s);
		return v;
	}
}
