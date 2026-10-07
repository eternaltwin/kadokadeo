package ktrain;

import ktrain.MC.FilterSpec;

// mt.bumdum.Phys (libs-haxe2, as compiled in the released game.swf): speed, weight, rotation, growth and a timer
// after which the clip fades (fadeType) and dies. The collected gems, the piouz hit by the train (it shrinks and can
// still be collected while it fades: vsc is game state, rounded) and the effects.
class Phys extends Sprite {
	public var frict:Null<Float>;
	public var vx:Float;
	public var vy:Float;
	public var vr:Null<Float>;
	public var fr:Null<Float>;
	public var vsc:Null<Float>;
	public var sleep:Null<Float>;
	public var timer:Null<Float>;
	public var alpha:Float;
	public var weight:Null<Float>;
	public var fadeLimit:Float;
	public var fadeType:Null<Int>;

	public function new(mc:MC) {
		super(mc);
		vx = 0;
		vy = 0;
		fadeLimit = 10;
		alpha = 100;
	}

	public function setAlpha(n:Float) {
		alpha = n;
		root._alpha = alpha;
	}

	override public function update() {
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
			vy += weight * Timer.tmod;

		if (frict != null) {
			var f = Const.q(Math.pow(frict, Timer.tmod));
			vx *= f;
			vy *= f;
		}

		x += vx * Timer.tmod;
		y += vy * Timer.tmod;

		if (vr != null)
			root._rotation += vr * Timer.tmod;
		if (fr != null)
			vr *= Const.q(Math.pow(fr, Timer.tmod));
		if (vsc != null) {
			root._xscale *= Const.q(Math.pow(vsc, Timer.tmod));
			root._yscale = root._xscale;
		}

		if (timer != null) {
			timer -= Timer.tmod;
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
						var n = (1 - c) * 16;
						// Filt.blur(root, n, 0): one more BlurFilter on the clip each frame
						var l = root.getFilters();
						l.push(Blur(n, 0));
						root.setFilters(l);
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
