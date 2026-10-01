package xianxiang;

import pixi.filters.colormatrix.ColorMatrixFilter;

class Card {
	public var id:CardID;
	public var mc:ASprite;

	var game:Game;

	public var x:Int;
	public var y:Int;

	var color:ColorMatrixFilter;
	var active:Bool;

	public function new(g, id, x, y) {
		this.id = id;
		this.game = g;
		this.x = x;
		this.y = y;
		initCard();
	}

	function initCard() {
		mc = game.dmanager.empty(Const.PLAN_CARD);
		mc._x = Const.BASE_X + x * Const.CARD_WIDTH;
		mc._y = Const.BASE_Y + y * Const.CARD_HEIGHT;

		// "card" clip: socle (with its "color" child) + symbol, all registered on the card origin
		var socle = mc.attachMovie("socle", "socle", 1);
		socle.gotoAndStop(id.socle + 1);
		var socleColor = socle.attachMovie(Const.SOCLE_NAMES[id.socle] + "_color", "color", 2);
		socleColor.gotoAndStop(id.color + 1);
		var symbol = mc.attachMovie("symbol", "symbol", 4);
		symbol.gotoAndStop(id.symbol + 1);

		// onPress is polled by Game.update (replay friendly)
		active = true;
	}

	public function hitTest(px:Float, py:Float) {
		return active
			&& px >= mc._x
			&& py >= mc._y
			&& px < mc._x + Const.CARD_HIT_WIDTH
			&& py < mc._y + Const.CARD_HIT_HEIGHT;
	}

	// Color.setTransform({ra: 100, rb: c, ga: 100, gb: c, ba: 100, bb: c, aa: 100, ab: 0})
	public function setColorOffset(c:Int) {
		if (color == null)
			color = new ColorMatrixFilter();
		var o = c / 255;
		color.matrix = [
			1, 0, 0, 0, o,
			0, 1, 0, 0, o,
			0, 0, 1, 0, o,
			0, 0, 0, 1, 0
		];
		mc.filters = [color];
	}

	// Color.reset()
	public function resetColor() {
		mc.filters = null;
	}

	public function desactivate() {
		active = false;
	}

	public function destroy() {
		mc.removeMovieClip();
	}
}
