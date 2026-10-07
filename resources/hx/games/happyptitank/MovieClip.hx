package happyptitank;

import common_haxe_avm1.display.ASprite;
import pixi.core.sprites.Sprite as PSprite;
import pixi.core.textures.Texture;
import pixi.core.Pixi.BlendModes;

/**
 * flash.display.MovieClip of a library symbol (Data.symbols): its timeline, played one frame per Flash frame
 * (advanceAll, before the code of the frame) unless stopped. A class bound to a symbol (@:bind in the original)
 * extends it with its symbol id; a symbol bound to a Sprite class (DummyFoe, UserInterface...) shows its first frame
 * only (asSprite). The nested symbols the timelines place are created through `factories` when a class is bound to
 * them (TankTracks), plain clips otherwise.
 */
class MovieClip extends Sprite {
	public static var factories:Map<Int, Void->MovieClip> = new Map();

	public var sym(default, null):Int;
	public var currentFrame(get, never):Int;
	public var totalFrames(get, never):Int;

	var def:Dynamic;
	var frames:Array<Dynamic>;
	var idx:Array<Int>;
	var cf:Int = 0;
	var playing:Bool;
	var asSprite:Bool;

	public function new(sym:Int, ?asSprite:Bool = false) {
		super();
		this.sym = sym;
		this.asSprite = asSprite;
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
		playing = !asSprite && idx.length > 1;
		goto(1);
	}

	function get_currentFrame():Int {
		return cf;
	}

	function get_totalFrames():Int {
		return asSprite ? 1 : idx.length;
	}

	public function gotoAndStop(f:Int) {
		playing = false;
		goto(f);
	}

	public function gotoAndPlay(f:Int) {
		playing = true;
		goto(f);
	}

	public function stop() {
		playing = false;
	}

	public function play() {
		playing = true;
	}

	// the timeline's display list of frame f: kept instances updated, the others removed, the new ones created
	function goto(f:Int) {
		var n = totalFrames;
		if (f < 1)
			f = 1;
		if (f > n)
			f = n;
		if (f == cf)
			return;
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
				var ci:Int = e[9];
				var cx:Array<Float> = ci >= 0 ? J.cx[ci] : null;
				c.setFromTimeline(e[3], e[4], e[5], e[6], e[7], e[8], cx);
				var ni:Int = e[10];
				if (ni >= 0) {
					c.name = J.names[ni];
					Reflect.setField(this, c.name, c);
				}
				c.fx = e[12];
				c.clipDepth = e[11];
				addChildAt(c, at);
			} else {
				var ci:Int = e[9];
				c.setFromTimeline(e[3], e[4], e[5], e[6], e[7], e[8], ci >= 0 ? J.cx[ci] : null);
				c.fx = e[12];
			}
		}
	}

	function create(e:Array<Dynamic>):DisplayObject {
		switch (e[0]) {
			case "M":
				var sid:Int = e[1];
				var fn = factories.get(sid);
				return fn != null ? fn() : new MovieClip(sid);
			case "L":
				return new Leaf(e[1], e[13] == 1);
			case "F":
				return new TextField(e[1]);
			default:
				return new Sprite();
		}
	}

	// one frame of the timeline (Flash: the playhead moves before the code of the frame)
	function nextFrame() {
		var n = totalFrames;
		goto(cf >= n ? 1 : cf + 1);
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
 * A picture of the SWF (shape, static text, or a picture baked by the exporter): its bounds (Flash's getBounds),
 * its collision mask, and its views: the picture, its white copy (drawn ADD, tinted with the colour offset of a
 * colour transform) and its drop shadow picture.
 */
class Leaf extends DisplayObject {
	public var leaf(default, null):String;
	public var L(default, null):Dynamic;

	var variantLeaf:Bool;
	// pictures of the view: base, white
	var base:Array<PSprite> = [null, null];
	var white:PSprite = null;
	var shown:String = null;

	public function new(leaf:String, variantLeaf:Bool) {
		super();
		this.leaf = leaf;
		this.variantLeaf = variantLeaf;
		L = Reflect.field(Data.get().leaves, leaf);
	}

	// the picture drawn: the variant of the colour of the nearest parent that has one
	public function current():String {
		if (!variantLeaf)
			return leaf;
		var v = -1;
		var o:DisplayObject = this;
		while (o != null && v < 0) {
			v = o.variant;
			o = o.parent;
		}
		if (v < 0)
			v = 0;
		var base = leaf.substr(0, leaf.lastIndexOf("_"));
		var vs:Array<String> = Reflect.field(Data.get().variants, base);
		return vs[v];
	}

	public function data():Dynamic {
		var n = current();
		return n == leaf ? L : Reflect.field(Data.get().leaves, n);
	}

	override public function boundsInto(m:Mat, r:Rect, edges:Bool) {
		var D = data();
		var b:Array<Float> = edges ? D.r : D.b;
		if (b == null)
			b = [D.ox, D.ox + D.w, D.oy, D.oy + D.h];
		for (k in 0...4) {
			var px = (k & 1) == 0 ? b[0] : b[1];
			var py = (k & 2) == 0 ? b[2] : b[3];
			r.addPoint(m.a * px + m.c * py + m.tx, m.b * px + m.d * py + m.ty);
		}
	}

	static function pic(name:String, res:Float):PSprite {
		var t = Tex.get(name)[0];
		var s = new PSprite(t);
		s.anchor.copyFrom(t.defaultAnchor);
		s.scale.set(1 / res, 1 / res);
		return s;
	}

	function setPictures(mode:Int, name:String) {
		var v = view(mode);
		v.removeChildren();
		var D:Dynamic = Reflect.field(Data.get().leaves, name);
		var res:Float = D.res;
		if (D.tiles != null) {
			var tiles:Array<String> = D.tiles;
			for (t in tiles)
				v.addChild(pic(t, res));
			base[mode] = null;
			return;
		}
		if (mode == 1) {
			var p = pic(D.white == true ? name + "_s" : name, res);
			if (D.white != true)
				p.tint = 0;
			v.addChild(p);
			return;
		}
		var p = pic(name, res);
		v.addChild(p);
		base[0] = p;
		white = null;
		if (D.white == true) {
			white = pic(name + "_w", res);
			white.blendMode = BlendModes.ADD;
			white.visible = false;
			v.addChild(white);
		}
	}

	var shownMode:Array<String> = [null, null];

	// the picture of a mask (Sprite.maskGroup): made now, it stays the same
	public function maskPicture(mode:Int):PSprite {
		var n = current();
		if (shownMode[mode] != n) {
			shownMode[mode] = n;
			setPictures(mode, n);
		}
		var v = view(mode);
		return v.children.length > 0 ? cast v.children[0] : null;
	}

	// the colour of the picture: multipliers m (r, g, b) and offsets a (0..255) of the transforms of its parents
	override public function syncLeaf(mode:Int, f:Float, m:Array<Float>, a:Array<Float>) {
		var n = current();
		if (shownMode[mode] != n) {
			shownMode[mode] = n;
			setPictures(mode, n);
		}
		if (mode == 1)
			return;
		var b = base[0];
		if (b == null)
			return;
		var hasAdd = a[0] > 0 || a[1] > 0 || a[2] > 0;
		var solid = m[0] == 0 && m[1] == 0 && m[2] == 0;
		if (!hasAdd) {
			b.visible = true;
			b.tint = rgb(m[0], m[1], m[2]);
			if (white != null)
				white.visible = false;
		} else if (white != null) {
			// colour * m + a: the picture tinted m, then its white copy added, tinted a
			b.visible = !solid;
			b.tint = rgb(m[0], m[1], m[2]);
			white.visible = true;
			white.tint = rgb(a[0] / 255, a[1] / 255, a[2] / 255);
			white.blendMode = solid ? BlendModes.NORMAL : BlendModes.ADD;
		} else {
			b.visible = true;
			b.tint = rgb(m[0] + a[0] / 255, m[1] + a[1] / 255, m[2] + a[2] / 255);
		}
		var add = blendAdd();
		b.blendMode = add ? BlendModes.ADD : BlendModes.NORMAL;
	}

	// a blend mode "add" on this leaf or a parent placed by a timeline (inside an object with a filter, Flash draws
	// into the filter's own bitmap: the tank's col1 is added over nothing, drawn normally)
	function blendAdd():Bool {
		var o:DisplayObject = this;
		while (o != null) {
			if (o.shadow)
				return false;
			if (o.fx >= 0) {
				var fx:Dynamic = Data.get().fx[o.fx];
				if (fx.blend == "add")
					return true;
			}
			o = o.parent;
		}
		return false;
	}

	static inline function rgb(r:Float, g:Float, b:Float):Int {
		return (c8(r) << 16) | (c8(g) << 8) | c8(b);
	}

	static inline function c8(v:Float):Int {
		return v <= 0 ? 0 : v >= 1 ? 255 : Std.int(v * 255 + 0.5);
	}
}

/**
 * A text field of the SWF (DefineEditText): `text` written by the code, drawn with the glyphs of its embedded font
 * (Glyphs.hx: the level and the time of the interface).
 */
class TextField extends DisplayObject {
	public var text(default, set):String = "";
	public var edit(default, null):Int;

	var E:Dynamic;
	var shownText:String = null;

	public function new(edit:Int) {
		super();
		this.edit = edit;
		E = Reflect.field(Data.get().edits, Std.string(edit));
	}

	function set_text(s:String):String {
		text = s;
		return s;
	}

	override public function boundsInto(m:Mat, r:Rect, edges:Bool) {
		var b:Array<Float> = E.b;
		for (k in 0...4) {
			var px = (k & 1) == 0 ? b[0] : b[1];
			var py = (k & 2) == 0 ? b[2] : b[3];
			r.addPoint(m.a * px + m.c * py + m.tx, m.b * px + m.d * py + m.ty);
		}
	}

	override public function syncLeaf(mode:Int, f:Float, m:Array<Float>, a:Array<Float>) {
		if (mode != 0 || shownText == text)
			return;
		shownText = text;
		Glyphs.layout(view(0), edit, text);
	}
}
