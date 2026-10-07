package memopsy;

import memopsy.Gfx.CardMC;
import memopsy.Gfx.FlipMC;

class Card {
	public static var cards:Array<Card> = [];

	public var id:Int;
	public var mc:CardMC;
	public var mcface:CardMC;
	public var flip:FlipMC;
	var game:Game;
	public var visible:Bool;
	var hideTimer:Float;
	// cell in the level grid (port: a press is recorded in the replay as one {k, x, y} event, see Game.pressCard)
	public var cx:Int;
	public var cy:Int;

	public function new(g:Game, id:Int, x:Int, y:Int) {
		this.id = id;
		visible = false;
		game = g;
		cx = x;
		cy = y;
		initCard(x, y);
	}

	function initCard(x:Int, y:Int) {
		var l = game.getLevel();
		var px = (300 - l.width * 50 + 8) / 2;
		var py = (290 - l.height * 70 + 6) / 2 + 10;

		mc = game.dmanager.add(new CardMC(), Const.PLAN_CARD);
		mc._x = px + x * 50;
		mc._y = py + y * 70;
		mc.stop();

		mcface = game.dmanager.add(new CardMC(), Const.PLAN_CARD);
		mcface._x = mc._x;
		mcface._y = mc._y;
		mcface._visible = false;
		mcface.gotoAndStop(id + 2);

		var me = this;
		mc.onPress = function() me.game.pressCard(me);
		// (KKApi.registerButton(mc): anti-cheat bookkeeping of the Flash player, nothing to do here)
	}

	public function show(b:Bool) {
		visible = b;
		flip = game.dmanager.add(new FlipMC(), Const.PLAN_CARD);
		flip._x = mc._x;
		flip._y = mc._y;
		flip.stop();
		flip.top.gotoAndStop(id + 2);
		flip.back.stop();
		mcface._visible = false;
		mc._visible = false;

		if (!visible) {
			flip.gotoAndStop(flip._totalframes);
			hideTimer = 10;
		}
		cards.push(this);
	}

	public function destroy() {
		mc.removeMovieClip();
		mcface.removeMovieClip();
	}

	public static function main(g:Game) {
		// explicit while: onShowDone pushes back into the list and the original splices with i--
		var i = 0;
		while (i < cards.length) {
			var c = cards[i];
			if (c.visible) {
				if (c.flip._currentframe == c.flip._totalframes) {
					c.flip.removeMovieClip();
					c.mcface._visible = true;
					cards.splice(i--, 1);
					g.onShowDone(c);
				}
				// (on the frame it completed, the flip was just removed: the call does nothing, like Flash; after a
				// failed pair, onShowDone gave the card a new flip on its last frame: nextFrame stays there)
				c.flip.nextFrame();
			} else {
				c.hideTimer -= mt.Timer.tmod;
				if (c.hideTimer <= 0) {
					if (c.flip._currentframe == 1) {
						c.flip.removeMovieClip();
						c.mc._visible = true;
						cards.splice(i--, 1);
						g.onShowDone(c);
					}
					c.flip.prevFrame();
				}
			}
			i++;
		}
	}
}
