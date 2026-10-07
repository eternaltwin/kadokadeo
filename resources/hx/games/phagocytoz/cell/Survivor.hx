package phagocytoz.cell;

import phagocytoz.Cell;
import phagocytoz.Element;
import phagocytoz.Game;
import phagocytoz.Gfx;

class Survivor extends Cell {
	public function new(r:Float) {
		super(r);
		// consume = true;
	}

	override function update() {
		ia();
		super.update();
	}

	override function majNear() {
		near = [];
		nearTimer = 30 + Seed.random(10);

		for (c in Game.me.cells) {
			if (c != this && c.ray > ray) {
				var dx = Cell.ddx(x - c.x);
				var dy = Cell.ddy(y - c.y);
				var dist = Math.sqrt(dx * dx + dy * dy) - (c.ray + ray);
				near.push({cell: c, dist: dist});
			}
		}
		sortNears(near);
		near = near.slice(0, 20);
	}
}
