package happyptitank;

import happyptitank.EnemyDeathAnim;

// a new circle crossed: flowers under the tank (pictures only: visual random)
class NewCircleAnim extends Sprite implements Anim {
	var time:Float;
	var particules:List<Nature>;
	var duration:Float;
	var state:Int;

	static var BOOM_DURATION = 0.5;
	static var FADE_DURATION = 1;

	public function new() {
		super();
		state = 0;
		time = 0;
		duration = BOOM_DURATION;
		particules = new List();
		x = Game.instance.tank.x;
		y = Game.instance.tank.y;
		Game.instance.groundLayer.addChild(this);
		Game.instance.addAnimation(this);
		boom();
	}

	function boom() {
		particules = new List();
		var n = 15 + Seed.randomVfx(10);
		if (Game.instance.slowLevel == 3)
			n = Math.ceil(n / 4);
		else if (Game.instance.slowLevel == 2)
			n = Math.ceil(n / 3);
		else if (Game.instance.slowLevel == 1)
			n = Math.ceil(n / 2);
		var sr = 60 / Timer.wantedFPS;
		var maxSpeed = 1;
		for (i in 0...n) {
			var n = new Nature();
			n.x = 0;
			n.y = 0;
			n.vect = {
				x: 1 - 2 * Seed.randVfx(),
				y: 1 - 2 * Seed.randVfx(),
			};
			n.rotationSpeed = (5 - Seed.randVfx() * 10) * sr;
			n.speed = (maxSpeed / 2 + Seed.randVfx() * maxSpeed) * sr;
			n.scaleMax = n.speed * 0.8;
			addChild(n);
			particules.push(n);
		}
	}

	public function update():Bool {
		time += Timer.deltaT;
		var delta = Math.min(1, time / duration);
		switch (state) {
			case 0:
				for (p in particules) {
					p.x += Timer.tmod * (1 - delta) * p.speed * p.vect.x;
					p.y += Timer.tmod * (1 - delta) * p.speed * p.vect.y;
					p.rotation += p.rotationSpeed * Timer.tmod;
					p.scaleX = p.scaleMax * Math.pow(delta, 3.0);
					p.scaleY = p.scaleMax * Math.pow(delta, 3.0);
				}
				if (delta >= 1) {
					state = 1;
					time = 0;
					duration = FADE_DURATION;
				}

			case 1:
				for (p in particules) {
					p.x += Timer.tmod * p.speed * p.vect.x * 0.1;
					p.y += Timer.tmod * p.speed * p.vect.y * 0.1;
					p.rotation += p.rotationSpeed * Timer.tmod * 0.1;
					p.scaleX = p.scaleMax * (1 - delta);
					p.scaleY = p.scaleMax * (1 - delta);
					if (delta == 1) {
						removeChild(p);
						particules.remove(p);
					}
				}
				if (delta == 1 || particules.length == 0)
					return false;
		}
		return true;
	}
}
