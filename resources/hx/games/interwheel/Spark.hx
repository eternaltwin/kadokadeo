package interwheel;

import mt.Timer;
import mt.bumdum.Phys;
import mt.bumdum.Lib;

class McPastille extends ASprite {
	public var pastille:ASprite;
	public var bg:ASprite;
}

class Spark extends Phys {
	var distLimit:Float;
	var coefLimit:Float;
	var coef:Float;

	public var c:ASprite;

	public var score:Int;

	public function new(mc) {
		Cs.game.sparkList.push(this);
		super(mc);
		frict = 0.9;
		coef = 0.01;

		distLimit = 5;
		coefLimit = 0.1;

		var bg = mc.attachMovie("mcPastilleBg");
		bg.loop = true;
		bg.play();
		c = mc.attachMovie("mcPastille");
	}

	public override function update() {
		super.update();

		distLimit = Num.q(distLimit + 0.05 * Timer.tmod);
		coefLimit = Num.q(coefLimit + 0.001 * Timer.tmod);

		coef = Num.q(Math.min(coef + 0.005 * Timer.tmod, coefLimit));
		towardSpeed(cast {x: Cs.game.blob.x, y: Cs.game.blob.y}, coef, distLimit);

		if (Num.q(getDist(cast {x: Cs.game.blob.x, y: Cs.game.blob.y})) < Blob.RAY + KadoKadeoManager.I(8)) {
			blast();
			Cs.game.addScore(score);
			kill();
		}

		if (Seed.randVfx() / Timer.tmod < 0.4) {
			var p = newStar();
			p.vx = vx * (0.5 + (Seed.randVfx() * 2 - 1) * 0.1);
			p.vy = vy * (0.5 + (Seed.randVfx() * 2 - 1) * 0.1);
		}
	}

	public function newStar() {
		var p = new Part(Cs.game.dm.attach("partStar", Game.DP_STAR));
		p.x = x;
		p.y = y;
		p.fadeType = 0;
		p.timer = 10 + Seed.randVfx() * 10;
		p.weight = 0.1 + Seed.randVfx() * 0.1;
		return p;
	}

	public function blast() {
		var mc = Cs.game.dm.attach("mcStartExplo", Game.DP_STAR);
		var sc = 60;
		mc._x = x;
		mc._y = y;
		mc._xscale = sc;
		mc._yscale = sc;
		mc.removeOnFrame = 15;
		mc.play();
		/*
			var max = 12
			var r = 8
			for( var i=0; i<max; i++ ){
				var p = newStar();
				var a = Math.random()*6.28//i/max * 6.28
				var ca = Math.cos(a)
				var sa = Math.sin(a)
				var sp = 1+(i%2)*2
				p.x += ca*r;
				p.y += sa*r;
				p.vx = ca*sp
				p.vy = sa*sp
				p.timer = 20-sp*2
			}
		 */
	}

	public override function kill() {
		Cs.game.sparkList.remove(this);
		super.kill();
	}
}
