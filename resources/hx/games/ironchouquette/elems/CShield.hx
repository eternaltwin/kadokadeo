package ironchouquette.elems;

// frame 19
class CShield extends Bads {
	public function new() {
		var root = Cs.game.dm.attach("shieldBody", Game.DP_BADS);
		super(root);

		root.loop = true;
		root.play();

		var zap = root.attachMovie("shieldZap");
		zap.loop = true;
		zap.play();

		var reflect = root.attachMovie("shieldReflect");
		reflect.loop = true;
		reflect.play();

		setLevel(13);
		setScore(Cs.C_SHIELD);
		hp = 10;
		ray = 27 * Cs.NEW_GEN_SCALE;
		shieldLim = 120 * Cs.NEW_GEN_SCALE;

		var m = 20 * Cs.NEW_GEN_SCALE;
		bList = [6, 10];
		acc = {c: 0.1 * Cs.NEW_GEN_SCALE, lim: 1 * Cs.NEW_GEN_SCALE}
		frict = 0.92;
		beeRange = [
			{
				w: 6,
				xMin: m,
				xMax: Cs.mcw - m,
				yMin: m,
				yMax: 170 * Cs.NEW_GEN_SCALE
			},
		];
	}
}
