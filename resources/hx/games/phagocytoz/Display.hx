package phagocytoz;

import common_haxe_avm1.display.ASprite;
import pixi.core.sprites.Sprite as PSprite;
import pixi.core.textures.Texture;
import pixi.core.Pixi.BlendModes;

/**
 * The AS3 display list of the original (flash.display.*), kept by the game (from Happy Pti Tank's Display.hx): the
 * code of the port reads and writes it like the original did (x, y, rotation, scaleX, alpha, visible, filters,
 * blendMode, addChild, gotoAndStop, mouseX...). PIXI only draws it (syncTree): nothing of the gameplay depends on the
 * rendering.
 *
 * Flash rules kept:
 *  - x / y are stored in twips (1/20 pixel, truncated); rotation is kept in ]-180, 180]; alpha is 8.8 fixed point;
 *  - the symbols play their timelines on their own (MovieClip), one frame per Flash frame, before the code of the
 *    frame (advanceAll), unless stopped;
 *  - an instance placed by a timeline is the same object while the timeline does not replace it (the keys of Data);
 *    its named children are fields of the clip (Reflect.setField: cell.env, cell.noyau, title.phase...);
 *  - an object moved or coloured by the code is no longer moved by its timeline.
 *
 * Display: Phagocytoz ran at 30 Flash frames/s (the KadoKado AS3 loader) and KadoKadeo steps 32 times per second (15
 * Flash frames every 16 steps, Game.update). Every object is shown as it was one Flash frame ago, interpolated towards
 * the last frame by the fraction of a frame the steps are behind: an object created during the last Flash frame is
 * not shown yet, one removed during it is still shown (ghost) until the next Flash frame.
 */
class DisplayObject {
	// Flash frames played (the snapshots of the display)
	public static var flashFrame:Int = 0;

	public var parent(default, null):Sprite = null;
	public var name:String = null;

	// the matrix (a, b, c, d, tx, ty) and the values the properties read back (Flash caches them)
	var ma:Float = 1;
	var mb:Float = 0;
	var mc:Float = 0;
	var md:Float = 1;
	var mtx:Int = 0; // twips
	var mty:Int = 0;
	var csx:Float = 1;
	var csy:Float = 1;
	var crot:Float = 0;

	// colorTransform: multipliers (alpha = the alpha property) and offsets (0..255)
	var cxm:Array<Float> = null;
	var cxa:Array<Float> = null;
	var alpha8:Float = 1;

	public var visible:Bool = true;

	// moved / coloured by the code: its timeline no longer changes it
	var scripted:Bool = false;

	// timeline instance key (Data), -1 for an object created by the code
	public var tlKey:Int = -1;
	public var tlDepth:Int = 0;
	// filters / blend mode of the timeline (Data.fx index)
	public var fx:Int = -1;
	// filters / blend mode set by the code (DisplayObject.filters, blendMode): [{type: "glow", blurX, blurY, color,
	// strength, passes}]
	public var filters(default, set):Array<Dynamic> = null;
	public var blendMode:String = null;

	public var x(get, set):Float;
	public var y(get, set):Float;
	public var rotation(get, set):Float;
	public var scaleX(get, set):Float;
	public var scaleY(get, set):Float;
	public var alpha(get, set):Float;

	public function new() {}

	// ---------------------------------------------------------------- properties
	function get_x():Float {
		return mtx / 20;
	}

	function set_x(v:Float):Float {
		scripted = true;
		mtx = twips(v);
		return v;
	}

	function get_y():Float {
		return mty / 20;
	}

	function set_y(v:Float):Float {
		scripted = true;
		mty = twips(v);
		return v;
	}

	// (Flash: NaN gives 0, the value truncated towards zero)
	static inline function twips(v:Float):Int {
		return Math.isNaN(v) ? 0 : Std.int(v * 20);
	}

	function get_rotation():Float {
		return crot;
	}

	function set_rotation(v:Float):Float {
		scripted = true;
		v = v % 360;
		if (v > 180)
			v -= 360;
		else if (v < -180)
			v += 360;
		crot = v;
		updateMatrix();
		return v;
	}

	function get_scaleX():Float {
		return csx;
	}

	function set_scaleX(v:Float):Float {
		scripted = true;
		csx = v;
		updateMatrix();
		return v;
	}

	function get_scaleY():Float {
		return csy;
	}

	function set_scaleY(v:Float):Float {
		scripted = true;
		csy = v;
		updateMatrix();
		return v;
	}

	function updateMatrix() {
		var r = crot * Math.PI / 180;
		var c = Math.cos(r);
		var s = Math.sin(r);
		ma = csx * c;
		mb = csx * s;
		mc = -csy * s;
		md = csy * c;
	}

	function get_alpha():Float {
		return alpha8;
	}

	// (8.8 fixed point)
	function set_alpha(v:Float):Float {
		scripted = true;
		alpha8 = Std.int(v * 256) / 256;
		return v;
	}

	function set_filters(v:Array<Dynamic>):Array<Dynamic> {
		filters = v != null && v.length > 0 ? v : null;
		return v;
	}

	// transform.colorTransform = new ColorTransform(rm, gm, bm, am, ro, go, bo, ao) (the alpha property is its am)
	public function setColorTransform(rm:Float, gm:Float, bm:Float, am:Float, ro:Float, go:Float, bo:Float, ao:Float) {
		scripted = true;
		cxm = [rm, gm, bm];
		cxa = [ro, go, bo, ao];
		alpha8 = Std.int(am * 256) / 256;
		if (rm == 1 && gm == 1 && bm == 1 && ro == 0 && go == 0 && bo == 0 && ao == 0) {
			cxm = null;
			cxa = null;
		}
	}

	// the timeline places / moves the object
	public function setFromTimeline(a:Float, b:Float, c:Float, d:Float, tx:Float, ty:Float, cx:Array<Float>) {
		if (scripted)
			return;
		ma = a;
		mb = b;
		mc = c;
		md = d;
		mtx = Math.round(tx * 20);
		mty = Math.round(ty * 20);
		csx = Math.sqrt(a * a + b * b);
		csy = Math.sqrt(c * c + d * d);
		if (a * d - b * c < 0)
			csy = -csy;
		crot = Math.atan2(b, a) * 180 / Math.PI;
		if (cx == null) {
			cxm = null;
			cxa = null;
			alpha8 = 1;
		} else {
			cxm = [cx[0], cx[1], cx[2]];
			cxa = [cx[4], cx[5], cx[6], cx[7]];
			alpha8 = cx[3];
		}
	}

	// ---------------------------------------------------------------- matrices
	// this object's matrix applied after m (m * own): the matrix from this object to the space of m
	public function concat(m:Mat):Mat {
		return new Mat(m.a * ma + m.c * mb, m.b * ma + m.d * mb, m.a * mc + m.c * md, m.b * mc + m.d * md,
			m.a * (mtx / 20) + m.c * (mty / 20) + m.tx, m.b * (mtx / 20) + m.d * (mty / 20) + m.ty);
	}

	// the matrix from this object to the top of its tree (flash.Lib.current: the stage)
	public function matrixToTop():Mat {
		var chain:Array<DisplayObject> = [];
		var o = this;
		while (o != null) {
			chain.push(o);
			o = o.parent;
		}
		var m = Mat.ident();
		var i = chain.length - 1;
		while (i >= 0) {
			m = chain[i].concat(m);
			i--;
		}
		return m;
	}

	// canvas pixels per unit of this object (the stage drawn x2): the resolution of its pictures (from the display
	// list, not from the PIXI picture: the same after a seek, when nothing was drawn)
	public function screenScale():Float {
		var m = matrixToTop();
		return Game.K * Math.sqrt(Math.abs(m.a * m.d - m.b * m.c));
	}

	// canvas pixels per unit of this object as it is shown between the last two Flash frames (f, see applyView): a
	// cell eaten in big bites is shown much larger than it is at the last frame
	public function shownScale(f:Float):Float {
		var k:Float = Game.K;
		var o = this;
		while (o != null) {
			var c = o.cur;
			if (c == null)
				k *= Math.sqrt(Math.abs(o.ma * o.md - o.mb * o.mc));
			else {
				var p = o.prev != null ? o.prev : c;
				var sx = p[2] + (c[2] - p[2]) * f;
				var sy = p[3] + (c[3] - p[3]) * f;
				k *= Math.sqrt(Math.abs(sx * sy * Math.cos(c[6])));
			}
			o = o.parent;
		}
		return k;
	}

	// mouseX / mouseY: the stage position (sx, sy) in this object's space
	public function globalToLocal(sx:Float, sy:Float):{x:Float, y:Float} {
		var inv = matrixToTop().invert();
		return {x: inv.a * sx + inv.c * sy + inv.tx, y: inv.b * sx + inv.d * sy + inv.ty};
	}

	// ---------------------------------------------------------------- display (PIXI)
	public var view(get, null):ASprite = null;

	function get_view():ASprite {
		if (view == null)
			view = makeView();
		return view;
	}

	// state of the last two Flash frames: x, y, scaleX, scaleY, rotation, alpha, skew
	var cur:Array<Float> = null;
	var prev:Array<Float> = null;
	var seenFrame:Int = -1;
	var bornFrame:Int = -1;

	// end of a Flash frame: keeps the state of the frame before (an object not seen at the frame before, just added
	// or hidden until now, starts from where it is: no slide)
	public function snapshot() {
		var fresh = seenFrame != flashFrame - 1;
		seenFrame = flashFrame;
		var old = cur;
		var sx = Math.sqrt(ma * ma + mb * mb);
		var rot = Math.atan2(mb, ma);
		var det = ma * md - mb * mc;
		var sy = Math.sqrt(mc * mc + md * md);
		if (det < 0)
			sy = -sy;
		// skew: the angle of the y axis compared with the one of a rotation
		var skew = 0.0;
		if (sy != 0) {
			var ay = Math.atan2(-mc / sy, md / sy);
			skew = rot - ay;
			while (skew > Math.PI)
				skew -= Math.PI * 2;
			while (skew < -Math.PI)
				skew += Math.PI * 2;
		}
		cur = [mtx / 20, mty / 20, sx, sy, rot, alpha8, skew];
		if (fresh || old == null)
			prev = cur;
		else {
			prev = old;
			prev[0] += jumpX;
			prev[1] += jumpY;
			if (jumpX != 0 || jumpY != 0)
				jumped = true;
		}
		jumpX = 0;
		jumpY = 0;
	}

	// jump of the position since the last snapshot that is not a move (a wrap): added to the state of the frame before
	var jumpX:Float = 0;
	var jumpY:Float = 0;
	// a jump not shown yet: the view (interpolated by the manager between two steps) does not slide either
	var jumped:Bool = false;

	// the object jumped by (dx, dy) without moving (the same place of the level's torus, the same picture of a loop):
	// the frame before is shown moved by as much, no slide across the screen
	public function shiftPrev(dx:Float, dy:Float) {
		jumpX += dx;
		jumpY += dy;
	}

	// x / y on a loop of w x h (the level's torus, the background's tiles, the starfield): a jump of whole loops is not
	// a move
	public function moveWrapped(nx:Float, ny:Float, w:Float, h:Float) {
		shiftPrev(Math.round((nx - x) / w) * w, Math.round((ny - y) / h) * h);
		x = nx;
		y = ny;
	}

	// the colour of a picture (Leaf / TextField): multipliers m and offsets a of its parents' colour transforms
	public function syncLeaf(f:Float, m:Array<Float>, a:Array<Float>, add:Bool) {}

	public inline function isFresh():Bool {
		return bornFrame == flashFrame;
	}

	// ---------------------------------------------------------------- filters / blend mode
	var shownFilters:Array<FlashFilter> = null;
	var shownKey:String = null;

	// the filters of the timeline and of the code, drawn with FlashFilter (Flash's blur and outer glow); with a blend
	// mode "add" (its own or a parent's: the title's phase, whose field glows), the filtered picture is added (the pictures
	// inside are drawn normally into the filter's bitmap). Returns whether the pictures inside are added.
	public function applyFx(v:ASprite, parentAdd:Bool):Bool {
		var list:Array<Dynamic> = [];
		var add = blendMode == "add" || parentAdd;
		if (fx >= 0) {
			var F:Dynamic = Data.get().fx[fx];
			var fl:Array<Dynamic> = F.filters;
			for (f in fl)
				list.push(f);
			if (F.blend == "add")
				add = true;
		}
		if (filters != null)
			for (f in filters)
				list.push(f);
		var used:Array<Dynamic> = [];
		for (f in list) {
			var bx:Float = f.blurX;
			var by:Float = f.blurY;
			if (f.type == "blur" && (bx >= 1 || by >= 1))
				used.push(f);
			else if (f.type == "glow" && f.inner != true && f.strength > 0)
				used.push(f);
		}
		var key = used.length == 0 ? null : [for (f in used) f.type].join(",") + (add ? "+" : "");
		if (key != shownKey) {
			shownKey = key;
			shownFilters = key == null ? null : [for (f in used) new FlashFilter(1, 1, 1, f.type == "glow")];
			v.filters = cast shownFilters;
		}
		if (shownFilters != null) {
			for (i in 0...used.length) {
				var f = used[i];
				var c:Dynamic = f.color;
				var col:Int = Std.isOfType(c, Int) ? c : c == null ? 0 : (c[0] << 16) | (c[1] << 8) | c[2];
				var passes:Int = f.passes == null ? 1 : f.passes;
				shownFilters[i].set(f.blurX, f.blurY, passes, col, f.strength == null ? 1 : f.strength);
				shownFilters[i].blendMode = (add && i == used.length - 1) ? BlendModes.ADD : BlendModes.NORMAL;
			}
			// (the pictures inside are drawn normally into the filter's bitmap)
			return false;
		}
		return add;
	}

	public function detachView() {
		if (view != null && view.parent != null)
			view.parent.removeChild(view);
	}

	public function makeView():ASprite {
		return new ASprite();
	}

	static inline function lerpAngle(a:Float, b:Float, f:Float):Float {
		var d = b - a;
		while (d > Math.PI)
			d -= Math.PI * 2;
		while (d < -Math.PI)
			d += Math.PI * 2;
		return a + d * f;
	}

	// shows the state between the last two Flash frames (f: 0 = the frame before, 1 = the last one)
	public function applyView(f:Float, ghost:Bool, snap:Bool) {
		var v = view;
		var p = prev;
		var c = cur;
		if (c == null)
			return;
		if (ghost)
			p = c;
		var s = v._curState;
		s.x = p[0] + (c[0] - p[0]) * f;
		s.y = p[1] + (c[1] - p[1]) * f;
		s.xscale = p[2] + (c[2] - p[2]) * f;
		// (a scale changing its sign is not interpolated)
		s.yscale = (p[3] < 0) != (c[3] < 0) ? c[3] : p[3] + (c[3] - p[3]) * f;
		s.rotation = lerpAngle(p[4], c[4], f);
		s.alpha = p[5] + (c[5] - p[5]) * f;
		v.skew.x = c[6];
		// (shown again, or for the first time, or across a wrap: no slide from where its view was)
		if (snap || jumped || v._prevState == null)
			v.updateState();
		jumped = false;
	}
}

// a matrix (Flash order: x' = a x + c y + tx)
class Mat {
	public var a:Float;
	public var b:Float;
	public var c:Float;
	public var d:Float;
	public var tx:Float;
	public var ty:Float;

	public inline function new(a, b, c, d, tx, ty) {
		this.a = a;
		this.b = b;
		this.c = c;
		this.d = d;
		this.tx = tx;
		this.ty = ty;
	}

	public static inline function ident():Mat {
		return new Mat(1, 0, 0, 1, 0, 0);
	}

	public function invert():Mat {
		var det = a * d - b * c;
		if (det == 0)
			return new Mat(0, 0, 0, 0, -tx, -ty);
		var ia = d / det;
		var ib = -b / det;
		var ic = -c / det;
		var id = a / det;
		return new Mat(ia, ib, ic, id, -(ia * tx + ic * ty), -(ib * tx + id * ty));
	}
}

// flash.display.Sprite (a DisplayObjectContainer)
class Sprite extends DisplayObject {
	public var children:Array<DisplayObject> = [];

	// children removed during the last Flash frame (shown until the next one), with their index
	var ghosts:Array<DisplayObject> = null;
	var ghostIdx:Array<Int> = null;
	var viewDirty:Bool = true;
	// PIXI picture of the sprite itself (its graphics: Rect), under its children
	var ownView:pixi.core.display.DisplayObject = null;

	public function new() {
		super();
	}

	public var numChildren(get, never):Int;

	function get_numChildren():Int {
		return children.length;
	}

	public function addChild(c:DisplayObject):DisplayObject {
		if (c.parent != null)
			c.parent.removeChild(c);
		children.push(c);
		attached(c);
		return c;
	}

	public function addChildAt(c:DisplayObject, i:Int):DisplayObject {
		if (c.parent != null)
			c.parent.removeChild(c);
		if (i > children.length)
			throw new FlashError("RangeError: addChildAt");
		children.insert(i, c);
		attached(c);
		return c;
	}

	function attached(c:DisplayObject) {
		untyped c.parent = this;
		// (added during this Flash frame: not shown before the display reaches it)
		untyped c.bornFrame = DisplayObject.flashFrame;
		viewDirty = true;
		if (ghosts != null) {
			var gi = ghosts.indexOf(c);
			if (gi >= 0) {
				ghosts.splice(gi, 1);
				ghostIdx.splice(gi, 1);
			}
		}
	}

	public function removeChild(c:DisplayObject):DisplayObject {
		var i = children.indexOf(c);
		if (i < 0)
			throw new FlashError("ArgumentError: Error #2025: The supplied DisplayObject must be a child of the caller.");
		children.splice(i, 1);
		untyped c.parent = null;
		if (c.cur != null && c.seenFrame >= DisplayObject.flashFrame - 1) {
			// shown (at its last state) until the next Flash frame
			if (ghosts == null) {
				ghosts = [];
				ghostIdx = [];
				withGhosts.push(this);
			}
			ghosts.push(c);
			ghostIdx.push(i);
		} else
			c.detachView();
		viewDirty = true;
		return c;
	}

	public function getChildIndex(c:DisplayObject):Int {
		var i = children.indexOf(c);
		if (i < 0)
			throw new FlashError("ArgumentError: getChildIndex");
		return i;
	}

	public function getChildAt(i:Int):DisplayObject {
		if (i < 0 || i >= children.length)
			throw new FlashError("RangeError: getChildAt");
		return children[i];
	}

	// ---------------------------------------------------------------- display
	static var withGhosts:Array<Sprite> = [];

	// start of a Flash frame: the objects removed during the last one are no longer shown
	public static function clearGhosts() {
		for (s in withGhosts) {
			if (s.ghosts == null)
				continue;
			for (g in s.ghosts)
				if (g.parent == null)
					g.detachView();
			s.ghosts = null;
			s.ghostIdx = null;
			s.viewDirty = true;
		}
		withGhosts = [];
	}

	public static function resetAll() {
		withGhosts = [];
		DisplayObject.flashFrame = 0;
	}

	// end of a Flash frame: the state of every object (the hidden ones are not drawn: their state is taken when they
	// are shown again, without a slide)
	public function snapshotTree() {
		snapshot();
		for (c in children) {
			if (!c.visible)
				continue;
			var s = Std.downcast(c, Sprite);
			if (s != null)
				s.snapshotTree();
			else
				c.snapshot();
		}
	}

	// shows the tree; cxm / cxa: the colour transform of the parents, add: drawn with the blend mode "add"
	public function syncTree(f:Float, cxm:Array<Float>, cxa:Array<Float>, add:Bool, ghost:Bool, snap:Bool) {
		if (viewDirty) {
			viewDirty = false;
			rebuildViews();
		}
		syncOwn(f, cxm, cxa, add);
		for (c in children)
			syncChild(c, f, cxm, cxa, add, ghost, snap);
		if (ghosts != null)
			for (g in ghosts)
				syncChild(g, f, cxm, cxa, add, true, snap);
	}

	// the sprite's own picture (Rect)
	function syncOwn(f:Float, m:Array<Float>, a:Array<Float>, add:Bool) {}

	function syncChild(c:DisplayObject, f:Float, pm:Array<Float>, pa:Array<Float>, add:Bool, ghost:Bool, snap:Bool) {
		var v = c.view;
		var hide = !c.visible || (c.isFresh() && !ghost) || c.cur == null;
		var sn = snap || !v.visible;
		v.visible = !hide;
		if (hide)
			return;
		// the colour transform of the child: its own applied first, then the parents'
		var m = pm;
		var a = pa;
		if (c.cxm != null) {
			m = [c.cxm[0] * pm[0], c.cxm[1] * pm[1], c.cxm[2] * pm[2]];
			a = [c.cxa[0] * pm[0] + pa[0], c.cxa[1] * pm[1] + pa[1], c.cxa[2] * pm[2] + pa[2], 0];
		}
		c.applyView(f, ghost, sn);
		var cadd = c.applyFx(v, add);
		var s = Std.downcast(c, Sprite);
		if (s != null)
			s.syncTree(f, m, a, cadd, ghost, sn);
		else
			c.syncLeaf(f, m, a, cadd);
	}

	// the views of the children in the order of the display list
	function rebuildViews() {
		var v = view;
		var list:Array<DisplayObject> = children.copy();
		if (ghosts != null)
			for (k in 0...ghosts.length)
				list.insert(Std.int(Math.min(ghostIdx[k], list.length)), ghosts[k]);
		var wanted:Array<pixi.core.display.DisplayObject> = ownView != null ? [ownView] : [];
		for (c in list)
			wanted.push(c.view);
		for (ch in v.children.copy())
			if (wanted.indexOf(ch) < 0)
				v.removeChild(ch);
		for (i in 0...wanted.length) {
			var w = wanted[i];
			if (w.parent != v || v.getChildIndex(w) != i) {
				if (w.parent != null)
					w.parent.removeChild(w);
				v.addChildAt(w, Std.int(Math.min(i, v.children.length)));
			}
		}
	}
}

// a Sprite whose graphics are a filled rectangle (graphics.beginFill(color, alpha); drawRect(x, y, w, h))
class Rect extends Sprite {
	var rx:Float;
	var ry:Float;
	var rw:Float;
	var rh:Float;
	var color:Int;
	var fillAlpha:Float;
	var pic:PSprite;

	public function new(x:Float, y:Float, w:Float, h:Float, color:Int, fillAlpha:Float = 1.0) {
		super();
		rx = x;
		ry = y;
		rw = w;
		rh = h;
		this.color = color;
		this.fillAlpha = fillAlpha;
		if (fillAlpha > 0) {
			pic = new PSprite(Texture.WHITE);
			pic.x = rx;
			pic.y = ry;
			pic.width = rw;
			pic.height = rh;
			ownView = pic;
		}
	}

	override function syncOwn(f:Float, m:Array<Float>, a:Array<Float>, add:Bool) {
		if (pic == null)
			return;
		var r = ((color >> 16) & 0xFF) * m[0] + a[0];
		var g = ((color >> 8) & 0xFF) * m[1] + a[1];
		var b = (color & 0xFF) * m[2] + a[2];
		pic.tint = (c8(r) << 16) | (c8(g) << 8) | c8(b);
		pic.alpha = fillAlpha;
		pic.blendMode = add ? BlendModes.ADD : BlendModes.NORMAL;
	}

	static inline function c8(v:Float):Int {
		return v <= 0 ? 0 : v >= 255 ? 255 : Std.int(v + 0.5);
	}
}

// the place of a plan of a DepthManager (flash.display.Shape, invisible): nothing drawn
class Marker extends DisplayObject {
	public function new(n:String) {
		super();
		name = n;
		visible = false;
	}
}

// an error the Flash player would have thrown: the rest of the frame's code is skipped (Game.flashFrame)
class FlashError {
	public var msg:String;

	public function new(m:String) {
		msg = m;
	}

	public function toString():String {
		return msg;
	}
}
