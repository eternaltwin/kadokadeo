package pacifik;

import pixi.core.display.Container;
import pixi.core.sprites.Sprite as PixiSprite;
import pixi.core.textures.RenderTexture;

/**
 * mcCanon: the box (depth 1), smc (mcFire, depth 2: the barrel the code turns and slides) and the ring with its struts
 * (depth 4). The frame (1 to 3: the shield) is given to the box, the ring and, by the code, to smc.
 * getBounds / _width measure every shape through its matrices (Flash: each shape's rectangle through its whole matrix).
 *
 * Display: the code gives every canon a GradientGlowFilter and a DropShadowFilter (Canon.update). With up to 24 canons
 * these filters at every render took ~5 ms of GPU per frame. A canon only changes while its barrel turns or recoils:
 * its pieces and their filters are drawn off screen into a texture of its own (cache) when they change, and that
 * texture is shown. The cache is drawn just before the screen (flushAll, Game.flushListener), with the interpolation
 * the screen gets (the barrel turns smoothly between two steps, in step with the rest). The filters are drawn in the coordinates of the canon (they are
 * the same turned by 180 degrees: blurs, and a shadow at distance 0).
 */
class CanonMC extends MC {
	// half the side of the cache, in Flash pixels: the barrel turned any way and recoiled (~31), and the blurs of the
	// glow (6) and of the shadow (2) around it
	static inline var HALF = 42.0;

	static var live:Array<CanonMC> = [];
	// (test harness, debug builds: window.__pkNoCache = true draws the canons on the stage with their filters, to
	// compare)
	var useCache:Bool = true;

	public var back:MC;
	public var smc:MC;
	public var front:MC;

	var content:ASprite;
	// content scaled and centred in the cache (renderer.render with a `transform` misplaces the filters in PixiJS 6.0.2:
	// they came out blurred)
	var wrap:Container;
	var view:PixiSprite;
	var cache:RenderTexture = null;
	var cacheScale:Float = 0;
	var cacheRes:Float = 0;
	var shown:String = null;

	public function new() {
		content = new ASprite();
		super();
		#if debug
		useCache = untyped js.Browser.window.__pkNoCache != true;
		if (!useCache)
			spr.addChild(content);
		#end
		wrap = new Container();
		#if debug
		if (useCache)
		#end
		wrap.addChild(content);
		view = new PixiSprite();
		view.anchor.set(0.5, 0.5);
		spr.addChild(view);
		live.push(this);
		_totalframes = 3;
		back = attach(new MC("canonb", Game.K));
		smc = attach(new MC("fire", Game.K));
		front = attach(new MC("canonf", Game.K));
		back.gotoAndStop(1);
		smc.gotoAndStop(1);
		front.gotoAndStop(1);
	}

	override public function gotoAndStop(f:Int):Void {
		super.gotoAndStop(f);
		back.gotoAndStop(_currentframe);
		front.gotoAndStop(_currentframe);
	}

	override function holder():ASprite {
		return content;
	}

	override function filterTarget():ASprite {
		return content;
	}

	override function onDestroy():Void {
		live.remove(this);
		if (cache != null)
			cache.destroy(true);
		cache = null;
		if (content != null) {
			content.filters = null;
			content.destroy({children: true});
		}
		content = null;
		if (wrap != null)
			wrap.destroy();
		wrap = null;
	}

	public static function clearAll():Void {
		live = [];
	}

	// at the start of a step, like KadoKadeo does for the stage: the state shown so far becomes the previous one of
	// the interpolation (the pieces in the cache are not on the stage)
	public static function stepAll():Void {
		for (c in live)
			if (c.content != null && c.useCache)
				c.content.updateState();
	}

	// before the render, after the interpolation of the stage (a: its fraction between two steps): the canons whose
	// picture changed are drawn again into their cache
	public static function flushAll(a:Float):Void {
		for (c in live)
			c.flush(a);
	}

	function flush(a:Float):Void {
		if (!useCache)
			return;
		if (spr == null || content == null || !spr.visible)
			return;
		var renderer:Dynamic = KadoKadeoManager.kkm.renderer;
		var S = FlashFilters.scale();
		var res:Float = renderer.resolution;
		// what the cache shows: the pictures and places of the pieces, the filters
		content.updateGraphics(a);
		var key = S + ":" + res + ":" + (content.filters == null ? 0 : content.filters.length);
		for (m in [back, smc, front]) {
			var p = m.spr;
			key += "|" + p.texture.textureCacheIds + ":" + p.position.x + "," + p.position.y + "," + p.rotation + "," + p.visible;
		}
		if (key == shown && cache != null)
			return;
		if (cache == null || S != cacheScale || res != cacheRes) {
			if (cache != null)
				cache.destroy(true);
			var side = Math.ceil(HALF * 2 * S);
			cache = (cast RenderTexture : Dynamic).create({width: side, height: side, resolution: res});
			cacheScale = S;
			cacheRes = res;
			view.texture = cache;
			view.scale.set(1 / S, 1 / S);
		}
		shown = key;
		wrap.scale.set(S, S);
		wrap.position.set(HALF * S, HALF * S);
		renderer.render(wrap, {renderTexture: cache, clear: true});
	}

	// the shapes in the coordinates of the canon
	function local():Array<Float> {
		var r = Const.union(Data.CANON_BACK[_currentframe - 1], Data.CANON_FRONT[_currentframe - 1]);
		return Const.union(r, smcRect());
	}

	// the barrel's shape in the canon (smc's matrix: its rotation, its position)
	function smcRect():Array<Float> {
		var m = Const.rotMatrix(smc._rotation, smc._xscale, smc._yscale);
		return Const.through(Data.FIRE[smc._currentframe - 1], m[0], m[1], m[2], m[3], smc._x, smc._y);
	}

	// getBounds(root)
	public function bounds():Array<Float> {
		if (removed)
			return null;
		var m = Const.rotMatrix(_rotation, _xscale, _yscale);
		var out:Array<Float> = null;
		for (r in [Data.CANON_BACK[_currentframe - 1], Data.CANON_FRONT[_currentframe - 1], smcRect()]) {
			var b = Const.through(r, m[0], m[1], m[2], m[3], _x, _y);
			out = out == null ? b : Const.union(out, b);
		}
		return out;
	}

	// mc._width
	public function width():Float {
		var b = bounds();
		return b == null ? Math.NaN : b[1] - b[0];
	}

	// mc.smc._width (in the canon)
	public function smcWidth():Float {
		var r = smcRect();
		return r[1] - r[0];
	}
}

// mcBall: 3 frames (the ball types; the bonus plays them)
class BallMC extends MC {
	public function new() {
		super("ball", Game.K);
	}

	// getBounds(root): the shape of the frame at the clip's place (no rotation, no scale)
	public function bounds():Array<Float> {
		if (removed)
			return null;
		var r = Data.BALL[_currentframe - 1];
		return Const.through(r, 1, 0, 0, 1, _x, _y);
	}

	public function width():Float {
		var r = Data.BALL[_currentframe - 1];
		return r[1] - r[0];
	}
}

/**
 * mcCar (the ship): 5 frames, the code stops it on one. Its visible picture is drawn from the sheet; smc (mcHitShip)
 * and r1 / r2 (mcReactor) are invisible markers whose places the code reads (Data.CAR_*).
 */
class CarMC extends MC {
	public function new() {
		super("car", Game.K);
	}

	// _height: every shape of the frame (the markers too)
	public function height():Float {
		var b = Data.CAR_BOUNDS[_currentframe - 1];
		return Math.round((b[3] - b[2]) * 20) / 20;
	}

	public function r1():Array<Float> {
		return Data.CAR_R1[_currentframe - 1];
	}

	public function r2():Array<Float> {
		return Data.CAR_R2[_currentframe - 1];
	}

	// smc.getBounds(root)
	public function smcBounds():Array<Float> {
		if (removed)
			return null;
		var p = Data.CAR_SMC[_currentframe - 1];
		return Const.through(Data.HIT_SHIP, 1, 0, 0, 1, _x + p[0], _y + p[1]);
	}

	public function smcWidth():Float {
		return Data.HIT_SHIP[1] - Data.HIT_SHIP[0];
	}

	public function smcHeight():Float {
		return Data.HIT_SHIP[3] - Data.HIT_SHIP[2];
	}
}

// mcOnde: 3 frames, each its own picture (frame 3 is the dock's), with the fields of the code (VV)
class OndeMC extends MC {
	public var top:Bool;
	public var speed:Float;
	public var sleep:Float;
	public var a:Float;

	public function new() {
		super(null, 1);
		frames = Tex.get("onde1").concat(Tex.get("onde2")).concat(Tex.get("dock"));
		_totalframes = frames.length;
		showFrame();
	}

	public function height():Float {
		return Data.ONDE_HEIGHTS[_currentframe - 1];
	}
}

// mcScore: its field s ("[") shows the score of a ball (pictures of the 4 scores), in the code's textColor
class ScoreMC extends MC {
	public function new(score:Int, color:Int) {
		super("score", Game.K);
		var i = Data.SCORES.indexOf(Std.string(score));
		gotoAndStop(i + 1);
		tint = color;
	}
}
