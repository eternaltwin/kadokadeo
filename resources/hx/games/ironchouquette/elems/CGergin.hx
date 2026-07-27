package ironchouquette.elems;

// frame 14, 15, 16 (only 14 has _react, 15 is empty, 16 is completely different skin)
class CGergin extends Bads {
	public var follow:ASprite;
	public var react:ASprite;

	public function new(last:CGergin = null, variant:Bool = false) {
		var root = Cs.game.dm.empty(Game.DP_BADS);
		super(root);
		var body = root.attachMovie(variant ? "gerginBodyVariant" : "gerginBody", 1);

		setLevel(22);
		setScore(Cs.C_GERGIN);
		hp = 30;
		rect = {rw: KadoKadeoManager.I(20), rh: KadoKadeoManager.I(26)}
		if (last == null) {
			follow = root.attachMovie("gerginTurret", 2);
			follow._x = -KadoKadeoManager.I(11);
			react = root.attachMovie("gerginReactor", 0);
			react.loop = true;
			react.play();
			react._visible = false;
			react._x = -KadoKadeoManager.I(23);

			bList = [6];
			acc = {
				c: KadoKadeoManager.S(0.1),
				lim: KadoKadeoManager.I(1)
			};
			frict = 0.9;
			var m = KadoKadeoManager.I(40);
			beeRange = [
				{
					w: 6,
					xMin: m,
					xMax: Cs.mcw - m * 2,
					yMin: m,
					yMax: KadoKadeoManager.I(90)
				},
			];
		} else {
			last.setPart(this, KadoKadeoManager.I(40), 0);
			var raf = newRafale();
			raf.addShot(1, [3, 0.15], 7, 12);
			raf.cooldown = 48;
			raf.dy = KadoKadeoManager.I(25);

			var f = () -> {
				last.bList = [3];
				last.turnCoef = 0.1;
				last.va = 0.1;
				last.trg = Cs.game.hero;
				last.flOrient = true;
				last.react._visible = true;
			}
			onDeath = f;

			var f2 = () -> {
				bList = [3];
				turnCoef = 0.2;
				va = 1;
				trg = {
					x: Cs.mcw * 0.5,
					y: KadoKadeoManager.S(40)
				};
				weapons = [];
				var r = newRafale();
				r.addShot(4, [3, 0.9], 5, 12);
				r.cooldown = 48;
				r.dy = KadoKadeoManager.I(25);
			}

			last.onDeath = f2;
		}
	}

	public override function update() {
		super.update();

		// TURRET
		if (follow != null && root != null) {
			var dx = Cs.game.hero.x - x;
			var dy = Cs.game.hero.y - y;
			follow._rotation = Math.atan2(dy, dx) / 0.0174 - root._rotation;
		}
	}
}
