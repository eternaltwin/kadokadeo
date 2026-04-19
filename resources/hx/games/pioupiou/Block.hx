package pioupiou;

class Block {
	var game:Game;

	public var mc:ASprite;
	public var x:Int;
	public var y:Int;
	public var dy:Float;
	public var speed:Float;
	public var ann:ASprite;
	public var time:Float;

	public function new(g:Game, x:Int, y:Int) {
		game = g;
		this.x = x;
		this.y = y;
		dy = 0;
		initBlock();
	}

	function initBlock():Void {
		mc = game.dmanager.attach("block", Cs.PLAN_BLOCK);
		mc.onFrame.set(13, function() {
			game.level.destroyBlock(this);
		});
		setPos();
	}

	public function setPos():Void {
		mc._x = x * Cs.BLK_WIDTH + Cs.DELTA_X;
		mc._y = (game.level.base_y - y) * Cs.BLK_HEIGHT + Cs.DELTA_Y + dy;
	}

	public function destroy():Void {
		mc.removeMovieClip();
	}
}
