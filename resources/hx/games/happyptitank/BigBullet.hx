package happyptitank;

import happyptitank.EnemyShot;

// (a subclass of EnemyShot: the shot of symbol 224, with 8 shots in it)
class BigBullet extends EnemyShot {
	var time:Float;
	var shots:Array<EnemyShot>;

	public function new(emitter:DisplayObject, vec:Geom._Ptx, ?speed:Float = 2.0) {
		super(vec, speed / 2);
		var n = 8;
		power = Math.floor(n / 2);
		time = 0;
		shots = [];
		x = emitter.x;
		y = emitter.y;
		var p = {x: 0.0, y: -5.0};
		for (i in 0...n) {
			var shot = new EnemyShot(Geom.radToVector((Math.PI * 2 / n) * i), speed);
			shot.gotoAndStop(2);
			shot.x = p.x;
			shot.y = p.y;
			shots.push(shot);
			addChild(shot);
			Geom.rotate(p, Math.PI * 2 / n);
		}
		Game.instance.foesShots.push(this);
		Game.instance.gameLayer.addChild(this);
	}

	override public function update():Bool {
		super.update();
		time += Timer.deltaT;
		rotation += 10;
		if (time >= 2) {
			explode();
			return false;
		}
		return true;
	}

	function explode() {
		for (shot in shots) {
			shot.x += x;
			shot.y += y;
			removeChild(shot);
			Game.instance.gameLayer.addChild(shot);
			Game.instance.foesShots.push(shot);
		}
		destroyed = true;
	}
}

class BigBulleter extends Enemy {
	var last:Float;

	public function new() {
		super();
		life = maxLife = 100;
		last = Game.instance.now;
		addChild(new DummyFoe());
	}

	override public function update() {
		var now = Game.instance.now;
		if (now - last > 1000) {
			var angle = Geom.angleRad(this, Game.instance.tank);
			var bullet = new BigBullet(this, Geom.radToVector(angle));
			last = now;
		}
	}
}
