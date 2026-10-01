package elloninthedark;

// "mcScore" clip: the score field pops (scale / alpha timeline), holds, then fades while the burst plays
class ScorePopup extends Sprite {
	static var FIELD_SCALE = [
		0.0974, 0.5154, 0.8141, 0.9932, 1.053, 1.0353, 1.0177, 1, 1, 1, 1, 1, 1, 1.0639, 1.1278, 1.1917, 1.2556, 1.3195, 1.3835
	];
	static var FIELD_ALPHA = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0.832, 0.668, 0.5, 0.332, 0.168, 0];
	static var LAST_FRAME = 19;

	var field:ASprite;
	var frame:Int;
	var compt:Int;

	public function new(x:Float, y:Float, score:Int) {
		super(Cs.game.mdm.empty(Game.DP_PARTS));
		this.x = x;
		this.y = y;

		field = root.createEmptyMovieClip("field", 1);
		var txt = field.initTextField("field", {
			font: "Pricedown",
			size: KadoKadeoManager.I(26),
			color: 0xFFFFFF,
			align: "center",
			x: 0,
			y: KadoKadeoManager.I(-13)
		});
		txt.text = Std.string(score);

		var burst = root.attachMovie("mcScoreBurst", "burst", 3);
		burst.stopOnFrame = [26];
		burst.play();

		frame = 1;
		compt = 0;
		showFrame();
		updatePos();
	}

	override public function update() {
		super.update();
		frame++;
		// frame 9: compt = 10 / frame 12: if (compt-- > 0) gotoAndPlay(_currentframe - 1)
		if (frame == 9)
			compt = 10;
		if (frame == 12 && compt-- > 0)
			frame = 11;
		// frame 19: removeMovieClip()
		if (frame >= LAST_FRAME) {
			kill();
			return;
		}
		showFrame();
	}

	function showFrame() {
		field._xscale = FIELD_SCALE[frame - 1] * 100;
		field._yscale = field._xscale;
		field._alpha = FIELD_ALPHA[frame - 1] * 100;
	}
}
