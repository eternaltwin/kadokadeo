package spiroule;

import pixi.core.graphics.Graphics;
import pixi.core.sprites.Sprite as PixiSprite;
import spiroule.FlashFilters.FlashCx;
import spiroule.FlashFilters.FlashGlow;

// Ball.hx of the original: a ball of a chain, of the launcher, or flying (a shot, or a black ball kicked out of its
// chain)
class Ball {
	public static var FL_ROLL = true;
	public static var ANIM_COEF = 0.5;

	public var flInsert:Bool = false;
	public var flDeath:Bool = false;
	public var from:Null<Float>;

	// (null in Flash before the first placement: NaN in a calculation)
	public var x:Float = Math.NaN;
	public var y:Float = Math.NaN;
	public var vx:Float = Math.NaN;
	public var vy:Float = Math.NaN;

	var px:Null<Int>;
	var py:Null<Int>;

	public var root:MC;

	// port: the BitmapData of the ball (root.smc's picture): one of the 48 textures of its colour (Game.initGfxTable)
	var bmp:PixiSprite;

	public var pos:Null<Float>;
	public var flh:Null<Float>;

	public var col:Int;
	public var chain:Chain;

	// port: the colour offset and glow of a flash (Col.setColor(root, 0, n), Filt.glow(root, 12 c, 1 + 2 c, 0xFFFFFF))
	var flashAdd:Int = 0;
	var glowC:Float = 0;
	var cx:FlashCx;
	var glow:FlashGlow;

	public function new(?flGen:Bool) {
		Game.me.balls.push(this);
		root = Game.me.bdm.attach("mcBall2", Game.DP_BALL);

		// new mt.DepthManager(root.smc).empty(0).attachBitmap(bmp, 0) at (-bray, -bray)
		var smc = root.clip.get("smc");
		bmp = new PixiSprite(Tex.get("tex0")[0]);
		var k = Data.BALL_SMC_K;
		bmp.x = -Cs.bray * k;
		bmp.y = -Cs.bray * k;
		bmp.scale.set(k, k);
		smc.addChild(bmp);

		col = Seed.random(Game.me.colorMax);

		if (flGen && Seed.random(Game.me.black) == 0) {
			col = 4;
		}
		root.gotoAndStop(col + 1);

		setTexture(0);
	}

	public function setPos(c:Float, ?flDirect:Bool) {
		pos = c;
		var p = Cs.getPos(pos);
		if (flInsert) {
			var c = Game.me.animCoef;
			var dx = p.x - x;
			var dy = p.y - y;
			x += dx * c;
			y += dy * c;
			flInsert = Math.abs(dx) + Math.abs(dy) > 2;
		} else {
			x = p.x;
			y = p.y;
		}

		root.setSub("smc", null, null, null, null, (p.a + 1.57) / 0.0174);

		setTexture(Std.int((c * 1350) % 48));

		updatePos();
		upgradeGridPos();
	}

	// bmp.copyPixels(Game.me.gfxTable[col][fr]): (a frame out of the table: copyPixels of undefined, the bitmap stays)
	function setTexture(fr:Int) {
		var t = Tex.get("tex" + col);
		if (fr >= 0 && fr < t.length)
			bmp.texture = t[fr];
	}

	public function updatePos() {
		root._x = x;
		root._y = y;
	}

	// FLYING
	public function update() {
		x += vx * Timer.tmod;
		y += vy * Timer.tmod;
		upgradeGridPos();
		var a = Game.me.cell(px, py);
		var ball:Ball = null;
		var dist = 99.0;
		var i = 0;
		while (a != null && i < a.length) {
			var b = a[i];
			i++;
			if (b.chain != null) {
				if (b.flDeath) {} else {
					var dx = b.x - x;
					var dy = b.y - y;
					var d = Math.sqrt(dx * dx + dy * dy);
					if (d < Cs.bray * 2) {
						if (d < dist || ball == null) {
							ball = b;
							dist = d;
						}
					}
				}
			}
		}
		if (ball != null) {
			if (from == null || Math.abs(from - ball.pos) > 0.1) {
				ball.chain.insert(this, ball);

				fxInsert((x + ball.x) * 0.5, (y + ball.y) * 0.5);
			}
		}
		updatePos();

		// PARTS
		fxDust();

		//
		if (Cs.isOut(x, y, -Cs.bray)) {
			if (col == 4) {
				Game.me.addScore(KKApi.val(Cs.SCORE_BLACK));
				fxSideBurst();
				#if debug
				Game.me.stats.blackOut++;
				#end
			}
			kill();
		}
	}

	public function getLauncherAngle():Float {
		var dx = Cs.SPX - x;
		var dy = Cs.SPY - y;
		return Cs.q(Math.atan2(dy, dx));
	}

	// MAJ
	public function maj() {
		if (flh != null) {
			var c = flh;
			flh *= 0.9;
			if (flh < 0.01) {
				flh = null;
				c = 0;
			}
			setColor(Std.int(c * 255));

			// root.filters = []; then the glow while it flashes
			glowC = c > 0 ? c : 0;
			showFlash();
		}
	}

	// GRID
	function upgradeGridPos() {
		var npx = Cs.getPX(x);
		var npy = Cs.getPY(y);
		if (npx != px || npy != py) {
			removeFromGrid();
			px = npx;
			py = npy;
			insertInGrid();
		}
	}

	function insertInGrid() {
		for (x in 0...3) {
			for (y in 0...3) {
				// (out of the grid: undefined in Flash, nothing is pushed)
				var a = Game.me.cell(px + x - 1, py + y - 1);
				if (a != null)
					a.push(this);
			}
		}
	}

	function removeFromGrid() {
		if (px == null || py == null)
			return;
		for (x in 0...3) {
			for (y in 0...3) {
				var a = Game.me.cell(px + x - 1, py + y - 1);
				if (a != null)
					a.remove(this);
			}
		}
	}

	// FX
	public function fxLink(b:Ball) {
		if (b.pos == null || pos == null)
			return;

		var mc = Game.me.magnet;

		var run:Float = pos;
		var ec = 0.01;
		var size = 6;

		var to = 0;
		var a = [];

		var lineMax = 2;

		while (true) {
			run = Math.min(run + ec, b.pos);

			var p = Cs.getPos(run);
			if (run < b.pos) {
				var lst = [];
				for (i in 0...lineMax) {
					lst.push({
						x: p.x + (Seed.randVfx() * 2 - 1) * size,
						y: p.y + (Seed.randVfx() * 2 - 1) * size,
					});
				}
				a.push(lst);
			}

			if (to++ > 500) {
				break;
			}

			if (run == b.pos)
				break;
		}

		for (i in 0...2) {
			// (Flash draws a line thinner than a screen pixel one pixel wide: the root is drawn x2)
			mc.lineStyle(Math.max(0.2 + i * 1.3, 1 / Clip.K), 0xFFFFFF, 1);
			mc.moveTo(x, y);
			for (lst in a) {
				var p = lst[i];
				mc.lineTo(p.x, p.y);
			}
		}
		Game.me.magnetUsed();
	}

	function fxInsert(px:Float, py:Float) {
		var max = 12;
		for (i in 0...max) {
			var a = i / max * 6.28;
			var sp = Seed.randVfx() * 3;
			var cr = 5;
			var ca = Math.cos(a) * sp;
			var sa = Math.sin(a) * sp;
			var p = fxPart();
			p.x = px + ca * cr;
			p.y = py + sa * cr;
			p.vx = ca;
			p.vy = sa;
		}
	}

	function fxDust() {
		var p = fxPart();
		p.x = x + (Seed.randVfx() * 2 - 1) * 10;
		p.y = y + (Seed.randVfx() * 2 - 1) * 10;
		p.vx = vx * Seed.randVfx() * 0.5;
		p.vy = vy * Seed.randVfx() * 0.5;
	}

	function fxSideBurst() {
		var dx = Cs.mcw * 0.5 - x;
		var dy = Cs.mch * 0.5 - y;
		var a = Math.atan2(dy, dx);

		//
		var mc = Game.me.dm.attach("mcSideBurst", Game.DP_FX);
		// (its shape is placed in blendMode "add" in the SWF)
		mc.blendAdd();
		mc._x = x;
		mc._y = y;
		mc._rotation = a / 0.0174 + 90;

		// PARTS
		var dec = 12;
		for (i in 0...36) {
			var sp = 1.5 + Seed.randVfx() * 4;
			var p = fxPart();
			p.x = x + (Seed.randVfx() * 2 - 1) * dec;
			p.y = y + (Seed.randVfx() * 2 - 1) * dec;
			p.vx = Math.cos(a) * sp;
			p.vy = Math.sin(a) * sp;
		}
	}

	// port: the sparks in blendMode "overlay" are attached in Game's overlay layer (see OverlayLayer), their glow
	// (Filt.glow(p.root, 10, 2, 0xFFFFFF)) drawn by Spark
	function fxPart():Phys {
		var p = new Phys(Game.me.odm.attach("fxSpark", 0));
		p.timer = 10 + Seed.randVfx() * 10;
		p.fadeType = 0;
		p.root.gotoAndPlay(Seed.randomVfx(p.root._totalframes) + 1);
		return p;
	}

	public function incFlash(inc:Float) {
		if (flh == null)
			flh = 0;
		flh = Math.min(flh + inc, 1);
		setColor(Std.int(flh * 255));
		if (flh > 0.5)
			flInsert = false;
	}

	//
	public function getIndex():Null<Int> {
		var id = 0;
		for (ball in chain.list) {
			if (ball == this)
				return id;
			id++;
		}
		return null;
	}

	//
	public function explode() {
		// ONDE
		var mc = Game.me.dm.attach("mcOnde", Game.DP_FX);
		mc._x = x;
		mc._y = y;

		// EXPLODE (its glow, Filt.glow(mc, 4, 1, 0xFFFFFF), drawn in its pictures)
		var mc = Game.me.dm.attach("fxExplode", Game.DP_FX);
		mc._x = x;
		mc._y = y;
		mc._rotation = Seed.randomVfx(360);
		mc.blendAdd();
		mc._xscale = mc._yscale = 120;
		mc._rotation = Seed.randVfx() * 360;

		var max = 8;
		var cr = 3;
		for (i in 0...max) {
			var speed = Seed.randVfx() * 2;
			var a = i / max * 6.28;
			var ca = Math.cos(a) * speed;
			var sa = Math.sin(a) * speed;
			var p = new Phys(Game.me.dm.attach("partEclat", Game.DP_FX));
			p.x = x + ca * cr * speed;
			p.y = y + sa * cr * speed;
			p.vx = ca * speed;
			p.vy = sa * speed;
			p.timer = 10 + Seed.randVfx() * 14;
			p.setScale(50 + Seed.randVfx() * 50);
			p.root._rotation = Seed.randVfx() * 360;
			p.root.setSub("smc", null, null, 50 + Seed.randVfx() * 100, 50 + Seed.randVfx() * 100);
			p.root.gotoAndPlay(Seed.randomVfx(p.root._totalframes) + 1);
			p.vr = (Seed.randVfx() * 2 - 1) * 25;
			p.frict = 0.95;
			p.fadeType = 0;
			var colors = Cs.COLORS;
			if (i / max < 0.5)
				colors = Cs.COLORS_DARK;
			// Col.setColor(smc, colors[col]) on a white picture: that colour (a black ball: colors[4] is undefined, the
			// offsets of 0 - 255 make it black)
			p.root.clip.setSubTint("smc", col < colors.length ? colors[col] : 0x000000);
			p.updatePos();
		}

		kill();
	}

	public function collapse() {
		explode();
	}

	//
	public function unchain() {
		// (a flying ball has no chain: null.list in Flash, nothing)
		if (chain != null)
			chain.list.remove(this);
		removeFromGrid();
		chain = null;
		pos = null;
	}

	public function kill() {
		flDeath = true;
		root.removeMovieClip();
		Game.me.shots.remove(this);
		Game.me.balls.remove(this);
		unchain();
		releaseFilters();
	}

	// ---------------------------------------------------------------- port: the flash of a ball
	// Col.setColor(root, 0, n): n added to the red, green and blue of the ball
	function setColor(n:Int) {
		flashAdd = n;
		showFlash();
	}

	function showFlash() {
		if (root.removed)
			return;
		var fl:Array<pixi.core.renderers.webgl.filters.Filter> = [];
		if (flashAdd != 0) {
			if (cx == null)
				cx = cast FlashFilters.take(FlashCx);
			cx.set([1, 1, 1, flashAdd, flashAdd, flashAdd]);
			fl.push(cx);
		}
		if (glowC > 0) {
			if (glow == null)
				glow = cast FlashFilters.take(FlashGlow);
			glow.set(12 * glowC, 1 + 2 * glowC, 0xFFFFFF, 1);
			fl.push(glow);
		}
		root.clip.filters = fl.length == 0 ? null : fl;
	}

	function releaseFilters() {
		if (cx != null)
			FlashFilters.release(cx);
		if (glow != null)
			FlashFilters.release(glow);
		cx = null;
		glow = null;
	}
}
