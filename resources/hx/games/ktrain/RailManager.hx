package ktrain;

import haxe.ds.List;

// RailManager.hx of the original: the rails, 5 pieces of 120 pixels prepared, shown, and prepared again when the
// last one has gone down past the screen
class RailManager {
	static var rails:Array<MC> = [];
	static var nrails:List<MC> = new List();
	static var displayed = false;
	static var game:Game = null;
	static var countRails = -1;
	static var countDone = false;

	public static var lock = false;

	// port: the statics of the original (the SWF was loaded again for every game)
	public static function reset() {
		rails = [];
		nrails = new List();
		displayed = false;
		game = null;
		countRails = -1;
		countDone = false;
		lock = false;
	}

	public static function init(g:Game) {
		game = g;
		prepare();
		display();
	}

	public static function scroll(scr:Float) {
		if (lock)
			return;
		var i = 0;
		while (i < rails.length) {
			var r = rails[i++];
			r.y += scr;
			r._y = r.y;
		}
	}

	public static function update(scroll:Float) {
		if (lock)
			return;

		// (the length is read at each turn: display() adds the rails it shows, updated in this same loop)
		var i = 0;
		while (i < rails.length) {
			var r = rails[i++];
			var count = countRails;
			if (r.idx == count && r._y > Const.HEIGHT + Const.RAIL_H && r.idx > 0 && !countDone) {
				countDone = true;
				r.idx = -1;
				prepare();
			}

			if (r.idx == 0 && r._y >= -Const.RAIL_H && !displayed) {
				countDone = false;
				r.idx = -1;
				display(r._y);
			}

			if (r._y > Const.HEIGHT + Const.RAIL_H) {
				r.d = true;
			}
		}
	}

	// (the length is read once: after a removal the next rail moves to the index and waits for the next frame; past the
	// end, the rail is undefined)
	public static function clean() {
		var n = rails.length;
		for (i in 0...n) {
			var r = rails[i];
			if (r != null && r.d) {
				r.removeMovieClip();
				r = null;
				rails.splice(i, 1);
			}
		}
	}

	public static function prepare() {
		displayed = false;
		countRails = -1;
		for (i in 0...5) {
			var r = game.dm.attach("mcRail", Const.DP_RAIL);
			r.gotoAndStop(1);
			r.idx = i;
			r._x = Const.CENTER_X;
			r._visible = false;
			r.d = false;
			nrails.add(r);
			countRails++;
		}
	}

	public static function display(y = 0.0) {
		if (displayed)
			return;

		var i = 0;
		for (r in nrails) {
			i++;
			r._visible = true;
			if (y != 0)
				r.y = r._y = -Const.HEIGHT - Const.RAIL_H + y + (-Const.HEIGHT + i * Const.RAIL_H);
			else
				r.y = r._y = -Const.HEIGHT + i * Const.RAIL_H;
			// port: prepared hidden at y 0, now above the screen (not interpolated from 0)
			r.teleport();

			rails.push(r);
			nrails.remove(r);
		}
		displayed = true;
	}
}
