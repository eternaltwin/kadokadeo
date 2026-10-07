package happyptitank;

import happyptitank.ShotManager;

class RotaShooter extends Enemy {
	var state:Int;
	var nbr:Int;
	var last:Float;

	public function new() {
		super();
		life = maxLife = 50;
		value = KKApi.const(500);
		state = 0;
		shot = new ShotManager(this, [
			ShotAngle(getAngle), Pause(200),
			ShotAngle(getAngle), Pause(200),
			ShotAngle(getAngle), Pause(200),
			ShotMultiAngles(getAngles), Pause(200),
			ShotAngle(getAngle), Pause(200),
			ShotAngle(getAngle), Pause(200),
			ShotAngle(getAngle), Pause(200),
			ShotMultiAngles(getAngles), Pause(200),
			ShotAngle(getAngle), Pause(200),
			ShotAngle(getAngle), Pause(200),
			ShotAngle(getAngle), Pause(200),
			ShotMultiAngles(getAngles), Pause(200),
			Pause(300),
		], 2);
		last = Game.instance.now;
		nbr = 0;
		addChild(new DummyFoe()); // apparence
	}

	function getAngles():Array<Float> {
		return [Geom.deg2rad(rotation), Geom.deg2rad(rotation - 180),];
	}

	function getAngle():Float {
		return Geom.deg2rad(rotation - 180);
	}

	override public function update() {
		super.update();
		rotation += 1 * Timer.tmod;
	}
}
