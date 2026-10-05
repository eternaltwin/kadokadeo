package electrolink;

// mt.bumdum.Phys of the original (as compiled in the released game.swf). Speeds and timers are scaled by
// mt.Timer.tmod: 0.8 in Electrolink (Flash ran it at 40 frames/s for Timer.wantedFPS = 32, see Game.update)
class Phys extends Sprite {
	public var vx:Float;
	public var vy:Float;
	public var vr:Null<Float>;
	public var fr:Null<Float>;
	public var vsc:Null<Float>;
	public var frict:Null<Float>;
	public var weight:Null<Float>;
	public var sleep:Null<Float>;
	public var timer:Null<Float>;
	public var fadeLimit:Float;
	// null: fade out by alpha (the default of the switch)
	public var fadeType:Null<Int>;
	public var alpha:Float;

	public function new(mc:MC) {
		super(mc);
		vx = 0;
		vy = 0;
		fadeLimit = 10;
		alpha = 100;
	}

	override public function update():Void {
		var tmod = mt.Timer.tmod;
		if (sleep != null) {
			sleep--;
			if (sleep < 0) {
				sleep = null;
				root._visible = true;
				root.play();
			}
			return;
		}
		if (weight != null)
			vy += weight * tmod;
		if (frict != null) {
			var f = Math.pow(frict, tmod);
			vx *= f;
			vy *= f;
		}
		x += vx * tmod;
		y += vy * tmod;
		if (vr != null)
			root._rotation += vr * tmod;
		if (fr != null)
			vr *= Math.pow(fr, tmod);
		if (vsc != null) {
			root._xscale *= Math.pow(vsc, tmod);
			root._yscale = root._xscale;
		}
		if (timer != null) {
			timer -= tmod;
			if (timer < fadeLimit) {
				var c = timer / fadeLimit;
				switch (fadeType) {
					case -1:
					case 0:
						root._xscale = c * scale;
						root._yscale = c * scale;
					case 1:
						root._visible = Std.int(timer) % 4 > 1;
					case 2:
						root.play();
					case 3:
						root._yscale = c * scale;
					case 4:
						// (Filt.blur(root, (1 - c) * 16, 0) too: fadeType 4 is not used by Electrolink)
						root._alpha = c * alpha;
					case 5:
						root._xscale = c * scale;
					default:
						root._alpha = c * alpha;
				}
				if (timer <= 0)
					kill();
			}
		}
		super.update();
	}
}
