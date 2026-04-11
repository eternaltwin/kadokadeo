package ironchouquette.elems;

// frame 14, 15, 16 (only 14 has _react, 15 is empty, 16 is completely different skin)
class CGergin extends Bads {
	public var follow:ASprite;
	public var react:ASprite;

	public function new(last:Bads = null, variant:Bool = false) {
		var root = Cs.game.dm.attach(variant ? "gerginBodyVariant" : "gerginBody", Game.DP_BADS);
		super(root);

		setLevel(22);
		setScore(Cs.C_GERGIN);
		hp = 30;
		rect = {rw: 20 * Cs.NEW_GEN_SCALE, rh: 26 * Cs.NEW_GEN_SCALE}
		if (last == null) {
			follow = root.attachMovie("gerginTurret");
			react = root.attachMovie("gerginReactor");
			react.loop = true;
			react.play();
			react._visible = false;
			react._x = -23 * Cs.NEW_GEN_SCALE;

			bList = [6];
			acc = {c: 0.1 * Cs.NEW_GEN_SCALE, lim: 1 * Cs.NEW_GEN_SCALE}
			frict = 0.9;
			var m = 40 * Cs.NEW_GEN_SCALE;
			beeRange = [
				{
					w: 6,
					xMin: m,
					xMax: Cs.mcw - m * 2,
					yMin: m,
					yMax: 90 * Cs.NEW_GEN_SCALE
				},
			];
		} else {
			last.setPart(this, 40 * Cs.NEW_GEN_SCALE, 0);
			var raf = newRafale();
			raf.addShot(1, [3 * Cs.NEW_GEN_SCALE, 0.15], 7, 12);
			raf.cooldown = 48;
			raf.dy = 25 * Cs.NEW_GEN_SCALE;

			var f = () -> {
				last.bList = [3];
				last.turnCoef = 0.1;
				last.va = 0.1;
				last.trg = cast Cs.game.hero;
				last.flOrient = true;
				untyped last.react._visible = true;
			}
			onDeath = f;

			var f2 = () -> {
				bList = [3];
				turnCoef = 0.2;
				va = 1;
				trg = {x: Cs.mcw * 0.5, y: 40 * Cs.NEW_GEN_SCALE}
				weapons = [];
				var r = newRafale();
				r.addShot(4, [3 * Cs.NEW_GEN_SCALE, 0.9], 5, 12);
				r.cooldown = 48;
				r.dy = 25 * Cs.NEW_GEN_SCALE;
			}

			last.onDeath = f2;
		}
	}

	public override function update() {
		super.update();

		// TURRET
		if (follow != null) {
			var dx = Cs.game.hero.x - x;
			var dy = Cs.game.hero.y - y;
			follow._rotation = Math.atan2(dy, dx) / 0.0174 - root._rotation;
		}
	}
}
