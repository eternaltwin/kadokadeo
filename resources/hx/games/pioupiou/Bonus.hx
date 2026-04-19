package pioupiou;

class Bonus {
	var game:Game;

	public var mc:ASprite;
	public var x:Int;
	public var type:Int;
	public var falling:Bool;

	public function new(g:Game, x:Int, y:Int, t:Int) {
		game = g;
		this.x = x;
		type = t;
		falling = true;
		mc = game.dmanager.attach("bonus" + (type + 1), Cs.PLAN_BONUS);
		mc.loop = true;
		mc.play();
		recall(x, y);
	}

	public function destroy():Void {
		mc.removeMovieClip();
	}

	public function recall(x:Null<Int>, y:Null<Int>):Void {
		if (x != null) {
			mc._x = x * Cs.BLK_WIDTH + Cs.DELTA_X;
		}
		if (y != null) {
			mc._y = (game.level.base_y - y) * Cs.BLK_HEIGHT + Cs.DELTA_Y;
		}
	}
}
