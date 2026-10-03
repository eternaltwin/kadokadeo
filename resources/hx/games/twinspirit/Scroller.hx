package twinspirit;

import pixi.core.Pixi.BlendModes;
import pixi.core.sprites.Sprite as PixiSprite;
import pixi.core.textures.Texture;

private typedef Cloud = {x:Float, y:Float, f:Int, sc:Float, spr:PixiSprite, add:PixiSprite};

// one layer of clouds: drawn in bitmaps in the original (5 to 24 thousand pixels high), here the clouds are
// remembered and only those on the screen are shown
private class Parallax extends ASprite {
	public var coef:Float;
	public var h:Float;
	public var max:Int;
	public var clouds:Array<Cloud>;
	public var lastY:Float;

	public function new() {
		super();
		clouds = [];
		lastY = 0;
	}
}

class Scroller {
	public static var HIGHSPEED = 20;
	public static var SPEED = 1;
	public static var BGH = 1200;
	public static var BITMAP_HEIGHT = 1000;

	// heights of the 5 clouds of mcNuage (brush._height: without their blur)
	static var CLOUD_H = [98.15, 159.4, 128.5, 112.6, 174.7];

	public var pos:Float;
	public var startPos:Int;
	public var speed:Float;
	public var bgh:Float;

	public var root:ASprite;
	public var bg:ASprite;

	var parallax:Array<Parallax>;
	var nuage:Array<Texture>;
	var nuageW:Array<Texture>;

	public function new() {
		root = Game.me.dm.empty(Game.DP_BG);
		startPos = BGH - 100;
		pos = startPos;
		speed = 0;
		parallax = [];
		nuage = Tex.get("nuage");
		nuageW = Tex.get("nuageW");
		initBg();
		for (k in 0...5)
			while (!addParallax(k, 5)) {}
		displayPos();
	}

	function initBg() {
		bg = new ASprite();
		root.addChild(bg);
		var i = 0;
		for (t in Tex.get("decor")) {
			var s = new PixiSprite(t);
			s.anchor.set(0, 0);
			s.y = i * 600;
			s.scale.set(1);
			bg.addChild(s);
			i++;
		}
		bgh = Data.DECOR_H - Cs.mch;
	}

	// clouds of a part of a layer (a bitmap of at most BITMAP_HEIGHT in the original), visual random
	function addParallax(k:Int, pmax:Int):Bool {
		var par = parallax[k];
		if (par == null) {
			par = new Parallax();
			root.addChild(par);
			parallax.push(par);
			par.coef = 0.2 + 0.8 * k / (pmax - 1);
			par.h = 0;
			par.max = Std.int(BGH * getSpeed(par.coef));
		}

		var bgh = BGH * getSpeed(par.coef);
		var cpath = par.h / bgh;
		var bh = Std.int(Math.min(BITMAP_HEIGHT, bgh - par.h));
		// (bgh is not a whole number: the last part may be less than one pixel high)
		if (bh <= 0)
			return true;
		var nmax = Std.int((1 - par.coef) * 50 * Math.pow(cpath, 2));

		// Col.setPercentColor(brush.smc, prc, CLOUD_FADE_COLOR): colour * (1 - p) + orange * p
		var p = (1 - par.coef) * Cs.CLOUD_FADE_PRC / 100;
		var m = Std.int(255 * (1 - p));
		var o = Cs.CLOUD_FADE_COLOR;
		var add = (Std.int(((o >> 16) & 255) * p) << 16) | (Std.int(((o >> 8) & 255) * p) << 8) | Std.int((o & 255) * p);

		for (i in 0...nmax) {
			var f = Seed.randomVfx(5) + 1;
			var sc = 0.5 + par.coef * 1.5;
			var hgt = CLOUD_H[f - 1];
			var ma = hgt * 0.5 * sc;
			var x = Seed.randVfx() * Cs.mcw;
			var y = par.h + ma + Seed.randVfx() * (bh - 2 * ma);
			var spr = new PixiSprite(nuage[f - 1]);
			spr.anchor.copyFrom(nuage[f - 1].defaultAnchor);
			spr.scale.set(sc / (Game.K * 0.5));
			spr.position.set(x, y);
			spr.tint = (m << 16) | (m << 8) | m;
			spr.visible = false;
			var sa = new PixiSprite(nuageW[f - 1]);
			sa.anchor.copyFrom(nuageW[f - 1].defaultAnchor);
			sa.scale.set(sc / (Game.K * 0.5));
			sa.position.set(x, y);
			sa.tint = add;
			sa.blendMode = BlendModes.ADD;
			sa.visible = false;
			par.addChild(spr);
			par.addChild(sa);
			par.clouds.push({x: x, y: y, f: f, sc: sc, spr: spr, add: sa});
		}
		par.h += bh;
		return par.h >= bgh;
	}

	public function update() {}

	public function inc(n:Float) {
		setPos(pos + n);
	}

	public function setPos(n:Float) {
		if (Game.me.mcStase != null) {
			var dec = n - pos;
			Game.me.mcStase._y += dec * SPEED;
		}
		speed = n - pos;
		pos = n;
		if (pos < 0)
			pos = 0;
		displayPos();
	}

	function displayPos() {
		var ny = (pos * SPEED) % bgh - bgh;
		if (Math.abs(ny - bg._y) > 100) {
			bg._y = ny;
			bg.updateState();
		} else {
			bg._y = ny;
		}

		for (par in parallax) {
			var y = (pos * getSpeed(par.coef)) % par.max - par.max;
			var jump = Math.abs(y - par._y) > 100;
			par._y = y;
			if (jump)
				par.updateState();
			// clouds on the screen (and around: the interpolation shows the previous position too)
			for (c in par.clouds) {
				var sy = y + c.y;
				var vis = sy > -300 && sy < Cs.mch + 300;
				c.spr.visible = vis;
				c.add.visible = vis;
			}
		}
	}

	function getSpeed(c:Float) {
		return SPEED + c * (HIGHSPEED - SPEED);
	}
}
