package elloninthedark;

class Drone extends Bads {
	public var flLeader:Bool;
	public var flOndulator:Bool;

	public function new(mc:ASprite) {
		super(mc, 1.5);
		ray = KadoKadeoManager.I(10);
		hp = 1;
		// root.stop() in the original: the root stays on its frame while the wings ("sub") keep flapping
		root.loop = true;
		root.play();
		frict = 1;
		score = Cs.SCORE_DRONE;
		shootRate = 400;
		gid = 1;
		cooldown = 100;
		flLeader = false;
		flOndulator = false;
	}

	override public function shoot() {
		if (flOndulator) {
			var s = newAimedShot(KadoKadeoManager.S(4), 0.2);
			s.setSkin(8);
			cooldown = 20;
		} else {
			var s = newAimedShot(KadoKadeoManager.S(2.5), 0.5);
			s.setSkin(2);
			cooldown = 30;
		}
	}

	// the leader is attached as "mcBat2" (frame 2 of the original mcBat)
	public function setLeader() {
		flLeader = true;
		hp = 4;
		shootRate = 30;
		gid = 21;
	}

	public function setOndulator() {
		root.gotoAndPlay(1);
		shootRate = 50;
		flOndulator = true;
		hp = 2;
		gid = 22;
	}

	override public function explode() {
		super.explode();

		//
		if (flLeader) {
			for (b in wave.bList.copy()) {
				if (b != null) {
					b.a = Math.atan2(b.vy, b.vx);
					b.va = 0;
					b.bList.push(1);
					b.bList.remove(0);
				}
			}
		}
	}
}
