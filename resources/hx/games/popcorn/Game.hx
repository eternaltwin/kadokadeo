package popcorn;

import kado.KadoKadeoManager;
import haxe.io.UInt16Array;
import pixi.filters.colormatrix.ColorMatrixFilter;
import mt.bumdum.Sprite;
import mt.bumdum.Lib.PointWithGetter;
import mt.bumdum.Lib.Num;
import mt.bumdum.Lib.Col;
import js.lib.Uint8Array;
import pixi.core.textures.RenderTexture;
import common_haxe_avm1.KeyboardManager;
import common_haxe_avm1.KKApi;
import mt.DepthManager;
import mt.Timer;

class GamePlanLayer extends ASprite {
	public var c:Float;
}

class GameAnimSprite extends ASprite {
	public var frame:Float;
	public var fs:Float;
	public var endType:Int;
}

class GpListSprite extends ASprite {
	public var size:Float;
}

@:expose('GamePopcorn')
class Game implements kado.GameInterface {
	public static var LIMIT = KadoKadeoManager.I(290);

	public static var DP_BASE = 0;
	public static var DP_BG = 4;
	public static var DP_DECOR = 5;
	public static var DP_CORN = 6;
	public static var DP_PIOU = 7;
	public static var DP_PART = 8;

	static var TOLERANCE = 30;

	static var DEBUG = false;

	static var SCROLL_DECAL = -KadoKadeoManager.I(50);

	public var step:Int;

	var timer:Float;
	var flasher:Float;
	var grey:Float;

	public var ly:Float;

	var glow:Float;
	var glowSpeed:Float;
	var scrollSpeed:Float;

	public var dm:DepthManager;
	public var gdm:DepthManager;

	var gpList:Array<GpListSprite>;

	public var cList:Array<Corn>;

	public var map:ASprite;
	public var bg:ASprite;

	var lim:ASprite;
	var plan:Array<GamePlanLayer>;

	public var animator:Array<GameAnimSprite>;

	public var lvl:RenderTexture;

	var collisionMask:Uint8Array;

	public var hero:Hero;
	public var boss:Boss;

	static var POPCORN_SHAPE = [
		{x: -8.0, y: 9.0, r: 11.0},
		{x: -11.0, y: -8.0, r: 13.0},
		{x: 11.0, y: 0.0, r: 19.0}
	];

	public var focus:PointWithGetter;

	var stats:{};
	var root:ASprite;
	var spaceWasDown:Bool = false;
	var enterWasDown:Bool = false;

	public function new(root:ASprite, ?isReplay:Bool = false) {
		this.root = root;
		Cs.init();
		Cs.game = this;
		gdm = new DepthManager(root);
		bg = gdm.attach("bg", 1);
		map = gdm.empty(2);

		dm = new DepthManager(map);
		cList = new Array();
		animator = new Array();
		gpList = new Array();

		ly = Cs.HEIGHT - KadoKadeoManager.I(30);
		scrollSpeed = KadoKadeoManager.I(100);

		var replayKeys = new UInt16Array(9);
		replayKeys[0] = KeyboardManager.LEFT;
		replayKeys[1] = KeyboardManager.Q;
		replayKeys[2] = KeyboardManager.A;
		replayKeys[3] = KeyboardManager.RIGHT;
		replayKeys[4] = KeyboardManager.D;
		replayKeys[5] = KeyboardManager.SPACE;
		replayKeys[6] = KeyboardManager.Z;
		replayKeys[7] = KeyboardManager.W;
		replayKeys[8] = KeyboardManager.UP;
		KadoKadeoManager.kkm.replay.init({
			recordedKeys: replayKeys,
			recordInputs: true,
			recordEvents: false,
		});

		initStep(0);
	}

	public function initDecor():Void {
		collisionMask = new Uint8Array(Cs.mcw * Cs.HEIGHT);

		// LIMIT
		lim = dm.attach("mcLimit", DP_DECOR);
		lim._y = Cs.HEIGHT - LIMIT;
		//
		lvl = RenderTexture.create(Cs.mcw, Cs.HEIGHT);
		dm.empty(DP_DECOR).attachBitmap(lvl, 0);

		// BASE
		// {
		// 	var mc = dm.attach("mcCadre", DP_BASE);
		// 	mc._y = Cs.HEIGHT - Cs.mch;
		// 	// Cs.draw(lvl,mc)
		// 	mc.removeMovieClip();
		// }

		// PLAN
		plan = new Array();
		{ // FRONT;

			for (n in 0...2) {
				var pl:GamePlanLayer = cast gdm.empty(3);
				pl.c = 1.3;
				var bmp = RenderTexture.create(KadoKadeoManager.I(70), Std.int(Cs.HEIGHT * pl.c));
				pl.attachBitmap(bmp, 0);
				plan.push(pl);
				pl._x = n * Cs.mcw;
				pl._xscale = -(n * 2 - 1) * 100;
				var y = 0;
				while (y < bmp.height) {
					if (Seed.random(3) == 0) {
						var mc = dm.attach("mcFrontDecor", DP_BASE);
						mc._y = y;
						mc.gotoAndStop(Seed.random(mc._totalframes) + 1);
						var sc = 50 + Seed.rand() * 50;
						mc._xscale = sc;
						mc._yscale = sc;
						Cs.draw(bmp, mc);
						mc.removeMovieClip();
					}
					y += KadoKadeoManager.I(100);
				}
			}
		}

		{ // BACK;
			var info = [{c: 0.5, link: "mcWall2"}, {c: 1, link: "mcWall"}];

			for (i in 0...2) {
				for (n in 0...2) {
					var pl:GamePlanLayer = cast gdm.empty(1);
					pl.c = info[i].c;
					var h = Std.int(Cs.HEIGHT * pl.c) + Cs.mch;
					var bmp = RenderTexture.create(KadoKadeoManager.I(50), h);
					pl.attachBitmap(bmp, 0);
					plan.push(pl);
					pl._x = n * Cs.mcw;
					pl._xscale = -(n * 2 - 1) * 100;
					var y:Float = 0;
					while (y < h) {
						var mc = dm.attach(info[i].link, DP_BASE);
						mc._xscale = 100 * pl.c;
						mc._yscale = 100 * pl.c;
						mc._y = y;
						mc.gotoAndStop(Seed.random(mc._totalframes) + 1);
						Cs.draw(bmp, mc);
						mc.removeMovieClip();
						y += KadoKadeoManager.I(100) * pl.c;
					}
				}
			}
		}

		initStep(1);
	}

	public function initStep(s:Int):Void {
		step = s;

		switch (step) {
			case 0:
				initDecor();
			case 1: // ;
				hero = new Hero(null);
				hero.bouncer.setPos(Cs.mcw * 0.5, Cs.HEIGHT - KadoKadeoManager.I(20));

				boss = new Boss(null);
				boss.y = Cs.HEIGHT - KadoKadeoManager.I(320);
				map._y = -Cs.HEIGHT + Cs.mch;

				focus = hero;

			case 9: // ENDGAME;
				if (hero.jumpPower != null)
					hero.releaseJump();
				timer = 8;
		}
	}

	//
	public function update(delta:Float):Void {
		// if(Key.isDown(107))Timer.tmod = 10;
		// if(Key.isDown(109))Timer.tmod = 0.3;
		if (hero != null && hero.jumpPower != null)
			Timer.tmod = 0.2;
		timer -= Timer.tmod;
		handleInput();
		switch (step) {
			case 0:
			case 1:
				// Log.print(ly+" < "+yLim)
				var yLim = Cs.HEIGHT - LIMIT;
				if (ly < yLim) {
					var x = 0;
					while (x < Cs.mcw) {
						if (!isFree(x, yLim)) {
							Cs.game.focus = cast {
								get_y: function() {
									return yLim;
								}
							};
							Cs.game.initStep(9);
						}
						x += KadoKadeoManager.I(3);
					}
				}

			case 9:
				endPart();

				if (timer < 0) {
					KadoKadeoManager.kkm.gameOver(stats);
					initStep(10);
				}
			case 10:
				endPart();
		}
		//
		updateScroll();
		updateAnimator();
		updateScreenEffect();
		// SPRITES
		Sprite.updateAll();
	}

	public function endPart():Void {
		var list = new Array();
		var yLim = Cs.HEIGHT - LIMIT;
		var x = 0;
		while (x < Cs.mcw) {
			if (!isFree(x, yLim))
				list.push(x);
			x += KadoKadeoManager.I(3);
		}
		for (i in 0...3) {
			var p = newPart("partLight");
			p.x = list[Seed.randomVfx(list.length)];
			p.y = yLim;
			p.weight = -KadoKadeoManager.S(0.1 + Seed.randVfx() * 0.5);
			p.timer = 10 + Seed.randVfx() * 10;
			p.setScale(100 + Seed.randVfx() * 150);
			p.vy = -KadoKadeoManager.I(1);
			p.root.loop = true;
			p.root.play();
		}
	}

	public function setScore(x:Float, y:Float, score:Int, scale:Float):Void {
		if (Cs.game.step != 10) {
			var mc = new mt.bumdum.Part(Cs.game.dm.empty(Game.DP_PART));
			mc.root._x = x;
			mc.root._y = y;
			mc.root._xscale = scale;
			mc.root._yscale = scale;
			mc.fadeLimit = 10;
			mc.fadeType = 0;
			mc.timer = 24;
			var scoremc = mc.root.initTextField("score", {
				font: "Impact",
				size: 45,
				color: 0xFFFFFF,
				align: "center",
				stroke: "#000000",
				strokeThickness: 4
			});
			scoremc.text = Std.string(KKApi.val(score));
			KadoKadeoManager.kkm.addScore(score);
		}
	}

	public function updateAnimator():Void {
		var i = 0;
		while (i < animator.length) {
			var mc = animator[i];
			mc.frame += mc.fs * Timer.tmod;
			if (mc.frame > mc._totalframes) {
				mc.removeMovieClip();
				animator.splice(i--, 1);
			} else {
				mc.gotoAndStop(Std.int(mc.frame) + 1);
			}
			i++;
		}
	}

	public function newPart(link:String):Part {
		var p = new Part(dm.attach(link, DP_PART));
		return p;
	}

	// FX
	public function updateScreenEffect():Void {
		if (flasher != null) {
			var prc = flasher;
			if (prc < 5) {
				prc = 0;
				flasher = null;
			}
			Col.setPercentColor(dm.root_mc, prc, 0xFFFFFF);
			if (flasher != null)
				flasher -= (110 - flasher);
		}

		if (grey != null) {
			var c = 0.0;
			if (hero.jumpPower != null) {
				grey = Math.min(grey + (105 - grey) * 0.2, 100);
			} else {
				grey = Math.max(grey - (120 - grey) * 0.5, 0);
			}
			c = grey / 100;

			var m = [];
			for (i in 0...Cs.CM_STD.length) {
				m[i] = Cs.CM_GREY[i] * c + Cs.CM_STD[i] * (1 - c);
			}

			if (grey == 0) {
				grey = null;
				while (gpList.length > 0)
					gpList.pop().removeMovieClip();
				root.filters = [];
			} else {
				var fl = new ColorMatrixFilter();

				var glow = 0.;
				if (hero.jumpPower != null)
					glow = (1 - c) * 160;
				fl.matrix = Cs.getGreyMatrix(30 + glow + Seed.randVfx() * 15);
				root.filters = [fl];
				// Log.print(glow)
				// Log.print(c)
			}

			var margin = KadoKadeoManager.I(10);
			for (i in 0...gpList.length) {
				var mc = gpList[i];
				mc._y -= KadoKadeoManager.I(5) * mc.size + (1 - c) * KadoKadeoManager.I(50);
				if (mc._y < -margin) {
					mc._y += Cs.mch + 2 * margin;
				}
			}
		}
	}

	public function initGrey():Void {
		if (grey == null) {
			grey = 0;
			glow = 0;
			glowSpeed = 0;
			var max = 12 / Timer.tmod;
			for (i in 0...Std.int(max)) {
				var mc:GpListSprite = cast gdm.attach("partLight", 10);
				mc._x = Seed.randVfx() * Cs.mcw;
				mc._y = Seed.randVfx() * Cs.mch;
				mc.size = 0.2 + Seed.randVfx() * 0.8;
				mc._xscale = 50 + mc.size * 100;
				mc._yscale = mc._xscale;
				if (i % 2 == 0)
					mc.gotoAndPlay(2);
				gpList.push(mc);
			}
		}
	}

	// SCROLL
	public function updateScroll():Void {
		var dy = Num.mm(-(Cs.HEIGHT - Cs.mch), Cs.mch * 0.5 - (focus.y + SCROLL_DECAL), 0) - map._y;
		var lim = Math.min(Math.abs(dy), scrollSpeed);
		map._y += Num.mm(-lim, dy * 0.2 * Timer.tmod, lim);

		//
		for (mc in plan) {
			mc._y = map._y * mc.c;
		}
	}

	// GEN
	public function genPopcorn(x:Float, y:Float):Corn {
		var sp = new Corn(null);
		sp.x = x;
		sp.y = y;
		// sp.bouncer.setPos(x,y)
		return sp;
	}

	// LEVEL
	inline function maskIndex(x:Int, y:Int):Int {
		return y * Cs.mcw + x;
	}

	public function stampCircle(cx:Float, cy:Float, r:Float):Void {
		if (collisionMask == null)
			return;

		var minY = Std.int(Math.floor(cy - r));
		var maxY = Std.int(Math.ceil(cy + r));
		if (maxY < 0 || minY >= Cs.HEIGHT)
			return;
		minY = Std.int(Math.max(0, minY));
		maxY = Std.int(Math.min(Cs.HEIGHT - 1, maxY));

		var rr = r * r;
		for (yy in minY...maxY + 1) {
			var dy = yy - cy;
			var remain = rr - dy * dy;
			if (remain < 0)
				continue;

			var dx = Math.sqrt(remain);
			var minX = Std.int(Math.floor(cx - dx));
			var maxX = Std.int(Math.ceil(cx + dx));
			if (maxX < 0 || minX >= Cs.mcw)
				continue;
			minX = Std.int(Math.max(0, minX));
			maxX = Std.int(Math.min(Cs.mcw - 1, maxX));
			var row = yy * Cs.mcw;

			for (xx in minX...maxX + 1) {
				collisionMask[row + xx] = 1;
			}
		}
	}

	public function stampPopcorn(x:Float, y:Float, rot:Float):Void {
		var a = rot * 0.017453292519943295;
		var ca = Math.cos(a);
		var sa = Math.sin(a);
		for (c in POPCORN_SHAPE) {
			var lx = KadoKadeoManager.S(c.x);
			var ly = KadoKadeoManager.S(c.y);
			var wx = x + lx * ca - ly * sa;
			var wy = y + lx * sa + ly * ca;
			stampCircle(wx, wy, KadoKadeoManager.S(c.r));
		}
	}

	public function isFree(x:Int, y:Int):Bool {
		if (x < 0 || x >= Cs.mcw || y >= Cs.HEIGHT)
			return false;
		if (y < 0)
			return true;
		return collisionMask[maskIndex(x, y)] == 0;
	}

	// KEYS
	function handleInput():Void {
		var spaceDown = KeyboardManager.isDown(KeyboardManager.SPACE)
			|| KeyboardManager.isDown(KeyboardManager.Z)
			|| KeyboardManager.isDown(KeyboardManager.W)
			|| KeyboardManager.isDown(KeyboardManager.UP);
		var enterDown = KeyboardManager.isDown(KeyboardManager.ENTER);

		if (spaceDown && !spaceWasDown && hero != null) {
			hero.action();
		}
		if (enterDown && !enterWasDown) {
			// boss.hit();
		}

		spaceWasDown = spaceDown;
		enterWasDown = enterDown;
	}

	//
	public function getRandomPos():{x:Int, y:Int} {
		return {
			x: Cs.MARGIN + Seed.random(Cs.mcw - 2 * Cs.MARGIN),
			y: Cs.MARGIN + Seed.random(Cs.mch - 2 * Cs.MARGIN)
		}
	}

	public function destroy() {}
}
