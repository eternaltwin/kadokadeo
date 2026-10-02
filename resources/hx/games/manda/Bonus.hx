package manda;

class Bonus extends Item {
	// (statics of the original: reset at the start of every game, a Flash game was a new SWF each time)
	public static var CISEAUX_COUNT = 1;
	public static var POTION_BLEUES = 0;

	public function new(id:Int, mc:ItemMc) {
		super(id, mc, 7 + (Seed.random(300) / 100));
	}

	public function activate(g:Game) {
		var x = mc._x;
		var y = mc._y;
		mc.remove();

		switch (id) {
			case 0: // CISEAUX
				// for(i=0;i<CISEAUX_COUNT,g.snake.len > 0;i++): both conditions (released SWF), each scissors cut one piece
				// more than the previous ones
				var i = 0;
				while (i < CISEAUX_COUNT && g.snake.len > 0) {
					g.snake.explode(g.snake.getColor());
					i++;
				}
				CISEAUX_COUNT++;
			case 1: // COFFRE
				var nfruits = 5 + Seed.random(5);
				for (i in 0...nfruits) {
					var f = g.level.generateFruit();
					f.setPos(x, y);
					f.add_queue = false;
					f.jumpNear(Seed.random(20) + 20, Seed.random(10) + 15, 0.05);
				}
			case 2: // POTION BLEUE
				var time = 15.0;
				POTION_BLEUES++;
				g.snake.blue = true;
				g.snake.blue_flag = true;
				var fupdate:Void->Void = null;
				fupdate = function() {
					time -= Timer.deltaT;
					if (time < 2 && POTION_BLEUES == 1 && (g.fcounter & 2) == 0)
						g.snake.blue_flag = false;
					else
						g.snake.blue_flag = true;
					if (time < 0) {
						if ((--POTION_BLEUES) == 0)
							g.snake.blue = false;
						g.updates.remove(fupdate);
					}
				};
				g.updates.push(fupdate);
			case 3: // CANNE
				var f = g.level.generateFruit();
				var pts = f.points() * Cs.C10;
				f.setPos(Cs.WIDTH / 2, Cs.HEIGHT / 2);
				f.mc.goStop(ItemMc.STANDARD);
				f.z = 100;
				f.scale *= 2;
				f.fall(0.08);
				f.fixedPoints = pts;
			case 4: // MOLECULE
				new PopScore(g, x, y, 3000, g.dmanager.empty(Cs.PLAN_POPSCORE));
				g.addScore(Cs.C3000);
				g.fbarre += 10;
				if (g.fbarre > Cs.FBARRE_MAX)
					g.fbarre = Cs.FBARRE_MAX;
			case 5: // PLUME
				g.snake.speed -= 1.0;
				if (g.snake.speed < Cs.SNAKE_MIN_SPEED)
					g.snake.speed = Cs.SNAKE_MIN_SPEED;
			case 6: // CLOCHE
				if (g.fcloche != null)
					return;
				var n = g.snake.len;
				g.fcloche = function() {
					if (g.snake.len <= 0 || n <= 0) {
						g.fcloche = null;
						return;
					}
					var p = g.snake.endQueuePos(0);
					if (g.snake.len % 2 == 0) {
						var f = g.level.generateFruit();
						f.id = 75;
						f.mc._x = p.x;
						f.mc._y = p.y;
						f.mc.fGoto(76);
					}
					g.snake.explode(g.snake.getColor());
					g.snake.draw();
					n--;
				};
			case 7: // JACKPOT
				g.jackpot.start();
		}
	}
}
