package starfang;

import mt.bumdum.Part;
import common_haxe_avm1.KKApi;

@:publicFields
class Asteroid extends Bads {
	static var SIZE = [6 * Cs.NEW_GEN_SCALE, 12 * Cs.NEW_GEN_SCALE, 25 * Cs.NEW_GEN_SCALE, 50 * Cs.NEW_GEN_SCALE, 100 * Cs.NEW_GEN_SCALE];

	var type:Int;
	var size:Int;
	var destructPoint:Int;
	var division:Int;
	var speed:Float;

	public function new(mc) {
		super(mc);
		destructPoint = 1;
		division = 2;
		speed = 1.5 * Cs.NEW_GEN_SCALE;
		hp = 1;
	}

	override function initStartPosition() {
		super.initStartPosition();
		// var a = Math.random()*6.28
		var a = 0.77 + (Cs.rand() * 2 - 1) * 0.2 + Cs.random(4) * 1.57;

		vx = Math.cos(a) * speed;
		vy = Math.sin(a) * speed;
	}

	override function update() {
		super.update();
		checkWarp();
	}

	override function hit(shot) {
		super.hit(shot);
		var x = shot.x;
		var y = shot.y;
		var ang = getAng({x: shot.x, y: shot.y});
		if (hp > 0) {
			for (i in 0...3) {
				var p = getRandomPart(type + 1);
				var a = ang + (Cs.rand() * 2 - 1) * 1.57;
				var sp = (0.5 + Cs.rand() * 3) * Cs.NEW_GEN_SCALE;
				p.x = x;
				p.y = y;
				p.vx = vx + Math.cos(a) * sp;
				p.vy = vy + Math.sin(a) * sp;
				p.vr = (Cs.rand() * 2 - 1) * 15;
				p.timer = 10 + Cs.rand() * 10;
				p.fadeType = 0;
				p.root._rotation = Cs.rand() * 360;
			}
		}
	}

	function getRandomPart(gid:Int):Part {
		var p = new Part(Cs.game.dm.attach("partDebris" + gid, Game.DP_PARTS));
		p.root.gotoAndStop(Cs.random(p.root._totalframes) + 1);

		return p;
	}

	public function setInfo(t, s) {
		type = t;
		size = s;
		root.gotoAndStop(size + 1);
		ray = SIZE[size];

		hp = 1 + size;

		switch (type) {
			case 0: // NORMAL;
				hp--;
				speed *= 0.5;
			case 1: // SMALLER;
				speed *= 1.25;
				destructPoint = 0;
			case 2: // SPEEDER;
				speed *= 3;
			case 3: // FRAGMENTER;
				hp *= 2;
				speed *= 1.5;
				division = 3;
			case 4: // STRONG;
				speed *= 1.5;
				hp *= 4;
			case _:
		}
		dif = Math.pow(division, size) * (hp + speed * 0.3);
		score = Cs.SCORE_ASTEROID[type] * KKApi.const(size);
		vr = (10 / size + 2) * (Cs.rand() * 2 - 1);
	}

	override function explode() {
		if ((Cs.game.flOption && Cs.random(Cs.game.badsList.length) == 0) || Cs.random(30) == 0) {
			Cs.game.flOption = false;
			var bonus = new Bonus(Cs.game.dm.attach("mcBonus", Game.DP_SHOT));
			bonus.x = x;
			bonus.y = y;
		}

		//
		if (size > destructPoint) {
			for (i in 0...2) {
				var a = Math.atan2(vy, vx) + 1.57 * ((i * 2) - 1);
				var sp = new Asteroid(Cs.game.dm.attach("mcAsteroid" + (type + 1), Game.DP_BADS));
				sp.setInfo(type, size - 1);
				var ca = Math.cos(a);
				var sa = Math.sin(a);
				var ray = SIZE[sp.size];
				sp.x = x + ca * ray;
				sp.y = y + sa * ray;
				sp.vx = ca * sp.speed;
				sp.vy = sa * sp.speed;
			}
		}

		fxOnde(ray * 2 + 30 * Cs.NEW_GEN_SCALE);
		throwDebris(type + 1, (size + 1) / 5);

		super.explode();
	}
}
