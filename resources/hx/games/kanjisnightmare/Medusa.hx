package kanjisnightmare;

import js.Browser;
import mt.bumdum.Lib;
import mt.DepthManager;
import mt.Timer;
import pixi.core.graphics.Graphics;
import pixi.core.math.Point;
import pixi.core.Pixi.BlendModes;
import pixi.core.sprites.Sprite;
import pixi.core.textures.Texture;

class MedusaSprite extends Phys {
	public var head:MedusaHeadSprite;
}

class MedusaHeadSprite extends ASprite {
	public var eatZone:ASprite;
}

class MedusaBodySprite extends Phys {
	public var body:ASprite;
	public var neck:ASprite;
}

class MedusaArmPartSprite extends ASprite {
	public var vr:Float;
	public var rot:Float;
}

class MedusaArmSprite extends Phys {
	public var ab:MedusaArmPartSprite;
	public var b:MedusaArmPartSprite;
	public var h:ASprite;
}

class Medusa {
	public var medusa:MedusaSprite;

	var medusaBody:MedusaBodySprite;
	var medusaArms:Array<MedusaArmSprite>;

	var mcRedLight:ASprite;
	var game:Game;

	public function new(game:Game) {
		this.game = game;
		// BODY
		medusaBody = cast new Phys(game.mdm.empty(Game.DP_MEDUSA));
		medusaBody.x = Cs.S(-2000);
		medusaBody.body = medusaBody.root.attachMovie("mcMedusaBody", "body", 1);
		medusaBody.neck = medusaBody.root.attachMovie("mcMedusaNeck", "neck", 0);

		// HEAD
		medusa = cast new Phys(game.mdm.attach("mcMedusa", Game.DP_MEDUSA));
		var hair = medusa.root.attachMovie("mcMedusaHair", "hair");
		hair.loop = true;
		hair.play();
		medusa.root._visible = false;
		medusa.x = -game.scrollMin;
		medusa.head = cast medusa.root;
		medusa.head.eatZone = medusa.head.createEmptyMovieClip();
		medusa.head.eatZone._y = Cs.S(50);
		// medusa.head.eatZone.getGraphics().beginFill(0xFFFFFF, 0.5).drawRect(0, 0, Cs.S(20), Cs.S(20));

		// ARMS
		medusaArms = [];
		var adp = [Game.DP_BACK, Game.DP_SHOT];
		for (i in 0...2) {
			var sp:MedusaArmSprite = cast new Phys(game.mdm.empty(adp[i]));
			sp.x = medusaBody.x;
			sp.y = medusaBody.y;
			sp.b = cast sp.root.attachMovie("mcMedusaBras", "b", 1);
			sp.ab = cast sp.root.attachMovie("mcMedusaAvantBras", "ab", 2);
			sp.h = sp.root.attachMovie("mcMedusaHand", "h", 3);
			//
			sp.b.vr = 0;
			sp.b.rot = 0;
			sp.ab.vr = 0;
			sp.ab.rot = 0;
			//
			medusaArms.push(sp);
			// sp.x = 1200;
			// sp.y = 500;
			// sp.ab._y = Cs.S(250);
			if (i == 0)
				Col.setPercentColor(sp.root, 50, 0x9D1E91);
		}

		mcRedLight = createRedLight();
		mcRedLight.blendMode = BlendModes.ADD;
		mcRedLight._alpha = 0;
		mcRedLight._y = Cs.mch * 0.5;
	}

	function createRedLight():ASprite {
		var mc = game.dm.empty(Game.DP_FRONT);
		var radius = Std.int(Cs.S(300));
		var size = radius * 2;
		var canvas = Browser.document.createCanvasElement();
		canvas.width = size;
		canvas.height = size;
		var ctx = canvas.getContext2d();
		var gradient = ctx.createRadialGradient(radius, radius, 0, radius, radius, radius);
		gradient.addColorStop(0, "rgba(255, 0, 0, 0.75)");
		gradient.addColorStop(0.45, "rgba(255, 0, 0, 0.35)");
		gradient.addColorStop(1, "rgba(255, 0, 0, 0)");
		ctx.fillStyle = gradient;
		ctx.beginPath();
		ctx.arc(radius, radius, radius, 0, Math.PI * 2);
		ctx.fill();
		var sp = new Sprite(Texture.from(canvas));
		sp.anchor.set(0.5, 0.5);
		mc.addChild(sp);
		mc.blendMode = BlendModes.ADD;
		mc._alpha = 0;
		mc._y = Cs.mch * 0.5;
		return mc;
	}

	public function update() {
		//
		mcRedLight._x = medusa.x + game.map._x;
		mcRedLight._y = medusa.y + game.map._y;

		// EAT
		if (game.hero.flEat) {
			medusa.vx += Cs.S(2 * Timer.tmod);
			medusa.vy += Cs.S(1.5 * Timer.tmod);
			var frame = Math.max(1, medusa.head._currentframe - 3);
			medusa.head.gotoAndStop(frame);

			medusa.head._rotation += 1;
			var lim = Cs.S(166) * (medusa.head._currentframe / 30);
			if (Num.q(game.hero.y) > Num.q(lim) && Num.q(game.hero.vy) > 0) {
				game.hero.y = Cs.S(166);
				game.hero.vy *= -0.5;
			}
		} else {
			var limit = Cs.S(300);
			var danger = game.scrollMin + game.hero.x;
			var c = danger / limit;
			var ty = (game.hero.y + game.hero.vy * 2) - (1 - c) * Cs.S(180);

			mcRedLight._alpha = 100 - c * 100;
			mcRedLight._xscale = 500 - c * 200;
			mcRedLight._yscale = mcRedLight._xscale;

			medusa.x = -game.scrollMin;
			var lim = Cs.S(2);
			var dy = ty - medusa.y;
			medusa.vy += Num.mm(-lim, dy * 0.15, lim);

			if (Num.q(danger) > limit) {
				medusa.root._visible = false;
				mcRedLight._visible = false;
				medusaBody.root._visible = false;
			} else {
				if (!medusa.root._visible) {
					medusa.y = ty;
					medusa.root._visible = true;
					mcRedLight._visible = true;
					medusaBody.root._visible = true;
				}

				//
				if (Num.q(c) < 0.7) {
					var frame = 1 + Std.int((1 - (c / 0.7)) * 40);
					medusa.head.gotoAndStop(frame);
				}

				medusa.head._rotation = (dy / Cs.NEW_GEN_SCALE) * 0.1 + (medusa.vy / Cs.NEW_GEN_SCALE) * 0.5;

				if (Num.q(c) < 0.5) {
					var cc = (c / 0.5) * 0.1;
					medusa.y += dy * cc;
				}

				if (Num.q(c) < 0.33) {
					game.focus = {x: game.hero.x, y: game.hero.y};
					game.hero.rootSprite.hero.removeMovieClip();
					game.hero.flEat = true;
					game.hero.releaseGrap();

					game.hero.setSens(game.hero.sens);
					game.hero.vx = Cs.S(-6);
					game.hero.vy -= medusa.vy;
					game.hero.weight = Cs.S(-4);

					var hx = game.hero.x + game.map._x;
					var hy = game.hero.y + game.map._y;
					var hp = medusa.head.eatZone.toLocal(new Point(hx, hy));
					game.hero.x = hp.x;
					game.hero.y = hp.y;
					game.hero.updatePos();

					//
					game.hero.initStep(Hero.DEATH);
					game.hero.nextAnim = null;
				}
			};
		}

		// BODY

		// MAIN
		var trg = {
			x: medusa.x - Cs.S(40),
			y: medusa.y + Cs.S(50)
		}
		medusaBody.toward(trg, 0.2, Std.int(Cs.S(100)));

		var a = medusaBody.getAng({x: medusa.x, y: medusa.y});
		var dist = medusaBody.getDist({x: medusa.x, y: medusa.y});
		medusaBody.neck._rotation = a / 0.0174 - medusaBody.root._rotation;
		medusaBody.neck._xscale = dist / Cs.NEW_GEN_SCALE;
		medusaBody.root._rotation = (medusaBody.neck._rotation + 45) * 0.5;

		// ARMS
		for (i in 0...medusaArms.length) {
			var arm = medusaArms[i];
			//
			arm.x = medusaBody.x;
			arm.y = medusaBody.y;
			//
			rotArm(arm.b);
			rotArm(arm.ab);
			moveToEdge(arm.ab, arm.b, Cs.S(255), 1.57);
			moveToEdge(arm.h, arm.ab, Cs.S(258), 0);

			// CHECK PLAT
			var hp = arm.root.toGlobal(new Point(arm.h._x, arm.h._y));

			if (Num.q(hp.y) < Cs.mch && arm.h._currentframe == 1)
				arm.h.gotoAndStop("2");
			if (Num.q(hp.y) > Cs.mch && arm.h._currentframe == 2)
				arm.h.gotoAndStop("1");

			hp.x += Cs.S(70) - game.map._x;
			hp.y += Cs.S(70) - game.map._y;

			if (Num.q(hp.x + game.map._x) > 0 && Num.q(hp.y + game.map._y) < Cs.mcw) {
				for (n in 0...game.platList.length) {
					var pl = game.platList[n];
					if (Num.q(hp.x) > Num.q(pl.x) && Num.q(hp.x) < Num.q(pl.x + pl.w) && Num.q(Math.abs(hp.y - pl.y)) < Cs.S(16)) {
						arm.b.vr -= 6;
						pl.explode(hp.x);
						break;
					}
				}
			}
		}

		if (medusa.root._visible != true)
			return;

		// HEAD DESTRUCT PLAT
		var hray = Cs.S(120);
		for (n in 0...game.platList.length) {
			var pl = game.platList[n];
			if (pl == null)
				continue;
			if (Num.q(medusa.x + hray) > Num.q(pl.x)
				&& Num.q(medusa.x - hray) < Num.q(pl.x + pl.w)
				&& Num.q(Math.abs(medusa.y - pl.y)) < Num.q(hray * 1.2)) {
				pl.explode(medusa.x + hray + Cs.S(30) + Seed.rand() * Cs.S(50));
			}
		}

		// RECAL HEAD
		if (Num.q(medusa.y) < Cs.S(80)) {
			for (i in 0...Std.int(-medusa.vy)) {
				var p = game.newPart("partDust");
				p.x = medusa.x + Seed.randVfx() * Cs.S(120);
				p.y = Cs.S(16);
				p.weight = Cs.S(0.2 + Seed.randVfx() * 0.3);
				p.vx = (Seed.randVfx() * 2 - 1) * Cs.S(6);
				p.timer = 10 + Seed.randVfx() * 30;
				p.fadeType = 0;
			}
			// RECAL
			medusa.y = Cs.S(80);
			medusa.vy = 0;
		}
	}

	function rotArm(m:MedusaArmPartSprite) {
		m.vr += (Seed.randVfx() * 2 - 1) * 0.8 * Timer.tmod;
		m.vr *= Math.pow(0.9, Timer.tmod);
		m.rot += m.vr * Timer.tmod;
		m.rot *= Math.pow(0.98, Timer.tmod);
		m._rotation = m.rot;
	}

	function moveToEdge(mc:ASprite, mc2:ASprite, d:Float, ba:Float) {
		var angle = mc2._rotation * 0.0174 + ba;
		mc._x = mc2._x + Math.cos(angle) * d;
		mc._y = mc2._y + Math.sin(angle) * d;
	}
}
