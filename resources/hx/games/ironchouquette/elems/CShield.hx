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
		ray = KadoKadeoManager.I(27);
		shieldLim = KadoKadeoManager.I(120);

		var m = KadoKadeoManager.I(20);
		bList = [6, 10];
		acc = {
			c: KadoKadeoManager.S(0.1),
			lim: KadoKadeoManager.I(1)
		}
		frict = 0.92;
		beeRange = [
			{
				w: 6,
				xMin: m,
				xMax: Cs.mcw - m,
				yMin: m,
				yMax: KadoKadeoManager.I(170)
			},
		];
	}
}
