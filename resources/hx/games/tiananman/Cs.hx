package tiananman;

import pixi.filters.colormatrix.ColorMatrixFilter;
import common_haxe_avm1.KKApi;
import mt.bumdum.Lib;

class Cs {
	// GAME SIZE
	public static var mcw = [0.0, KadoKadeoManager.S(300)];
	public static var mch = [KadoKadeoManager.S(20), KadoKadeoManager.S(300)];

	public static var LEADER_LIFE = 1;
	public static var FOLLOWERS_LIFE = 15;

	public static var FPS = 44;

	public static var repopArmyDelay = 15.0;
	public static var repopFollowDelay = 50.0;

	public static var HIDE_START = KadoKadeoManager.I(30);
	public static var HIDE_END = KadoKadeoManager.I(5);
	public static var MIN_DELTA_QUEUE = KadoKadeoManager.I(5);

	public static var ARMY_MAX = 6;
	public static var GRAB_MAX = 2;

	public static var DELTA_FOLLOW = KadoKadeoManager.S(12.0);
	public static var MAX_LEADERTRACE = 50;

	public static var FOLLOW_POINTS = KKApi.const(800);
	public static var MIN_POINTS = KKApi.const(50);

	public static var TRACE_TIMER = 200;
	public static var TRACE_FADE = 50;

	public static var GRAB_SHIELD = 20;

	public static var FEVER_LOSE_PER_KILL = 3;
	public static var bloodCt = new ColorMatrixFilter();

	public static function outOfBounds(x:Float, y:Float, ?d:Float = 0.0):Bool {
		d = KadoKadeoManager.S(d);
		var qx = Num.q(x);
		var qy = Num.q(y);
		return qx < mcw[0] + d || qx > mcw[1] - d || qy < mch[0] + d || qy > mch[1] - d;
	}

	public static function getDist(x:Float, y:Float, lastX:Float, lastY:Float):Float {
		var dx = Num.q(x - lastX);
		var dy = Num.q(y - lastY);
		return Num.q(Math.sqrt(dx * dx + dy * dy));
	}

	public static function rotateMc(mc:ASprite, x:Float, y:Float, lx:Float, ly:Float, ?mr = 0.0):Float {
		var qx = Num.q(x);
		var qy = Num.q(y);
		var qlx = Num.q(lx);
		var qly = Num.q(ly);
		var dist = Cs.getDist(qx, qy, qlx, qly);
		if (dist <= 0) {
			mc._rotation = Num.q(mr);
			return mc._rotation;
		}
		var ratio = Num.q(Math.abs(qx - qlx) / dist);
		ratio = Math.max(-1, Math.min(1, ratio));
		var a = Math.acos(ratio);
		var dg = Num.q(180 * a / 3.14);
		var p = 0;
		if (qx <= qlx && qy <= qly)
			dg = 0 + dg;
		else if (qx > qlx && qy <= qly)
			dg = 90 + (90 - dg);
		else if (qx > qlx && qy > qly)
			dg = 180 + dg;
		else if (qx <= qlx && qy > qly)
			dg = 270 + (90 - dg);
		mc._rotation = Num.q(dg + mr);
		return mc._rotation;
	}

	static public function randomProbs(t:Array<Int>):Int {
		var n = 0;
		for (i in t)
			n += i;
		n = Seed.random(n);
		var i = 0;
		while (n >= t[i]) {
			n -= t[i];
			i++;
		}
		return i;
	}

	static public function elastic(pa:Float = 1.0, p:Float):Float {
		return Math.pow(2, 10 * --p) * Math.cos(20 * p * Math.PI * pa / 3);
	}

	static public function s(v:Float):Float {
		return KadoKadeoManager.S(v);
	}
}
