package happyptitank;

import happyptitank.ShotManager;
import happyptitank.MoveManager;

class CFoe extends Enemy {
	public function new() {
		super();
		shot = new ShotManager(this, [Pause(1000), Shot], 2);
		life = maxLife = 25;
		value = KKApi.const(100);
		speed = 4 * (60 / Timer.wantedFPS);
		addChild(new DummyFoe());
	}
}
