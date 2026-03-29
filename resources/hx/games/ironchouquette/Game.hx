package ironchouquette;

import pixi.core.textures.RenderTexture;
import pixi.core.math.Matrix;
import common_haxe_avm1.KeyboardManager;
import mt.bumdum.Lib;
import mt.DepthManager;
import mt.Timer;

class ShotLayerSprite extends ASprite {
	public var dm:DepthManager;
}

class ShotsSprite extends ASprite {
	public var layer:Array<ShotLayerSprite>;
}

class PlasmaLayerSprite extends ASprite {
	public var bmp:RenderTexture;
}

class PlasmaSprite extends ASprite {
	public var layer:Array<PlasmaLayerSprite>;
}

@:expose('GameIronchouquette')
class Game implements kado.GameInterface {
	public static var FL_CHEAT = false;

	public static var DP_INTER = 12;
	public static var DP_PARTS = 10;
	public static var DP_SHOTS = 8;
	public static var DP_HERO = 9;
	public static var DP_BADS = 7;
	public static var DP_DRAW = 5;
	public static var DP_UNDERPARTS = 3;
	public static var DP_BG = 2;

	public static var SCROLL_SPEED = 0.0001; // 5//10;
	public static var SCROLL_SPEED_MAX = 6; // 5//10;
	public static var PLASMA_CACHE = 100;

	public static var PM = 1;

	//
	public var stats:{
		k:Array<Array<Int>>,
		b:Array<Array<Int>>
	};

	public var gfxMode:Int;
	public var step:Int;
	public var lagTimer:Float;
	public var timer:Float;
	public var flashouille:Float;
	public var pq:Float;

	public var pList:Array<Part>;
	public var shotList:Array<Shot>;
	public var badsList:Array<Bads>;
	public var bonusList:Array<Bonus>;

	public var dm:DepthManager;
	public var hero:Hero;

	public var root:ASprite;
	public var bg:ASprite;
	public var shots:ShotsSprite;
	public var plasma:PlasmaSprite;

	public var baseList:Array<ASprite>;

	public var bt:{trg:Float, timer:Float, val:Float};

	public var prevKeys:Map<Int, Bool>;

	public var knTurnRay:Float;
	public var knTurnDecal:Float;
	public var knTurnSpeed:Float;
	public var kidnappers:Array<Phys>;
	public var chouquette:Phys;

	public function new(root:ASprite, ?isReplay:Bool = false) {
		Cs.game = this;
		dm = new DepthManager(root);
		this.root = root;

		pList = new Array();
		shotList = new Array();
		badsList = new Array();
		bonusList = new Array();

		bg = dm.attach("mcBg", DP_BG);

		lagTimer = 0;
		gfxMode = 4;

		stats = {
			k: [],
			b: []
		};

		initStep(0);
		initKeyListener();
	}

	public function initStep(n:Int) {
		step = n;
		switch (n) {
			case 0:
				// CHOUQUETTE
				chouquette = new Phys(dm.attach("mcChouquette", DP_BADS));
				chouquette.x = Cs.mcw * 0.5 - 5;
				chouquette.y = Cs.mch + 10;
				chouquette.frict = 0.92;

				// KIDNAPPERS
				knTurnRay = 10;
				knTurnDecal = 0;
				knTurnSpeed = 0;
				kidnappers = new Array();
				for (i in 0...3) {
					var sp = new Phys(dm.attach("mcBads", DP_BADS));
					sp.root.gotoAndStop("6");
					kidnappers.push(sp);
					sp.x = -100;
					sp.y = -100;
					sp.updatePos();
				}

				// BASE
				var pl = dm.attach("mcPlanet", DP_BG);
				pl._x = Cs.mcw;
				pl._y = 160;
				baseList = [pl, dm.attach("base2", DP_BG), dm.attach("base1", DP_PARTS)];

				//
				pq = 0.5;
				initPlasma();
				initShots();
			// initStep(1)
			case 1:
				hero = new Hero(dm.attach("mcHero", DP_HERO));
			case _:
		}
	}

	//
	public function update(delta:Float) {
		updateKeyboard();

		if (bt != null)
			updateBulletTime();
		updateFlash();
		updatePlasma();

		// SPRITE
		for (sp in mt.bumdum.Sprite.spriteList.copy()) {
			sp.update();
		}

		//
		switch (step) {
			case 0:
				if (chouquette.y > Cs.mch * 0.5) {
					chouquette.vy -= 0.3 * Timer.tmod;
				} else {
					initStep(1);
				}
				knTurnRay += 0.35 * Timer.tmod;
				updateKidnappers();
				timer = 60;
			case 1:
				knTurnSpeed += 0.15 * Timer.tmod;
				if (timer > 0) {
					timer -= Timer.tmod;
				} else {
					chouquette.vy -= 0.8 * Timer.tmod;
					if (chouquette.y < -100) {
						while (kidnappers.length > 0)
							kidnappers.pop().kill();
						chouquette.kill();
						initStep(2);
					}
				}
				updateKidnappers();
				Stykades.update();
			case 2: // PLAY
				Stykades.update();
			case _:
		}

		// BG
		if (SCROLL_SPEED > 0)
			updateScroll();

		// GFXMODE
		updateGfxMode();
	}

	public function updateKidnappers() {
		for (i in 0...kidnappers.length) {
			var k = kidnappers[i];
			var c = i / kidnappers.length;

			knTurnDecal = (knTurnDecal + knTurnSpeed * Timer.tmod) % 628;

			k.x = chouquette.x + Math.cos(knTurnDecal * 0.01 + c * 6.28) * knTurnRay;
			k.y = chouquette.y + Math.sin(knTurnDecal * 0.01 + c * 6.28) * knTurnRay;
		}
	}

	public function updateGfxMode() {
		if (Timer.tmod > 2) {
			lagTimer += Timer.tmod;
			if (lagTimer > 16) {
				lagTimer = -150;
				switch (gfxMode) {
					case 4:
						setPq(0.3);
					case 3:
						downcast(root)._quality = "$LOW".substring(1);
						Bads.scoreDisplayLimit = 500;
					case 2:
						plasma.layer[0].bmp.dispose();
						plasma.layer[0].removeMovieClip();
						plasma.layer[0] = null;
					case 1:
						plasma.layer[1].bmp.dispose();
						plasma.removeMovieClip();
					case _:
				}
				gfxMode--;
				PM *= 0.7;
				Stykades.BADS_LIMIT = Math.max(10, Stykades.BADS_LIMIT - 2);
			}
		} else {
			if (lagTimer > 0) {
				lagTimer -= Timer.tmod;
			} else {
				lagTimer += Timer.tmod;
			}
		}
	}

	//
	public function updateBulletTime() {
		var dif = bt.trg - bt.val;
		bt.val += dif * 0.1;
		if (Math.abs(dif) < 0.1)
			bt.val = bt.trg;
		Timer.tmod = bt.val;
		if (bt.timer-- <= 0)
			bt.trg = 1;
		if (bt.val == 1) {
			bt = null;
			bg.filters = [];
		} else {
			// if(Cs.game.root.filters.length>0)return;
			var fl = new flash.filters.ColorMatrixFilter();
			var c = 1 - bt.val;
			var sat = 0.3;
			var inc = Math.random() * 15;
			fl.matrix = [
				1 + c * sat,           0,           0, 0, inc + 200 * c,
				          0, 1 + c * sat,           0, 0,  inc - 50 * c,
				          0,           0, 1 + c * sat, 0,  inc - 50 * c,
				          0,           0,           0, 1,             0

			];
			bg.filters = [fl];
		}
	}

	public function updateFlash() {
		if (flashouille != null) {
			var prc = Math.min(flashouille, 100);
			flashouille *= 0.6;
			if (flashouille < 2) {
				flashouille = null;
				prc = 0;
			}
			Col.setPercentColor(root, prc, 0xFFFFFF);
		}
	}

	// SHOTS
	public function initShots() {
		shots = downcast(dm.empty(DP_SHOTS));
		shots.layer = new Array();
		var dm = new DepthManager(shots);
		for (i in 0...3) {
			var mc = downcast(dm.empty(0));
			mc.dm = new DepthManager(mc);
			shots.layer.push(mc);
		}
	}

	// PLASMA
	public function initPlasma() {
		plasma = downcast(dm.empty(DP_BG));
		plasma.layer = new Array();
		var dm = new DepthManager(plasma);
		for (i in 0...2) {
			var mc = downcast(dm.empty(0));
			mc.bmp = new flash.display.BitmapData(Std.int(Cs.mcw * pq), Std.int((Cs.mch + PLASMA_CACHE) * pq), true, 0x00000000);
			mc.attachBitmap(mc.bmp, 0);
			plasma.layer.push(mc);
			mc._y = -PLASMA_CACHE * pq;

			if (i == 0)
				mc.blendMode = BlendMode.ADD;
			// if(i==1)mc.blendMode = BlendMode.OVERLAY;
		}
		plasma._xscale = 100 / pq;
		plasma._yscale = 100 / pq;
	}

	public function updatePlasma() {
		plasmaDraw(shots.layer[0], 0);
		var bfl = new flash.filters.BlurFilter();

		for (i in 0...plasma.layer.length) {
			if (plasma.layer[i] != null) {
				var bmp = plasma.layer[i].bmp;
				switch (i) {
					case 0:
						var blp = Math.max(2 * pq * Timer.tmod, 1.5);
						bfl.blurX = blp;
						bfl.blurY = blp;
						bmp.applyFilter(bmp, bmp.rectangle, new flash.geom.Point(0, 0), bfl);
						var inc = -2;
						var ct = new flash.geom.ColorTransform(1, 1, 1, 1, inc, inc, inc, 0);
						bmp.colorTransform(bmp.rectangle, ct);
					case 1:
						var blp = Math.max(10 * pq * Timer.tmod, 1);
						bfl.blurX = blp;
						bfl.blurY = blp;
						bmp.applyFilter(bmp, bmp.rectangle, new flash.geom.Point(0, 0), bfl);

						var inc = -10;
						var mult = 0.8;
						var ct = new flash.geom.ColorTransform(0.95, mult, mult, 1, inc, inc * 2, inc * 2, -10);
						bmp.colorTransform(bmp.rectangle, ct);

					case _:
				}

				if (SCROLL_SPEED > 0.2)
					bmp.scroll(0, Std.int(SCROLL_SPEED * 3 * pq));
			}
		}
	}

	public function plasmaDraw(mc, n) {
		if (plasma.layer[n] == null)
			return;
		var bmp = plasma.layer[n].bmp;

		var m = new Matrix();
		m.scale((mc._xscale / 100) * pq, (mc._yscale / 100) * pq);
		m.rotate(mc._rotation * 0.0174);
		m.translate((mc._x) * pq, (mc._y + PLASMA_CACHE) * pq);

		// Commented while converting to pixi:
		// var ct = new flash.geom.ColorTransform(1, 1, 1, 1, 0, 0, 0, -255 + mc._alpha * 2.55);
		// var b = mc.blendMode;

		// bmp.draw(mc, m, ct, b, null, false);

		/* PIXI VERSION COMMENT:
			Exemple Haxe (Pixi) pour l’équivalent de ColorTransform :
			import pixi.filters.ColorMatrixFilter;
			var f = new ColorMatrixFilter();
			var a = mc.alpha; // 0..1 en Pixi
			// Matrice identité + offset sur alpha (dernière valeur)
			f.matrix = [
			1, 0, 0, 0, 0,
			0, 1, 0, 0, 0,
			0, 0, 1, 0, 0,
			0, 0, 0, 1, a - 1
			];
			mc.filters = [f];
		 */
		bmp.draw(mc, m);
		//*/
	}

	public function plasmaPoint(x, y, color) {
		var bmp = plasma.layer[0].bmp;
		bmp.setPixel32(Std.int(x), Std.int(y), color);
	}

	public function setPq(n) {
		pq = n;
		plasma.removeMovieClip();
		initPlasma();
	}

	// SCROLL
	public function updateScroll() {
		if (gfxMode < 3) {
			SCROLL_SPEED *= 0.95;
			if (SCROLL_SPEED < 0.5)
				SCROLL_SPEED = 0;
		} else {
			if (step > 1) {
				SCROLL_SPEED = Math.min(SCROLL_SPEED + 0.01 * Timer.tmod, SCROLL_SPEED_MAX);
			}
		}

		bg._y += SCROLL_SPEED;
		if (bg._y > 0)
			bg._y -= 1800;

		var i = 0;
		while (i < baseList.length) {
			var b = baseList[i];
			if (b._y == 0)
				b._y = Cs.mch;
			b._y += SCROLL_SPEED;
			if (b._y > Cs.mch + 100) {
				b.removeMovieClip();
				baseList.splice(i, 1);
				continue;
			}
			i++;
		}
	}

	// KEY
	public function initKeyListener() {
		prevKeys = new Map();
	}

	public function isKeyJustPressed(code:Int):Bool {
		var down = KeyboardManager.isDown(code);
		var wasDown = prevKeys.exists(code) ? prevKeys.get(code) : false;
		prevKeys.set(code, down);
		return down && !wasDown;
	}

	public function updateKeyboard() {
		if (hero == null)
			return;

		if (FL_CHEAT) {
			for (n in 96...107) {
				if (isKeyJustPressed(n))
					hero.addWeapon(n - 96);
			}
			for (n in 49...54) {
				if (isKeyJustPressed(n))
					hero.addBox();
			}
			for (n in 54...59) {
				if (isKeyJustPressed(n)) {
					var bonus = new Bonus(null);
					bonus.x = Math.random() * Cs.mcw;
					bonus.y = -bonus.ray;
				}
			}
		}

		if (isKeyJustPressed(KeyboardManager.CONTROL) || isKeyJustPressed(16)) {
			hero.sacrifice(null);
		}
	}

	public function destroy():Void {
		Cs.game = null;
	}
}
