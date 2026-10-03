package alphabounce.fx;

import mt.bumdum.Phys;

class Attract extends Phys {
	public var dx:Float;

	public function new(mc:ASprite) {
		super(mc);
		dx = 0;
	}

	override public function update() {
		var ox = x;
		var oy = y;

		var p = {x: Game.me.pad.x + dx, y: Game.me.pad.y};
		toward(p, 0.3);

		var vx = x - ox;
		var vy = y - oy;

		var vit = Math.sqrt(vx * vx + vy * vy);
		var a = Math.atan2(vy, vx);

		// (the picture is a line of 1.4 px with its glow)
		root._xscale = vit / 1.4 * 100;
		root._rotation = a / 0.0174;

		super.update();

		if (getDist(p) < 5)
			kill();
	}
}
