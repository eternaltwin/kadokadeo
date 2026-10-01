package kanjisnightmare;

// shuriken
class Star extends Phys {
	public var damage:Float;

	public function new(mc:ASprite) {
		super(mc);
		Cs.game.nsList.push(this);
		damage = 5;
	}

	override public function update() {
		super.update();
		for (m in Cs.game.mList) {
			if (Math.abs(m.x - x) + Math.abs(m.y - y) < 20) {
				m.hit(this);
				kill();
				break;
			}
		}
		// CHECK (like the original, still done after a hit)
		checkMouse();
		checkMedusa();
		// OUT
		if (isOut(40))
			kill();
	}

	// the shuriken can hit the mouse pointer (it falls)
	function checkMouse() {
		var g = Cs.game;
		if (!g.flMouseDead && g.mouseActive()) {
			var xm = g.mouseMapX() + 8;
			var ym = g.mouseMapY() + 8;
			if (Math.abs(x - xm) + Math.abs(y - ym) < 15) {
				g.killMouse();
				var p = g.newPart("mcMouse");
				p.x = xm + 8;
				p.y = ym + 8;
				p.vy = -4;
				p.vx = vx * 0.5;
				p.vr = 8 + Seed.randVfx() * 10;
				p.timer = 30 + Seed.randVfx() * 10;
				p.fadeType = 0;
				p.weight = 0.6;
				p.flPlatCol = true;
				p.ray = 8;
				kill();
			}
		}
	}

	function checkMedusa() {
		if (vx < 0 && Cs.game.medusaHitTest(x, y))
			klong();
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
		p.weight = 0.6;
		kill();
	}

	override public function kill() {
		super.kill();
		Cs.game.nsList.remove(this);
	}
}
