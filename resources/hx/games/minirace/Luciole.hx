package minirace;

import pixi.mesh.NineSlicePlane;

// light streak of an overtaking (partLine with the glow of the overtaken car): it races along the track
class Luciole extends Tracker {
	// glow of the original (Filt.glow(root, 10, 2, colors[1])): 10 screen pixels = 5 map units
	static inline var GLOW = 5.0;

	public var flLine:Bool;

	var acc:Float;
	var line:NineSlicePlane;

	public function new(mc:ASprite, pid:Int) {
		super(mc);
		vfx = true;
		flLine = false;
		cpi = 0;

		acc = 0.01 + Seed.randVfx() * 0.2;
		// root.gotoAndPlay(Std.random(2) + 1): partLine has one frame
		Seed.randomVfx(2);

		turnCoef = 0.1 + Seed.randVfx() * 0.2;
		turnLimit = 0.8 + Seed.randVfx();

		timer = 10 + Seed.randVfx() * 120;

		// the segment (Data.LINE_L units from LINE_X0 px) with its glow: the ends of the image keep their size
		var t = Tex.get("partLine" + pid)[0];
		var cap = Data.LINE_X0 + GLOW * Data.MAP_PX * 0.5 + 1;
		line = new NineSlicePlane(t, cap, 0, Data.LINE_W - Data.LINE_X0 - Data.LINE_L * Data.MAP_PX + GLOW * Data.MAP_PX * 0.5 + 1, 0);
		line.scale.set(1 / Data.MAP_PX, 1 / Data.MAP_PX);
		line.y = -t.defaultAnchor.y * t.orig.height / Data.MAP_PX;
		line.visible = false;
		root.addChild(line);
	}

	override public function update() {
		var opx = x;
		var opy = y;

		speed += acc;
		move();
		// (Phys.update a second time: the streaks move twice per frame, like in the original)
		super.update();

		if (flLine && !dead) {
			var dx = x - opx;
			var dy = y - opy;
			var a = Math.atan2(dy, dx);
			var dist = Math.sqrt(dx * dx + dy * dy);
			// root._xscale = dist: a segment of dist units, its glow fades when it is shorter than the blur
			var w:Float = Data.LINE_W + (dist - Data.LINE_L) * Data.MAP_PX;
			untyped line.width = w;
			line.x = -Data.LINE_X0 / Data.MAP_PX;
			line.alpha = Math.min(1, dist / GLOW);
			line.visible = dist > 0;
			root._rotation = a / 0.0174;
		}
	}
}
