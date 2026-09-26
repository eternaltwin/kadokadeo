package kanjisadventure.ent;

import kanjisadventure.*;

class Trader extends Ent {
	public function new() {
		super();
		flTrader = true;
		lifeMax = 5;
		init();
	}

	//
	override function attach():ASprite {
		root = sq.dm.attach("mcTrader", Square.DP_ACTOR);
		return root;
	}

	//
	override function die() {
		var id = 3;
		if (Seed.random(5) == 0)
			id = 4;
		sq.addItem(id);
		sq.showItem();

		root.gotoAndPlay(2);
		root = null;

		super.die();
	}
	/*
		public function setSquare(sq:Square){
			//trace("setSq("+sq+")");
			super.setSquare(sq);
		}
	 */
}
/*





	enum AttackBehaviour {
	ABRandom(c:Float);
	ABStick;
	ABCoward;
	}
	enum MoveBehaviour {
	ABFollow;
	ABRandom(c:Float);
	}





 */
