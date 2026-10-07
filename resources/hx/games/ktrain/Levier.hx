package ktrain;

// Levier.hx of the original: the panel at the bottom left (lever m: the speed asked, c: the coal left, f: the needle of
// the speed, p: the train behind)
class Levier {
	static var mc:MC;
	static var game:Game;
	static var curSpeed = 0;
	static var speed = 0.0;
	static var pStartPos = 0.0;
	static var diff:Float = 0.0;

	// port: the statics of the original (the SWF was loaded again for every game)
	public static function reset() {
		mc = null;
		game = null;
		curSpeed = 0;
		speed = 0.0;
		pStartPos = 0.0;
		diff = 0.0;
	}

	public static function init(g:Game) {
		game = g;
		mc = game.dm.attach("mcLevier", Const.DP_INTER);
		mc._x = 5;
		mc._y = 220;
		var m = mc.sub("m");
		m.gotoAndStop(m._totalframes - 1);
		mc.sub("c").gotoAndStop(3);
		pStartPos = Data.LEV_P[1];
		updateCounter();
		diff = KKApi.val(Const.OPP_POS);
	}

	public static function updateOpp() {
		if (Game.startBoom > 0) {
			game.boom();
		}

		if (game.gameOver)
			return;

		if (game.opp > game.me) {
			var diff = game.opp - game.me;
			var dist = KKApi.val(Const.OPP_START) - diff;
			var pcd = 100 - dist / KKApi.val(Const.OPP_START) * 100;
			var v = pStartPos - KKApi.val(Const.OPP_POS) * pcd / 100;
			mc.setSub("p", null, v);

			if (v <= pStartPos - KKApi.val(Const.OPP_POS)) {
				mc.setSub("p", null, pStartPos - KKApi.val(Const.OPP_POS));
				Man.lock = true;
				Loco.doCrash();
				return;
			}

			if (v >= pStartPos) {
				mc.setSub("p", null, pStartPos);
				game.opp = game.me = 0;
			}
		}
	}

	public static function updateCoal() {
		mc.sub("c").gotoAndStop(Math.floor(game.coal / KKApi.val(Const.NEXT_STATION)) + 1);
	}

	public static function updateCounter() {
		if (Const.SPEED <= 0) {
			mc.setSub("f", null, null, null, null, -90);
			return;
		}

		var s = Math.floor(Const.SPEED * 10);
		var cs = s / Const.MAX_SPEED * 10;
		var a = -90 + Std.int(180 * cs / 100);
		mc.setSub("f", Data.LEV_C[0] - 8, Data.LEV_C[1], null, null, a);
	}

	public static function update(speed:Int) {
		if (speed == curSpeed)
			return;

		var m = mc.sub("m");
		if (speed < m._totalframes) {
			m.gotoAndStop(5 - speed);
		}
		curSpeed = speed;
	}

	public static function hide() {
		mc._visible = false;
	}

	public static function show() {
		mc._visible = true;
	}

	public static function noMoreCoal() {
		mc.sub("c").gotoAndStop(5);
	}
}
