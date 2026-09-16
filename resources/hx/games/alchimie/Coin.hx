package alchimie;

import mt.bumdum.Phys;

class Coin {
	public var pList:Array<Phys>;
	public var nextId:Int;
	public var id:Int;
	public var mc:ASprite;
	public var group:Array<Coin>;
	public var dy:Float;
	public var x:Int;
	public var y:Int;

	var trg:Coin;
	var timer:Float;
	var prc:Float;
	var step:Int;
	var game:Dynamic;

	public function new(g:Dynamic, x:Int, y:Int) {
		game = g;
		dy = 0;
		mc = game.dmanager.attach("coin", Cs.PLAN_COIN);
		mc._x = x * Cs.COIN_SIZE + Cs.POS_X;
		mc._y = y * Cs.COIN_SIZE + Cs.POS_Y;
		mc._xscale = 100 * 30 / 24;
		mc._yscale = 100 * 30 / 24;
		pList = [];
	}

	public function setId(id:Int):Void {
		this.id = id;
		mc.gotoAndStop(id + 1);
	}

	public function gravityInit():Void {
		dy += Cs.COIN_SIZE;
	}

	public function gravityUpdate():Bool {
		if (dy <= 0) {
			return false;
		}
		var s = Math.min(KadoKadeoManager.I(20) * Timer.tmod, Cs.COIN_SIZE / 2);
		dy -= s;
		mc._y += s;
		return dy > 0;
	}

	public function recall():Void {
		mc._y += dy;
		dy = 0;
	}

	public function explodeInit(c:Coin):Void {
		trg = c;
		prc = 100;
		step = 0;
	}

	public function explodeUpdate():Bool {
		switch (step) {
			case 0:
				prc = Math.max(prc - 20 * Timer.tmod, 0);
				Col.setPercentColor(mc, 100 - prc, 0xFFFFFF);
				if (prc == 0) {
					var p = getPos();

					var explo:Phys = game.newPart("partExplosion");
					explo.root.play();
					explo.fadeType = -1;
					explo.x = p.x;
					explo.y = p.y;
					explo.scale = 80;
					explo.root._rotation = Seed.randVfx() * 360;
					explo.timer = 20;

					for (_ in 0...6) {
						var part:Phys = game.newPart("partLightFlip");
						var a = Seed.randVfx() * 6.28;
						var ca = Math.cos(a);
						var sa = Math.sin(a);
						var speed = KadoKadeoManager.S(4 + Seed.randVfx() * 8);
						part.x = p.x + ca * KadoKadeoManager.I(4);
						part.y = p.y + sa * KadoKadeoManager.I(4);
						part.vx = ca * speed;
						part.vy = sa * speed;
						part.frict = 0.9;
						part.scale = 50 + Seed.randVfx() * 50;
						trg.pList.push(part);
					}

					if (this == trg) {
						step = 1;
						timer = 24;
					} else {
						step = 10;
					}
				}
			case 1:
				mc._alpha = Math.max(mc._alpha - 20 * Timer.tmod, 0);
				timer -= Timer.tmod;
				if (timer < 20) {
					for (part in pList) {
						var p = trg.getPos();
						part.towardSpeed(p, 0.1, KadoKadeoManager.S(0.8));
					}
				}

				if (timer <= 0) {
					var p = getPos();

					var explo:Phys = game.newPart("partLightCircle");
					explo.x = p.x;
					explo.y = p.y;
					explo.scale = 10;
					explo.vs = 30;
					explo.frict = 0.5;
					explo.timer = 10;

					for (part in pList) {
						var a = part.getAng(p);
						var d = part.getDist(p);
						var c = Math.max(KadoKadeoManager.I(1), KadoKadeoManager.I(16) - d);
						part.vx = -Math.cos(a) * c;
						part.vy = -Math.sin(a) * c;
						part.timer = 10 + Seed.randVfx() * 10;
					}
					setId(nextId);
					mc._alpha = 100;
					prc = 0;
					step = 2;
				}
			case 2:
				prc = Math.min((prc * Math.pow(1.2, Timer.tmod)) + 2, 100);
				Col.setPercentColor(mc, 100 - prc, 0xFFFFFF);
				if (prc == 100) {
					return false;
				}
			case 10:
				mc._alpha = Math.max(mc._alpha - 20 * Timer.tmod, 0);
				if (mc._alpha == 0) {
					mc.removeMovieClip();
					return false;
				}
		}

		return true;
	}

	public function transmuteInit(nextid:Int):Void {
		setId(nextid);
	}

	public function transmuteUpdate():Bool {
		return false;
	}

	public function getPos():{x:Float, y:Float} {
		return {
			x: mc._x + Cs.COIN_SIZE * 0.5,
			y: mc._y + Cs.COIN_SIZE * 0.5
		};
	}
}
