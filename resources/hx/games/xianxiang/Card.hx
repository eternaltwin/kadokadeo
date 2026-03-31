package xianxiang;

class Card {
	public var id:CardID;
	public var mc:ASprite;

	var game:Game;

	public var x:Int;
	public var y:Int;

	// public var color:Color;

	public function new(g, id, x, y) {
		this.id = id;
		this.game = g;
		this.x = x;
		this.y = y;
		initCard();
	}

	function initCard() {
		mc = game.dmanager.attach("card", Const.PLAN_CARD);
		// TO DO
		/*color = new Color(mc);
			mc._x = Const.BASE_X + x * Const.CARD_WIDTH;
			mc._y = Const.BASE_Y + y * Const.CARD_HEIGHT;
			downcast(mc).symbol.gotoAndStop(Std.string(id.symbol + 1));
			downcast(mc).socle.gotoAndStop(Std.string(id.socle + 1));

			var c = Const.COLORS[id.color];
			downcast(mc).socle.color.gotoAndStop(Std.string(id.color + 1));

			var me = this; */
		// TO DO
		// mc.onPress = fun() {
		// 		me.game.cardSelect(me)
		// 	};
		// 	KKApi.registerButton(mc);
	}

	public function desactivate() {
		mc.onPress = null;
	}

	public function destroy() {
		mc.removeMovieClip();
	}
}
