package xianxiang;

class Card {
	var id:CardID;
	var mc:ASprite;
	var game:Game;
	var x:Int;
	var y:Int;
	var color:Color;

	function new(g, id, x, y) {
		this.id = id;
		this.game = g;
		this.x = x;
		this.y = y;
		initCard();
	}

	function initCard() {
		mc = game.dmanager.attach("card", Const.PLAN_CARD);
		color = new Color(mc);
		mc._x = Const.BASE_X + x * Const.CARD_WIDTH;
		mc._y = Const.BASE_Y + y * Const.CARD_HEIGHT;
		downcast(mc).symbol.gotoAndStop(Std.string(id.symbol + 1));
		downcast(mc).socle.gotoAndStop(Std.string(id.socle + 1));

		var c = Const.COLORS[id.color];
		downcast(mc).socle.color.gotoAndStop(Std.string(id.color + 1));

		var me = this;
		mc.onPress = fun()
		{
			me.game.cardSelect(me)
		};
		KKApi.registerButton(mc);
	}

	function desactivate() {
		mc.onPress = null;
	}

	function destroy() {
		mc.removeMovieClip();
	}
}
