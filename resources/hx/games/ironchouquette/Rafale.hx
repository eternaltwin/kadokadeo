package ironchouquette;

import mt.Timer;

class Rafale {
	public var cooldown:Float;
	public var w:Int;
	public var dx:Float;
	public var dy:Float;
	public var cInert:Float;

	public var list:Array<{type:Int, params:Array<Float>, cooldown:Float}>;
	public var b:Bads;

	public var index:Int;
	public var timer:Float;

	public var orientRay:Float;

	public function new(bad) {
		list = new Array();
		b = bad;

		w = 1;
		cooldown = 200;
		dx = 0;
		dy = b.ray;
	}

	public function init() {
		index = 0;
		timer = 0;
		b.rafale = this;
		b.shootTimer = cooldown;
	}

	public function update() {
		timer -= Timer.tmod;
		if (timer <= 0) {
			var si = list[index];
			shot(si.type, si.params);
			timer += si.cooldown;
			index++;
			b.fire.gotoAndPlay("2");
			if (index == list.length) {
				b.rafale = null;
			}
		}
	}

	public function addShot(n, a, cd, max) {
		if (max == null)
			max = 1;
		for (i in 0...max) {
			list.push({type: n, params: a, cooldown: cd});
		}
	}

	public function shot(type, a:Array<Dynamic>) {
		var shot = null;
		switch (type) {
			case 0: // FRONT (  speed, skin, ray )
				shot = newShot();
				shot.vy = a[0];
				shot.setSkin(a[1], 1);
				if (a[2] != null)
					shot.ray = a[2];

			case 1: // STANDARD (  speed, acc )
				shot = newAimedShot(a[0], a[1]);
				shot.setSkin(13, 1);

			case 2: // CIBLE (  speed, skin )
				shot = newAimedShot(a[0], 0);
				shot.setSkin(a[1], 1);
				shot.orient();

			case 3: // MULTI (  speed, skin, nb, pa )
				for (i in 0...a[2]) {
					var c = (i / (a[2] - 1)) * 2 - 1;
					shot = newAngledShot(a[0], 1.57 + c * a[3]);
					shot.setSkin(a[1], 1);
					// shot.orient();
				}
			case 4: // FRONT ANGLED ( speed, acc )
				var c = Cs.rand() * 2 - 1;
				shot = newAngledShot(a[0], 1.57 + c * a[1]);
				shot.setSkin(13, 1);
		}
		if (cInert != null) {
			shot.vx += cInert * b.vx;
			shot.vy += cInert * b.vy;
		}
	}

	public function newShot() {
		var shot = new Shot(null);
		shot.x = b.x + dx;
		shot.y = b.y + dy;
		if (orientRay != null) {
			var a = b.getAng(cast Cs.game.hero);
			shot.x += Math.cos(a) * orientRay;
			shot.y += Math.sin(a) * orientRay;
		}
		return shot;
	}

	public function newAimedShot(speed, da) {
		// var shot = newShot();
		// var a = b.getAng(Cs.game.hero) +
		// shot.vx = Math.cos(a)*speed;
		// shot.vy = Math.sin(a)*speed;

		return newAngledShot(speed, b.getAng(cast Cs.game.hero) + (Cs.rand() * 2 - 1) * da);
	}

	public function newAngledShot(speed, a) {
		var shot = newShot();
		shot.vx = Math.cos(a) * speed * Cs.NEW_GEN_SCALE;
		shot.vy = Math.sin(a) * speed * Cs.NEW_GEN_SCALE;
		return shot;
	}
}
