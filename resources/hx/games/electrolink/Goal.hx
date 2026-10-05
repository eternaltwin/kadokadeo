package electrolink;

import electrolink.Gfx.GoalMC;

class Goal {
	public var toExplode:Bool;
	public var explosionCount:Int;
	public var side:Int;
	public var index:Int;

	public var mc:GoalMC;

	public function new() {
		toExplode = false;
		explosionCount = 0;

		mc = Game.me.dm.add(new GoalMC(), Game.DP_GOALS);
		mc.smc.gotoAndStop(1);
		mc._xscale = 70;
		mc._yscale = 70;
	}

	public function setPos(s:Int, index:Int) {
		side = s;
		this.index = index;

		if (side == 0) {
			mc._x = Cs.BOARD_X + -1 * Cs.TILE_SIZE;
			mc._xscale = -70;
		} else
			mc._x = Cs.BOARD_X + Cs.BOARD_WIDTH * Cs.TILE_SIZE;

		mc._y = Cs.BOARD_Y + index * Cs.TILE_SIZE;
	}

	public function activate(?justLight:Int) {
		if (justLight == null || justLight == Cs.PARSE_IN) {
			toExplode = true;
			Game.me.explode[side]++;
		}
		mc.smc.gotoAndStop(side + 2);

		mc.smc.syncPulse(Game.me.cTile.mc.smc.smc.pulseFrame());
	}

	public function charge() {
		mc.smc.gotoAndStop(2);
		mc.smc.syncPulse(Game.me.cTile.mc.smc.smc.pulseFrame());
		// Filt.glow(mc, 10, 2, 0xFFFFFF)
		mc.glow = true;
		Game.parts(mc._x, mc._y);
	}

	public function shutdown() {
		toExplode = false;
		mc.smc.gotoAndStop(1);
	}

	public function explode() {
		var points = KKApi.cmult(KKApi.cmult(Cs.GOAL_POINTS, KKApi.const(Std.int(Math.max(Game.me.getExplosions(), 1)))),
			KKApi.const(Game.comboMult(Game.me.combo)));
		Game.me.addScore(points);
		prepare();
	}

	public function prepare() {
		toExplode = false;
		unLight();
		explosionCount++;
	}

	public function unLight() {
		// mc.filters = []
		mc.glow = false;
		mc.smc.gotoAndStop(1);
	}
}
