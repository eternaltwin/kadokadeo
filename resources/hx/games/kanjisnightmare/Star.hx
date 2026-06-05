package kanjisnightmare;

import mt.bumdum.Lib.Num;
import mt.Timer;

class Star extends Phys {
	public var damage:Float;

	public function new(mc) {
		super(mc);
		Cs.game.nsList.push(this);
		damage = 5;
	}

	public override function update() {
		super.update();
		// list = Cs.game.grid[x][y].list
		for (i in 0...Cs.game.mList.length) {
			var m = Cs.game.mList[i];
			if (Num.q(Math.abs(m.x - x) + Math.abs(m.y - y)) < Cs.S(20)) {
				m.hit(this);
				kill();
				break;
			}
		}
		// CHECK
		checkMouse();
		checkMedusa();
		// OUT
		if (isOut2(Cs.S(40))) {
			kill();
		}
	}

	function checkMouse() {
		if (!Cs.game.flMouseDead) {
			var mouse = Cs.game.getMapMouse();
			var xm = Num.q(mouse.x + Cs.S(8));
			var ym = Num.q(mouse.y + Cs.S(8));
			if (Num.q(Math.abs(x - xm) + Math.abs(y - ym)) < Cs.S(15)) {
				Cs.game.flMouseDead = true;
				Cs.game.mouseDeadTimer = 50;
				Cs.game.dm.root_mc.interactive = true;
				untyped Cs.game.dm.root_mc.cursor = "none";

				var p = Cs.game.newPart("mcMouse");
				p.x = xm + Cs.S(8);
				p.y = ym + Cs.S(8);
				p.vy = Cs.S(-4);
				p.vx = vx * 0.5;
				p.vr = 8 + Seed.randVfx() * 10;
				p.timer = 30 + Seed.randVfx() * 10;
				p.fadeType = 0;
				p.weight = Cs.S(0.6);
				p.flPlatCol = true;
				p.ray = Cs.S(8);

				kill();
				return;
			}
		}
	}

	function checkMedusa() {
		if (vx < 0) {
			var dx = Num.q(x - Cs.game.medusa.medusa.x);
			var dy = Num.q(y - Cs.game.medusa.medusa.y);
			var ray = Cs.S(58);
			if (Cs.game.medusa.medusa.root._visible == true && dx * dx + dy * dy < ray * ray)
				klong();
		}
	}

	function klong() {
		var a = Math.atan2(-vy, -vx) + (Seed.randVfx() * 2 - 1) * 0.4;
		var speed = Math.sqrt(vx * vx + vy * vy) * 0.5;

		var p = Cs.game.newPart("mcKlongShuriken");
		p.x = x;
		p.y = y;
		p.vx = Math.cos(a) * speed;
		p.vy = Math.sin(a) * speed;
		p.vr = 8 + Seed.randVfx() * 10;
		p.timer = 30 + Seed.randVfx() * 10;
		p.fadeType = 0;
		p.weight = Cs.S(0.6);
		kill();
	}

	public override function kill() {
		super.kill();
		Cs.game.nsList.remove(this);
	}
}
