package kanjisnightmare;

class Phys extends Sprite {
	public var flOrient:Bool;

	public var ray:Float;
	public var weight:Null<Float>;
	public var frict:Null<Float>;
	public var vx:Float;
	public var vy:Float;
	public var vr:Null<Float>;

	public function new(mc:ASprite) {
		super(mc);
		frict = 0.95;
		vx = 0;
		vy = 0;
		ray = 0;
		flOrient = false;
	}

	override public function update() {
		if (vr != null)
			root._rotation += vr * Timer.tmod;
		if (weight != null)
			vy += weight * Timer.tmod;
		if (frict != null) {
			var f = Math.pow(frict, Timer.tmod);
			vx *= f;
			vy *= f;
		}
		x += vx * Timer.tmod;
		y += vy * Timer.tmod;
		if (flOrient)
			orient();
		super.update();
	}

	public function checkPlatCol() {
		if (vy > 0) {
			var py = y + ray;
			var oy = py - vy * Timer.tmod;
			for (pl in Cs.game.platList) {
				if (oy < pl.y && py > pl.y && x > pl.x && x < pl.x + pl.w) {
					y = pl.y - ray;
					land(pl);
					break;
				}
			}
		}
	}

	public function land(plat:Plat) {}

	public function orient() {
		var sens = 1;
		if (vx < 0)
			sens = -1;
		root._xscale = sens * 100;
		root._rotation = Math.atan2(vy, vx) / 0.0174;
		if (vx < 0)
			root._rotation += 180;
	}

	public function speedToward(o:{x:Float, y:Float}, c:Float, lim:Float) {
		var dx = o.x - x;
		var dy = o.y - y;
		vx += Cs.mm(-lim, dx * c, lim);
		vy += Cs.mm(-lim, dy * c, lim);
	}
}
