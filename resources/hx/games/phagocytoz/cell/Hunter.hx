package phagocytoz.cell;

import phagocytoz.Cell;
import phagocytoz.Element;
import phagocytoz.Game;
import phagocytoz.Gfx;

class Hunter extends Cell {
	public function new(r:Float) {
		super(r);
		consume = true;
		sprite.env.gotoAndStop(2);
		sprite.noyau.gotoAndStop(2);
	}

	override function update() {
		ia();
		super.update();
	}
}
