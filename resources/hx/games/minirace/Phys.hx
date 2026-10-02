package minirace;

// mt.bumdum.Phys of the original (the fields that Mini-Race uses)
class Phys extends Sprite {
	public var frict:Null<Float>;

	public var vx:Float;
	public var vy:Float;
	public var vr:Null<Float>;
	public var fr:Null<Float>;
	public var timer:Null<Float>;
	public var alpha:Float;
	public var weight:Null<Float>;
	public var fadeLimit:Float;
	public var fadeType:Null<Int>;

	public function new(mc:ASprite) {
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
		if (weight != null)
			vy += weight * Timer.tmod;

		if (frict != null) {
			var f = Math.pow(frict, Timer.tmod);
			vx *= f;
			vy *= f;
		}

		x += vx * Timer.tmod;
		y += vy * Timer.tmod;

		if (vr != null)
			root._rotation += vr * Timer.tmod;
		if (fr != null)
			vr *= Math.pow(fr, Timer.tmod);

		if (timer != null) {
			timer -= Timer.tmod;
			if (timer < fadeLimit) {
				var c = timer / fadeLimit;
				switch (fadeType) {
					case 0:
						root._xscale = c * scale;
						root._yscale = c * scale;
					case 2:
						fadePlay();
					default:
						root._alpha = c * alpha;
				}
				if (timer <= 0) {
					kill();
					return;
				}
			}
		}

		super.update();
	}

	// fadeType 2: root.play() (the clip plays its end and removes itself)
	function fadePlay() {
		root.play();
	}
}
