package manda;

import pixi.core.graphics.Graphics;

typedef Slot = {mc:ASprite, fruit:Pic, id:Int};

// the 3 slots under the field: they spin among the last fruits eaten, 2 or 3 identical ones win
class Jackpot {
	var game:Game;

	public var encyclo:Array<Int>;

	var slots:Array<Slot>;
	var nturns:Float;
	var coins:Int;

	public var count2:Int;
	public var count3:Int;

	public function new(g:Game) {
		game = g;
		coins = 0;
		nturns = 0;
		count2 = 0;
		count3 = 0;
		encyclo = new Array();
		slots = new Array();
		initSlots();
	}

	// clip "jackpot": frame (d2), fruit f (d4) masked by a rounded square (d3), glass (d20). The fruit is cut by the
	// square of the mask, its rounded corners are covered by the frame outside the mask (slotCorner).
	function initSlots() {
		var m = Data.SLOT_MASK;
		for (i in 0...3) {
			var mc = game.interf.add(new ASprite(), Cs.PLAN_JACKPOT);
			mc._x = 110 + i * 30;
			mc._y = 270;
			mc.addChild(new Pic("slotBack"));
			var fruit = new Pic("slotFruit");
			fruit._x = 12;
			fruit._y = 14.6;
			var mask = new Graphics();
			mask.beginFill(0xFFFFFF);
			mask.drawRect(m[0], m[1], m[2] - m[0], m[3] - m[1]);
			mask.endFill();
			mc.addChild(mask);
			fruit.mask = mask;
			mc.addChild(fruit);
			mc.addChild(new Pic("slotCorner"));
			mc.addChild(new Pic("slotFront"));
			slots.push({
				mc: mc,
				fruit: fruit,
				id: 0
			});
		}
	}

	public function addFruit(id:Int) {
		if (id == 75) // fruit cloche
			return;
		encyclo.push(id);
		while (encyclo.length > 10)
			encyclo.shift();
	}

	public function start() {
		if (nturns <= 0)
			nturns = 100;
		else
			coins++;
	}

	function jackpot(id:Int, big:Bool) {
		var pts = Fruit.basePoints(id) * (big ? Cs.C20 : Cs.C5);
		new PopScore(game, 160, 285, pts, game.interf.empty(Cs.PLAN_POPSCORE));
		game.addScore(pts);
		if (big)
			count3++;
		else
			count2++;
	}

	public function main() {
		if (nturns > 0) {
			nturns -= Timer.tmod;
			for (i in 0...3) {
				var s = slots[i];
				if (nturns > (2 - i) * 30) {
					var id = encyclo[Seed.random(encyclo.length)];
					s.id = id;
					s.fruit.show(id + 1);
					s.fruit._y = Seed.randomVfx(30);
				} else
					s.fruit._y = 15;
				// the fruits jump from a place to another: not interpolated
				s.fruit.updateState();
			}
			if (nturns <= 0) {
				var b1 = slots[0].id == slots[1].id;
				var b2 = slots[1].id == slots[2].id;
				var b3 = slots[0].id == slots[2].id;
				if (b1 && b2 && b3)
					jackpot(slots[0].id, true);
				else if (b1 || b3)
					jackpot(slots[0].id, false);
				else if (b2)
					jackpot(slots[1].id, false);
				if (coins > 0) {
					coins--;
					nturns = 100;
				}
			}
		}
	}
}
