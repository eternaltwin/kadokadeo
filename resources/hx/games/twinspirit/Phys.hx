package twinspirit;

// mcLabel: a name over the sprite (WALLIS / FUTUNA / ROBERT, pictures of the label with its bar)
class Label extends Mc {
	public var timer:Null<Float>;
	public var sy:Int;
	public var dec:Float;
	public var col:Int;

	public function new(id:Int) {
		super("label" + id, false);
	}
}

class Phys extends Sprite {
	public var ray:Float;
	public var frict:Null<Float>;
	public var vx:Float;
	public var vy:Float;
	public var vr:Null<Float>;

	public var mcLabel:Label;

	var glow:Dynamic;

	public function new(mc:ASprite) {
		super(mc);
		vx = 0;
		vy = 0;
		ray = 1;
	}

	override public function update() {
		if (vr != null)
			root._rotation += vr;
		if (frict != null) {
			vx *= frict;
			vy *= frict;
		}

		x += vx;
		y += vy;

		super.update();
		if (mcLabel != null)
			updateLabel();
	}

	// label: 0 Wallis, 1 Futuna, 2 Robert (null: only the glow)
	public function setLabel(col:Int, ?label:Null<Int>, ?timer:Null<Float>) {
		if (label != null) {
			mcLabel = Game.me.dm.add(new Label(label), Game.DP_FX);
			mcLabel._x = -1000;
			mcLabel.timer = timer;
			mcLabel.sy = -1;
			mcLabel.dec = 10;
			mcLabel.col = col;
		}
		setGlow(4, col);
	}

	// Filt.glow(root, gl, gl, col)
	public function setGlow(gl:Float, col:Int) {
		if (gl <= 0.05) {
			root.filters = null;
			glow = null;
			return;
		}
		if (glow == null) {
			root.filters = null;
			glow = Filt.glow(root, 8, 2, col, false, 0.2);
		}
		glow.color = col;
		glow.outerStrength = gl * 0.5;
	}

	public function updateLabel() {
		mcLabel._x = x;
		mcLabel._y = y + (ray + mcLabel.dec) * mcLabel.sy;
		if (mcLabel.timer != null) {
			mcLabel.timer--;
			var c = mcLabel.timer / 10;
			if (c < 1) {
				mcLabel._alpha = c * 100;
				if (mcLabel.timer < 0)
					mcLabel.removeMovieClip();
				setGlow(c * 4, mcLabel.col);
			}
		}
	}

	public function addToVictims() {
		var dx = Game.me.htrg.x - x;
		var dy = Game.me.htrg.y - y;
		Game.me.victims.push({p: this, ray: Math.sqrt(dx * dx + dy * dy)});
	}

	public function warp() {
		var mc = Game.me.dm.attach("warp", Game.DP_FX);
		mc.removeAfter = true;
		mc._x = x;
		mc._y = y;
		mc._xscale = mc._yscale = 40 + ray * 5;
		kill();
	}

	override public function kill() {
		if (mcLabel != null)
			mcLabel.removeMovieClip();
		super.kill();
	}
}
