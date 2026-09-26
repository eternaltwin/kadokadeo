package kanjisadventure.ev;

class Floor extends Event {
	static inline var FADE_FRAMES = 12;

	var lvl:Int;
	var mcFader:ASprite;

	public function new(inc) {
		super();

		this.lvl = Game.me.cfl.id + inc;

		var etage = lvl + "ème sous-sol";
		if (lvl == 0)
			etage = "rez-de-chaussée";
		if (lvl == 1)
			etage = "1er sous-sol";
		if (lvl == 2)
			etage = "2d sous-sol";
		Game.me.log("Vous " + ["grimpez", "descendez"][inc < 0 ? 0 : 1] + " les escaliers vers le " + etage);

		spc = 1 / FADE_FRAMES;

		mcFader = Game.me.dm.empty(Game.DP_FADER);
		mcFader.getGraphics()
			.beginFill(0x000000)
			.drawRect(0, 0, KadoKadeoManager.I(Cs.mcw), KadoKadeoManager.I(Cs.mch))
			.endFill();
		mcFader._alpha = 0;
	}

	override function update() {
		super.update();

		switch (step) {
			case 0:
				mcFader._alpha = coef * 100;
				if (coef == 1) {
					Game.me.allies = [];
					for (ent in Game.me.cfl.ents) {
						if (ent.flGood && Game.me.hero != ent)
							Game.me.allies.push(ent);
					}
					Game.me.loadFloor(lvl);
					coef = 0;
					step++;
				}

			case 1:
				mcFader._alpha = (1 - coef) * 100;
				if (coef == 1)
					kill();
		}
	}

	override function kill() {
		mcFader.removeMovieClip();
		super.kill();
	}
}
