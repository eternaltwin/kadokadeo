package phagocytoz.cell;

import phagocytoz.Cell;
import phagocytoz.Element;
import phagocytoz.Game;
import phagocytoz.Gfx;

class Neutral extends Cell {
	public function new(r:Float) {
		super(r);
	}

	override function update() {
		if (Seed.random(200) == 0 && Math.sqrt(vx * vx + vy * vy) < Cell.IMPULSE) {
			randomImpulse();
		}

		super.update();
	}
}
