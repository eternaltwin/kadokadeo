package magmax.monsters;

import mt.Timer;
import common_haxe_avm1.display.BBox;
import pixi.filters.colormatrix.ColorMatrixFilter;

class Cyblock extends Monster {
	public var flames:ASprite;

	public function new(g) {
		mc = cast g.dmanager.empty(1);
		var m = mc.attachMovie("monster3", "monster", 0);
		var h = m.attachMovie("heroBlob", "heroBlob", 1);
		h._x = KadoKadeoManager.S(-0.25);
		h._xscale = h._yscale = 70.673523;
		var blobColor = new ColorMatrixFilter();
		blobColor.matrix = [
			1,  0,  0, 0, 0,
			0, -1,  0, 0, 0,
			0,  0, -1, 0, 0,
			0,  0,  0, 1, 0
		];
		h.filters = [blobColor];
		mc.sub = cast m;
		mc.sub.col = mc.sub.attachBBox(new BBox(KadoKadeoManager.S(-9), KadoKadeoManager.S(-15), KadoKadeoManager.S(20), KadoKadeoManager.S(22)));
		h.play();
		h.loop = true;

		// Position effective du sprite 167 dans les 43 frames du sprite 188.
		// Une entrée par frame garde les sauts gotoAndStop synchronisés avec le SWF.
		var blobYByFrame = [
			-26.15, -26.15, -26.15, -26.15, -26.15, -26.15, -26.15, -26.15, -26.15, -26.15, -26.15, -26.15, -26.15, -26.15, -26.15, -24.8, -23.45, -22.1,
			-20.7, -19.35, -18, -16.65, -16.65, -16.65, -16.65, -16.65, -16.65, -16.65, -16.65, -16.65, -16.65, -16.65, -16.65, -16.65, -16.65, -16.65,
			-16.65, -16.65, -18.55, -21.35, -22.15, -22.95, -24.15
		];
		var updateBlob = function() {
			h._y = KadoKadeoManager.S(blobYByFrame[m._currentframe - 1]);
		};
		for (frame in 1...44)
			m.onFrame.set(frame, updateBlob);
		updateBlob();

		super(g, 2);
	}

	override public function init() {
		super.init();

		pv = 10;
		next = genRandPos(false);
		speed = KadoKadeoManager.S(2 + game.level / 100);
		time = 0;
	}

	override public function nextStep() {
		next = genRandPos(false);
	}

	override public function mobTouched() {
		var b = game.dmanager.attach("blam", Cs.PLAN_PART);
		b.play();
		b.removeOnFrame = b._totalframes;
		b._x = x;
		b._y = y;
	}

	override public function mobWait() {
		time += Timer.tmod;
		if (flag) {
			if (time > 30)
				time = 30;
		} else {
			if (time > 43)
				time = 0;
			else if (time < 30)
				time = time % 14;
		}
		mc.sub.gotoAndStop(Std.int(time + 1));
	}

	override public function mobUpdate():Bool {
		if (flag) {
			flag = false;
			fire4();
			wait = 1;
			nextStep();
			return true;
		}

		time += Timer.tmod;
		mc.sub.gotoAndStop(Std.int(time % 14 + 1));

		// move
		var p = Math.pow(0.97, Timer.tmod);
		x = x * p + next.x * (1 - p);
		y = y * p + next.y * (1 - p);

		var ddx = next.x - x;
		var ddy = next.y - y;
		var d = Math.sqrt(ddx * ddx + ddy * ddy);

		if (d < KadoKadeoManager.I(20)) {
			flag = true;
			wait = 2;
			time = time % 14;
		}
		return true;
	}

	function fire4() {
		var s = KadoKadeoManager.S(3);
		game.tirs.push(new Tir(game, 2, x, y, -s, -s));
		game.tirs.push(new Tir(game, 2, x, y, -s, s));
		game.tirs.push(new Tir(game, 2, x, y, s, -s));
		game.tirs.push(new Tir(game, 2, x, y, s, s));
	}
}
