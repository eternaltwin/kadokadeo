package klinkersurprise;

// the point the map is centred on (mcRunner, invisible: _alpha 0), moved by the mouse (Game.moveSelector) and by the
// scrollers between two levels. initPos / run (a runner painting the cells it crosses) are never called by the game.
class Selector extends Rel {
	var pos:Array<Int>;
	var charge:Array<Float>;

	public function new(mc:MC) {
		super(mc);
		charge = [0.0, 0.0];
		root._alpha = 0;
	}

	public function initPos(x:Int, y:Int):Void {
		pos = [x, y];
	}

	public function run():Void {
		var c = 0.005;
		var dx = Game.me.xmouse - Game.mcw * 0.5;
		var dy = Game.me.ymouse - Game.mch * 0.5;

		charge[0] += dx * c * mt.Timer.tmod;
		charge[1] += dy * c * mt.Timer.tmod;

		var ax = Math.abs(charge[0]);
		var ay = Math.abs(charge[1]);
		var sx = Math.floor(charge[0] / ax);
		var sy = Math.floor(charge[1] / ay);

		if (ax > 0 && Game.me.cell(Game.gx(pos[0] + sx), pos[1]) != Game.EMPTY)
			charge[0] = 0;
		if (ay > 0 && Game.me.cell(pos[0], Game.gy(pos[1] + sy)) != Game.EMPTY)
			charge[1] = 0;

		for (i in 0...charge.length) {
			var ch = charge[i];
			var ach = Math.abs(ch);
			while (ach >= 1) {
				var sens = Math.floor(ch / ach);
				charge[i] -= sens;
				pos[i] = Math.floor(Num.sMod(pos[i] + sens, Game.me.xmax));
				Game.me.paint(pos[0], pos[1]);
				ach--;
			}
		}

		x = Rel.getRelX((pos[0] + charge[0] + 0.5) * Game.me.size);
		y = Rel.getRelY((pos[1] + charge[1] + 0.5) * Game.me.size);
	}
}
