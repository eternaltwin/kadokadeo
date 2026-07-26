package kanjisnightmare;

import mt.bumdum.Lib.Num;
import mt.DepthManager;
import mt.bumdum.Sprite;
import pixi.core.graphics.Graphics;

class PlatGfxSprite extends ASprite {
	public var cornerStart:ASprite;
	public var cornerEnd:ASprite;
	public var text:ASprite;
	public var textMask:Graphics;
}

class Plat extends Sprite {
	public var w:Float;

	var bx:Float;
	var gfx:PlatGfxSprite;

	public var grap:Grap;

	public function new(mc) {
		Cs.game.platList.push(this);
		super(mc);
		gfx = cast mc;
		gfx.text = mc.attachMovie("mcPlat", "text");
		gfx.textMask = mc.createEmptyMovieClip("textMask").getGraphics();
		gfx.text.mask = gfx.textMask;
		gfx.cornerStart = gfx.attachMovie("corner", "cornerStart");
		gfx.cornerStart._xscale = -100;
		gfx.cornerEnd = gfx.attachMovie("corner", "cornerEnd");
	}

	public function setPlat(nx:Float, ny:Float, nw:Float) {
		var dx = nx - x;
		x = nx;
		y = ny;
		w = nw;
		gfx.text._x -= dx;

		gfx.textMask.clear()
			.beginFill(0xFFFFFF)
			.drawRect(KadoKadeoManager.S(-2.5 + 19), KadoKadeoManager.S(-2.5), w - KadoKadeoManager.I(19 * 2) + KadoKadeoManager.I(5),
				KadoKadeoManager.S(30 + 2.5))
			.endFill();
		// gfx.mask.scale.x = (w - 38) / 100;
		gfx.cornerStart._x = KadoKadeoManager.I(19);
		gfx.cornerEnd._x = w - KadoKadeoManager.I(19);

		updatePos();
	}

	public override function update() {
		super.update();
		// Log.print(x+w)
	}

	public function explode(sx:Float) {
		var flKill = false;
		var wx = Num.q(sx - x);
		if (Num.q(w - wx) < KadoKadeoManager.I(100)) {
			flKill = true;
			wx = w;
		}

		// FX
		if (Num.q(sx + Cs.game.map._x) > 0) {
			// PARTS
			for (i in 0...Std.int(wx * 0.1)) {
				var p = Cs.game.newPart("partDust");
				p.x = x + Seed.randVfx() * wx;
				p.y = y + Seed.randVfx() * KadoKadeoManager.I(8);
				p.setScale(100 + Seed.randVfx() * 100);
				p.weight = KadoKadeoManager.S(0.1 + Seed.randVfx() * 0.3);
				p.timer = 20 + Seed.randVfx() * 10;
				p.fadeType = 0;
			}

			// PLAT
			var dig = wx;
			var xd = x;
			while (Num.q(dig) > KadoKadeoManager.I(30)) {
				var ww = Num.mm(KadoKadeoManager.I(30), Seed.randVfx() * dig, KadoKadeoManager.I(100));

				var p = new Part(Cs.game.mdm.empty(Game.DP_PLAT));
				p.x = xd + ww * 0.5;
				p.y = y + KadoKadeoManager.I(5);
				var dm = new DepthManager(p.root);
				var pl = new Plat(dm.empty(0));
				pl.x = -ww * 0.5;
				pl.setPlat(pl.x, KadoKadeoManager.I(-5), ww);
				pl.root = null;
				pl.kill();

				p.weight = KadoKadeoManager.S(0.2 + Seed.randVfx() * 0.2);
				p.vr = (Seed.randomVfx(2) * 2 - 1) * (0.5 + Seed.randVfx() * (Math.max(4 - (ww / KadoKadeoManager.I(1)) * 0.05, 0)));
				p.timer = 30 + Seed.randVfx() * 10;

				xd += ww;
				dig -= ww;
			}

			// MONS
			for (i in 0...Cs.game.mList.length) {
				var mons = Cs.game.mList[i];
				if (mons.plat == this && (Num.q(sx) > Num.q(mons.x) || flKill)) {
					mons.initStep(2);
				}
			}
			// GRAP

			if (grap != null) {
				if (Num.q(sx) > Num.q(grap.x) || flKill) {
					// grap.drop();
					Cs.game.hero.releaseGrap();
				}
			}

			if (flKill) {
				if (this == Cs.game.hero.plat) {
					Cs.game.hero.initStep(Hero.FLY);
				}
				kill();
			} else {
				setPlat(x + wx, y, w - wx);
				gfx.updateState();
			}
		}
	}

	public function isPlatOut(tx) {
		var px = Num.q(tx);
		return px < Num.q(x) || px > Num.q(x + w);
	}

	public override function kill() {
		Cs.game.platList.remove(this);
		super.kill();
	}
}
