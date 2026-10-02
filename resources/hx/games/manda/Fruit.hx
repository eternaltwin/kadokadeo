package manda;


class Fruit extends Item {
	var dmanager:Plans;

	public var add_queue:Bool;

	// points of the fruit replaced by the canne (x10)
	public var fixedPoints:Null<Int>;

	public function new(id:Int, mc:ItemMc, dman:Plans) {
		super(id, mc, 6 + (Seed.random(200) / 100));
		scale = 0.75;
		add_queue = true;
		dmanager = dman;
	}

	public static function basePoints(id:Int):Int {
		id++;
		if (id <= 25)
			return id * Cs.C5;
		else if (id <= 60)
			return Cs.C200 + (id - 25) * Cs.C10;
		else if (id <= 100)
			return Cs.C700 + (id - 60) * Cs.C20;
		else if (id <= 145)
			return Cs.C1900 + (id - 100) * Cs.C30;
		else if (id <= 170)
			return Cs.C4000 + (id - 145) * Cs.C50;
		else
			return Cs.C6000 + (id - 170) * Cs.C100;
	}

	public function points():Int {
		return fixedPoints != null ? fixedPoints : basePoints(id);
	}

	override function createShade():ItemMc {
		var shade = dmanager.add(new ItemMc(mc.game, ItemMc.SHADE), Cs.PLAN_FRUITS_SHADE);
		shade.goStop(ItemMc.OMBRE);
		shade.fGoto(id + 1);
		return shade;
	}
}
