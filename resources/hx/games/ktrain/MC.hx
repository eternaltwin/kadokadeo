package ktrain;

import pixi.core.Pixi.BlendModes;

// a filter of the Flash 8 `filters` array the code sets (BlurFilter quality 1, ColorMatrixFilter)
enum FilterSpec {
	Blur(bx:Float, by:Float);
	ColorMatrix(m:Array<Float>);
}

// getBounds: [xMin, yMin, xMax, yMax] (Flash pixels)
typedef Rect = Array<Float>;

/**
 * A MovieClip attached by the game code (DepthManager.attach / empty, attachMovie): the Flash properties the code
 * reads and writes (_x / _y truncated to twips like Flash, _xscale, _rotation, _alpha, _width / _height, getBounds,
 * hitTest, depths), the fields the code adds to it (y, d, gem...), and the Clip that draws it.
 *
 * Flash rules the code relies on: a removed clip reads undefined (NaN in a calculation, false in a test, its fields
 * too: a collected gem that has faded out is no longer a gem) and ignores what is written to it; getBounds is the
 * rectangle of every shape of the clip through the matrices, the hit zones included (invisible: blend mode "alpha"),
 * measured on the SWF (Data.bounds / Data.sub); an empty clip has no bounds (no hit, _width 0).
 *
 * Display: K-Train ran at 40 Flash frames/s and KadoKadeo steps 32 times per second, so a step plays 1 or 2 Flash
 * frames (Game.update). Like Cosmo Crash, every clip shows its state one Flash frame ago, interpolated towards the last
 * one by the fraction of a Flash frame the steps are behind (displayAll): the game moves by exactly 1.25 Flash frames
 * per step. The pictures of the timelines are the current ones. A removed clip is still shown until the picture has
 * reached its removal (ghosts), like a new one is hidden until it reaches its creation: the ground scene removed when it
 * has gone down past the screen is still on the screen in the picture one Flash frame ago.
 */
class MC {
	public static var all:Array<MC> = [];
	// removed clips still shown (displayAll), the Flash frames started, the time (in Flash frames) of the last picture
	static var ghosts:Array<MC> = [];
	static var frameNo:Int = 0;
	static var shownT:Float = 0;

	public var clip(default, null):Clip;
	// the symbol (for the measures of Data)
	public var name(default, null):String;

	public var _x(get, set):Float;
	public var _y(get, set):Float;
	public var _xscale(get, set):Float;
	public var _yscale(get, set):Float;
	public var _rotation(get, set):Float;
	public var _alpha(get, set):Float;
	public var _visible(get, set):Bool;
	public var _currentframe(get, never):Int;
	public var _totalframes(get, never):Int;
	public var _width(get, never):Float;
	public var _height(get, never):Float;

	// removeMovieClip() was called (by the code, a frame script or the removal of its parent): Flash's _name == null
	public var removed(default, null):Bool = false;

	// fields the original adds to its clips (typedefs Ob, DOb, Idx, Bmp, M, P of Common.hx): undefined on a removed clip
	public var y(get, set):Null<Float>;
	public var d(get, set):Dynamic;
	public var gem(get, set):Null<Bool>;
	public var piouz(get, set):Null<Bool>;
	public var idx(get, set):Null<Int>;
	public var type(get, set):Null<Int>;
	public var disposed(get, set):Null<Bool>;
	public var rotation(get, set):Null<Float>;
	public var bmp:Bmp;
	public var obj:Dynamic;

	var fy:Null<Float>;
	var fd:Dynamic;
	var fgem:Null<Bool>;
	var fpiouz:Null<Bool>;
	var fidx:Null<Int>;
	var ftype:Null<Int>;
	var fdisposed:Null<Bool>;
	var frotation:Null<Float>;

	// depth in its parent (getDepth) and the parent (Holder of the game root or of an empty clip)
	public var depth(default, null):Int = 0;
	public var holder(default, null):Holder;
	// an empty clip holding clips or a bitmap
	public var kids(default, null):Holder;

	var x:Float = 0;
	var y_:Float = 0;
	var xs:Float = 100;
	var ys:Float = 100;
	var rot:Float = 0;
	var alpha:Float = 100;
	var vis:Bool = true;
	var blend:String = null;
	var filterList:Array<FilterSpec> = [];
	var filtersShown:String = "";

	// state of the previous Flash frame (display)
	var fresh:Bool = true;
	var snap:Bool = false;
	var px:Float = 0;
	var py:Float = 0;
	var pxs:Float = 100;
	var pys:Float = 100;
	var prot:Float = 0;
	var pa:Float = 100;
	// the Flash frame that removed it (ghost)
	var goneAt:Int = 0;

	public function new(name:String) {
		this.name = name;
		clip = new Clip(name);
		clip.owner = this;
		all.push(this);
	}

	// ---------------------------------------------------------------- Flash properties
	function get__x():Float {
		return removed ? Math.NaN : x;
	}

	function set__x(v:Float):Float {
		if (!removed && Math.isFinite(v))
			x = twips(v);
		return v;
	}

	function get__y():Float {
		return removed ? Math.NaN : y_;
	}

	function set__y(v:Float):Float {
		if (!removed && Math.isFinite(v))
			y_ = twips(v);
		return v;
	}

	function get__xscale():Float {
		return removed ? Math.NaN : xs;
	}

	function set__xscale(v:Float):Float {
		if (!removed && Math.isFinite(v))
			xs = v;
		return v;
	}

	function get__yscale():Float {
		return removed ? Math.NaN : ys;
	}

	function set__yscale(v:Float):Float {
		if (!removed && Math.isFinite(v))
			ys = v;
		return v;
	}

	function get__rotation():Float {
		return removed ? Math.NaN : rot;
	}

	// Flash keeps the rotation of the matrix, read back in ]-180, 180]
	function set__rotation(v:Float):Float {
		if (removed || !Math.isFinite(v))
			return v;
		v = v % 360;
		if (v > 180)
			v -= 360;
		else if (v <= -180)
			v += 360;
		rot = v;
		return v;
	}

	function get__alpha():Float {
		return removed ? Math.NaN : alpha;
	}

	function set__alpha(v:Float):Float {
		if (!removed && Math.isFinite(v))
			alpha = v;
		return v;
	}

	function get__visible():Bool {
		return !removed && vis;
	}

	function set__visible(v:Bool):Bool {
		if (!removed)
			vis = v;
		return v;
	}

	// (a value written to _x is kept in twips: truncated to 1 / 20 of a pixel)
	public static inline function twips(v:Float):Float {
		return Std.int(v * 20) / 20;
	}

	// (undefined for a removed clip: -1 is never equal to a frame)
	function get__currentframe():Int {
		return removed ? -1 : clip.frame;
	}

	function get__totalframes():Int {
		return clip.def.n;
	}

	function get__width():Float {
		if (removed)
			return Math.NaN;
		var b = getBounds();
		return b == null ? 0 : b[2] - b[0];
	}

	function get__height():Float {
		if (removed)
			return Math.NaN;
		var b = getBounds();
		return b == null ? 0 : b[3] - b[1];
	}

	function get_y():Null<Float>
		return removed ? null : fy;

	function set_y(v:Null<Float>):Null<Float> {
		if (!removed)
			fy = v;
		return v;
	}

	function get_d():Dynamic
		return removed ? null : fd;

	function set_d(v:Dynamic):Dynamic {
		if (!removed)
			fd = v;
		return v;
	}

	function get_gem():Null<Bool>
		return removed ? null : fgem;

	function set_gem(v:Null<Bool>):Null<Bool> {
		if (!removed)
			fgem = v;
		return v;
	}

	function get_piouz():Null<Bool>
		return removed ? null : fpiouz;

	function set_piouz(v:Null<Bool>):Null<Bool> {
		if (!removed)
			fpiouz = v;
		return v;
	}

	function get_idx():Null<Int>
		return removed ? null : fidx;

	function set_idx(v:Null<Int>):Null<Int> {
		if (!removed)
			fidx = v;
		return v;
	}

	function get_type():Null<Int>
		return removed ? null : ftype;

	function set_type(v:Null<Int>):Null<Int> {
		if (!removed)
			ftype = v;
		return v;
	}

	function get_disposed():Null<Bool>
		return removed ? null : fdisposed;

	function set_disposed(v:Null<Bool>):Null<Bool> {
		if (!removed)
			fdisposed = v;
		return v;
	}

	function get_rotation():Null<Float>
		return removed ? null : frotation;

	function set_rotation(v:Null<Float>):Null<Float> {
		if (!removed)
			frotation = v;
		return v;
	}

	public function gotoAndStop(f:Dynamic):Void {
		if (!removed)
			clip.gotoAndStop(f);
	}

	public function play():Void {
		if (!removed)
			clip.play();
	}

	// port: the same timeline with other pictures (mcSmoke: smc.smc.gotoAndStop(n) picks the puff; mcBonus: smc.text
	// is the price)
	public function setDef(name:String) {
		if (!removed) {
			this.name = name;
			clip.setDef(name);
		}
	}

	// mc.sub._x = ... (Flash pixels of this clip)
	public function setSub(name:String, ?x:Float, ?y:Float, ?xscale:Float, ?yscale:Float, ?rotation:Float) {
		if (!removed)
			clip.setSub(name, x, y, xscale, yscale, rotation);
	}

	public function sub(name:String):Clip {
		return removed ? null : clip.getClip(name);
	}

	// mc.blendMode = "multiply" (shadows). Loco's "substract" (sic) is not a blend mode name: Flash ignores it, the train
	// behind is drawn normally (red: its colour matrix)
	public function setBlend(b:String) {
		if (removed)
			return;
		blend = b;
		applyEffects();
	}

	// mc.filters (a copy: Filt.blur pushes a new filter on the list it read and writes the list back)
	public function getFilters():Array<FilterSpec> {
		return removed ? [] : filterList.copy();
	}

	public function setFilters(l:Array<FilterSpec>) {
		if (removed)
			return;
		filterList = l.copy();
		applyEffects();
	}

	function applyEffects() {
		var key = Std.string(filterList);
		var mode = switch (blend) {
			case "multiply": BlendModes.MULTIPLY;
			case _: BlendModes.NORMAL;
		}
		// the smoke: only a vertical blur on a clip of one picture, drawn by its picture (VBlur): the box of `by` stage
		// pixels in texels of the picture (scaled by the clip's _yscale)
		if (filterList.length == 1 && clip.def.simple)
			switch (filterList[0]) {
				case Blur(bx, by) if (bx < 2 && ys > 0):
					filtersShown = key;
					clip.filters = null;
					clip.setVBlur(by * Clip.K * clip.def.r * 100 / ys);
					clip.setBlend(mode);
					return;
				case _:
			}
		if (key != filtersShown) {
			filtersShown = key;
			var out:Array<Dynamic> = [];
			var bx = [], by = [];
			for (f in filterList)
				switch (f) {
					case Blur(x, y):
						bx.push(x);
						by.push(y);
					case ColorMatrix(m):
						out.push(new FlashColorMatrix(m));
				}
			if (bx.length > 0)
				out.unshift(new FlashBlur(bx, by));
			clip.filters = out.length > 0 ? cast out : null;
		}
		// PIXI draws a filtered clip with the blend mode of its last filter (inside the filter the clip is drawn alone)
		var fl:Array<Dynamic> = cast clip.filters;
		if (fl != null && fl.length > 0) {
			clip.setBlend(BlendModes.NORMAL);
			for (f in fl)
				f.blendMode = BlendModes.NORMAL;
			fl[fl.length - 1].blendMode = mode;
		} else {
			clip.setBlend(mode);
		}
	}

	// ---------------------------------------------------------------- measures (Flash getBounds in the game root)
	// the rectangle of the clip on its current frame through its matrix (null: no shape)
	public function getBounds():Rect {
		if (removed)
			return null;
		var t:Array<Dynamic> = Reflect.field(Data.bounds(), name);
		if (t == null)
			throw 'no bounds for ' + name;
		var r:Rect = t[clip.frame - 1];
		return r == null ? null : transform(r);
	}

	// the rectangle of a named child (hit1, hit2, smc) on the current frame (null: no such child, or this clip removed)
	public function getSubBounds(child:String):Rect {
		if (removed)
			return null;
		var s:Dynamic = Reflect.field(Data.sub(), name);
		var t:Array<Dynamic> = s != null ? Reflect.field(s, child) : null;
		if (t == null)
			return null;
		var r:Rect = t[clip.frame - 1];
		return r == null ? null : transform(r);
	}

	// mc.hit1 != null
	public function hasSub(child:String):Bool {
		return getSubBounds(child) != null;
	}

	// (Flash transforms the corners of the rectangle, in twips)
	function transform(r:Rect):Rect {
		var a = xs / 100, dd = ys / 100;
		if (rot == 0) {
			var x0 = r[0] * a + x, x1 = r[2] * a + x;
			var y0 = r[1] * dd + y_, y1 = r[3] * dd + y_;
			return [tw(Math.min(x0, x1)), tw(Math.min(y0, y1)), tw(Math.max(x0, x1)), tw(Math.max(y0, y1))];
		}
		var rr = rot * Math.PI / 180;
		var c = Math.cos(rr), s = Math.sin(rr);
		var xmin = Math.POSITIVE_INFINITY, ymin = Math.POSITIVE_INFINITY, xmax = Math.NEGATIVE_INFINITY, ymax = Math.NEGATIVE_INFINITY;
		for (px in [r[0], r[2]])
			for (py in [r[1], r[3]]) {
				var tx = c * a * px - s * dd * py + x;
				var ty = s * a * px + c * dd * py + y_;
				xmin = Math.min(xmin, tx);
				xmax = Math.max(xmax, tx);
				ymin = Math.min(ymin, ty);
				ymax = Math.max(ymax, ty);
			}
		return [tw(xmin), tw(ymin), tw(xmax), tw(ymax)];
	}

	static inline function tw(v:Float):Float {
		return Math.round(v * 20) / 20;
	}

	// MovieClip.hitTest(target): the bounding boxes in the stage overlap (touching counts)
	public function hitTest(o:MC):Bool {
		var a = getBounds();
		var b = o == null ? null : o.getBounds();
		if (a == null || b == null)
			return false;
		return a[0] <= b[2] && a[2] >= b[0] && a[1] <= b[3] && a[3] >= b[1];
	}

	// ---------------------------------------------------------------- display list
	public function getDepth():Null<Int> {
		return removed ? null : depth;
	}

	// mc.swapDepths(depth): the clip at that depth (if any) takes this clip's depth
	public function swapDepths(target:Int) {
		if (removed || holder == null || target == depth)
			return;
		holder.swap(this, target);
	}

	// mc.swapDepths(other)
	public function swapWith(o:MC) {
		if (removed || o == null || o.removed || o.holder != holder)
			return;
		holder.swap(this, o.depth);
	}

	// (its kids first: the ghosts are destroyed in this order. Removed during the Flash frame that created it: never
	// shown, destroyed now)
	public function removeMovieClip():Void {
		if (removed)
			return;
		removed = true;
		if (kids != null)
			kids.clear();
		if (holder != null)
			holder.forget(this);
		if (fresh) {
			destroyClip();
		} else {
			goneAt = frameNo;
			ghosts.push(this);
		}
	}

	function destroyClip() {
		if (bmp != null)
			bmp.detach();
		clip.removeMovieClip();
		clip.destroy({children: true});
	}

	// a move made at once (the rails placed above the screen when they are shown): shown where it is now, not
	// interpolated from where it was
	public function teleport():Void {
		px = x;
		py = y_;
		pxs = xs;
		pys = ys;
		prot = rot;
		pa = alpha;
		snap = true;
	}

	// createEmptyMovieClip / attachMovie inside this clip (its children are in Flash pixels)
	public function getKids():Holder {
		if (kids == null)
			kids = new Holder(clip);
		return kids;
	}

	// mc.attachBitmap(bmp, depth): the bitmap shown in this (empty) clip
	public function attachBitmap(b:Bmp, depth:Int) {
		if (removed)
			return;
		b.attach(clip);
	}

	// ---------------------------------------------------------------- Flash frames and display
	// a Flash frame starts: the state shown keeps the last one, every timeline advances (before the code runs), then
	// the clips removed by their frame scripts are taken out
	public static function frameStart():Void {
		frameNo++;
		var i = 0;
		while (i < all.length) {
			var m = all[i];
			if (m.removed) {
				all.splice(i, 1);
				continue;
			}
			m.fresh = false;
			m.px = m.x;
			m.py = m.y_;
			m.pxs = m.xs;
			m.pys = m.ys;
			m.prot = m.rot;
			m.pa = m.alpha;
			i++;
		}
		for (m in all.copy())
			if (!m.removed)
				m.clip.tick();
		Clip.flushRemoved();
	}

	public static function displayAll(f:Float):Void {
		for (m in all)
			if (!m.removed)
				m.display(f);
		// the picture before was at or after its removal: gone (the renderer interpolates from that picture)
		var t = frameNo - 1 + f;
		var i = 0;
		while (i < ghosts.length) {
			var g = ghosts[i];
			if (shownT >= g.goneAt) {
				ghosts.splice(i, 1);
				g.destroyClip();
				continue;
			}
			var gf = t - (g.goneAt - 1);
			g.display(gf < 0 ? 0 : gf > 1 ? 1 : gf);
			i++;
		}
		shownT = t;
	}

	function display(f:Float):Void {
		var s = clip;
		// attached during the last Flash frame: the picture shown is still before it (f = 1: the start of the game);
		// shown from the next step, not interpolated from where it was created
		var hide = fresh && f < 1;
		if (fresh)
			f = 1;
		s._x = px + (x - px) * f;
		s._y = py + (y_ - py) * f;
		s._xscale = pxs + (xs - pxs) * f;
		s._yscale = pys + (ys - pys) * f;
		var dr = rot - prot;
		if (dr > 180)
			dr -= 360;
		else if (dr < -180)
			dr += 360;
		s._rotation = prot + dr * f;
		var a = pa + (alpha - pa) * f;
		s._alpha = a < 0 ? 0 : a > 100 ? 100 : a;
		if (snap && s._prevState != null)
			s._prevState.copyFrom(s._curState);
		snap = hide;
		s.visible = vis && !hide && !s.selfRemoved;
	}

	public static function clearAll():Void {
		for (m in all.copy())
			m.removeMovieClip();
		all = [];
		for (g in ghosts)
			g.destroyClip();
		ghosts = [];
	}
}

/**
 * The children of a Flash 8 MovieClip by depth (attachMovie, createEmptyMovieClip, swapDepths): the game root (the
 * original's DepthManager works on it with depths plan * 1000 + n) or an empty clip. PIXI draws them in depth order.
 */
class Holder {
	var container:common_haxe_avm1.display.ASprite;
	var byDepth:Map<Int, MC> = new Map();
	var order:Array<MC> = [];

	public function new(container:common_haxe_avm1.display.ASprite) {
		this.container = container;
	}

	// attachMovie(name, newName, depth): a clip already at that depth is replaced (removed)
	public function attachMovie(name:String, depth:Int):MC {
		var old = byDepth.get(depth);
		if (old != null)
			old.removeMovieClip();
		var mc = new MC(name);
		untyped mc.holder = this;
		untyped mc.depth = depth;
		byDepth.set(depth, mc);
		insert(mc);
		return mc;
	}

	public function createEmptyMovieClip(depth:Int):MC {
		return attachMovie(Clip.EMPTY, depth);
	}

	function insert(mc:MC) {
		var i = 0;
		while (i < order.length && order[i].depth < mc.depth)
			i++;
		order.insert(i, mc);
		// (after the clip below it: the ghosts are still in the container)
		var at = i == 0 ? 0 : container.getChildIndex(order[i - 1].clip) + 1;
		container.addChildAt(mc.clip, Std.int(Math.min(at, container.children.length)));
	}

	public function swap(mc:MC, target:Int) {
		var other = byDepth.get(target);
		var from = mc.depth;
		byDepth.remove(from);
		order.remove(mc);
		if (other != null) {
			order.remove(other);
			untyped other.depth = from;
			byDepth.set(from, other);
		}
		untyped mc.depth = target;
		byDepth.set(target, mc);
		if (other != null) {
			container.removeChild(other.clip);
			insert(other);
		}
		container.removeChild(mc.clip);
		insert(mc);
	}

	public function forget(mc:MC) {
		if (byDepth.get(mc.depth) == mc)
			byDepth.remove(mc.depth);
		order.remove(mc);
	}

	public function clear() {
		for (m in order.copy())
			m.removeMovieClip();
	}
}
