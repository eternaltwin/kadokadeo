package travoltax.opt;

import kado.Seed;
import travoltax.Common.Cs;
import travoltax.Common.Step;
import travoltax.Game;
import travoltax.Option;
import mt.bumdum.Lib;
import mt.bumdum.Phys;

class Contrat extends Option {
	var inc:Float;
	var wait:Int;
	var coef:Float;
	var index:Int;

	public function new() {
		super();
		Game.me.step = Freeze;
		destroyPiece();

		inc = 1;
		coef = 0;
		wait = 20 + Seed.random(20);
		index = 0;
	}

	public override function update() {
		coef += inc;
		while (coef > 1) {
			coef--;
			if (wait-- < 0)
				inc -= 0.04;
			Game.me.removeContrat(index);
			gotoNextFreeIndex();
			Game.me.addContrat(index);
			if (inc <= 0)
				kill();
		}

		super.update();
	}

	function gotoNextFreeIndex() {
		while (true) {
			index = (index + 1) % Cs.CONTRAT_MAX;
			if (Game.me.contrats[index] == null)
				break;
		}
	}

	public override function kill() {
		Game.me.initPlay();
		super.kill();
	}
}
