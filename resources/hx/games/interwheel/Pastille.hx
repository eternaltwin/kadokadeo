package interwheel;

class Pastille extends Element {
	var type:Int;
	var cn:ASprite;

	public function new() {
		super();
		ray = 20 * Cs.NEW_GEN_SCALE;
		skin = "mcPastille";

		type = 0;
		if (Cs.random(30) == 0)
			type = 1;
		if (Cs.random(200) == 0)
			type = 2;
	}

	public override function update() {
		super.update();
		if (Cs.game.blob.getDist(this) < 70 * Cs.NEW_GEN_SCALE) {
			flRemove = true;
			var p = new Spark(Cs.game.dm.empty(Game.DP_PART));
			p.x = x;
			p.y = y;
			p.c.gotoAndStop(type + 1);
			p.score = Cs.SCORE_PASTILLE[type];
			Cs.game.stats.b[type]++;
		};
		if (cn != null) {
			var sc = 90 + Math.random() * 20;
			cn._xscale = sc;
			cn._yscale = sc;
		}
	}

	public override function attach() {
		super.attach();
		var o = Cs.game.eList[0];
		for (wh in o.list) {
			if (Cs.getDist(wh, this) < wh.ray + 20 * Cs.NEW_GEN_SCALE) {
				flRemove = true;
				if (root != null) {
					root.removeMovieClip();
					root = null;
				}
			}
		}
		cn = root;
		if (cn != null) {
			cn.gotoAndStop(type + 1);
			var bg = cn.attachMovie("mcPastilleBg");
			bg.loop = true;
			bg.play();
		}
	}
}
