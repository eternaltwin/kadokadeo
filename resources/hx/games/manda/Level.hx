package manda;

class Level {
	var game:Game;
	var bonus_time:Float;
	var bonus_inhib:Float;

	public var bonuses:Array<Bonus>;
	public var fruits:Array<Fruit>;

	var fl:Int;

	static var col = [0.0, 0, 0, 0];

	public function new(g:Game) {
		game = g;
		bonus_time = 0;
		bonus_inhib = 0;
		fruits = new Array();
		bonuses = new Array();
		fl = 0;
	}

	public function generateFruit():Fruit {
		var base = Std.int(game.fbarre / 3);
		var ampl = Math.round(game.fbarre * (Cs.FRUITS_MAX - base + 1) / Cs.FBARRE_MAX);
		var id = base + Seed.random(ampl);
		var mc = game.dmanager.add(new ItemMc(game, ItemMc.FRUIT), Cs.PLAN_FRUITS);
		mc._xscale = 75;
		mc._yscale = 75;
		mc.fGoto(id + 1);
		var f = new Fruit(id, mc, game.dmanager);
		fruits.push(f);
		fl++;
		return f;
	}

	function generateBonus() {
		var id;
		do {
			id = Cs.randomProbas(Cs.BONUS_PROBAS);
		} while (game.jackpot.encyclo.length < 5 && id == 7); // pas de jackpot
		var mc = game.dmanager.add(new ItemMc(game, ItemMc.BONUS), Cs.PLAN_FRUITS);
		mc._xscale = 75;
		mc._yscale = 75;
		mc.fGoto(id + 1);
		bonuses.push(new Bonus(id, mc));
	}

	public function main() {
		var tmod = Timer.tmod;
		if (!game.game_over_flag) {
			if (Seed.random(Math.round(Cs.FRUITS_FREQ * fruits.length / tmod)) == 0)
				generateFruit();
			if (bonus_inhib > 0) {
				bonus_inhib -= Timer.deltaT;
				bonus_time = 0;
			} else if (Seed.random(Math.round((Cs.BONUS_FREQ + game.getScore() / 10000) * (bonuses.length + 1) / tmod - bonus_time / 6)) == 0) {
				bonus_time = 0;
				generateBonus();
			} else
				bonus_time += tmod;
		}

		game.snake.colBox(col);
		var i = 0;
		while (i < fruits.length) {
			var f = fruits[i];
			if (!f.update()) {
				bonus_inhib += 6;
				game.fbarre += Cs.FBARRE_FRUIT_TIMEOUT;
				if (game.fbarre < 0)
					game.fbarre = 0;
				fruits.remove(f);
				fl--;
				i--;
			} else if (!game.game_over_flag && f.mc.hitBox(col) && game.eatFruit(f)) {
				fruits.remove(f);
				fl--;
				i--;
			}
			i++;
		}

		i = 0;
		while (i < bonuses.length) {
			var b = bonuses[i];
			if (!b.update()) {
				bonuses.remove(b);
				i--;
			} else if (!game.game_over_flag && b.mc.hitBox(col)) {
				b.activate(game);
				bonuses.remove(b);
				i--;
			}
			i++;
		}
	}
}
