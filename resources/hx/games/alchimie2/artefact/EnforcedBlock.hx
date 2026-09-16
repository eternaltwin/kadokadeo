package alchimie2.artefact;

// bloc
class EnforcedBlock extends StageObject {
	var level:Int;

	public function new(l:Int, ?dm:mt.DepthManager, ?depth:Int = 2) {
		super();
		id = Block(l);
		level = l;
		autoFall = false;
		isParasit = true;
		pdm = if (dm != null) dm else Game.me.stage.dm;

		omc = new ObjectMc(id, pdm, depth);
	}

	public function initKill() {
		effectTimer = 100;
		effectStep = 0;
	}

	public function updateKill() {
		switch (effectStep) {
			case 0:
				if (warm()) {
					for (sp in explode()) {
						sp.vsc = 1.05;
						sp.fadeType = 0;
						sp.timer = 10 + Seed.randVfx() * 20;
					}

					level--;
					if (level > 0) {
						omc.mc.gotoAndStop(level);
						effectStep = 1;
						effectTimer = 0;
					} else
						effectStep = 2;
				}

			case 1:
				if (colder()) {
					toKill = false;
					return false;
				}

			case 2:
				if (disappear()) {
					Game.me.stage.remove(this);
					return false;
				}
		}
		return true;
	}
}
