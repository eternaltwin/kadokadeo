package opalusfactory;

// AnimFunc.hx of the original (easing functions). bounce and quint move the lines of the roll, whose scale decides when
// the coins and the hero fall (Game.coinFalls): their results are rounded (Cs.q), Math.pow can differ in the last bits
// between browsers
class AnimFunc {
	public static function bounce(p:Float):Float {
		var value:Float = Math.NaN;
		var a = 0.0;
		var b = 1.0;
		while (true) {
			if (p >= (7 - 4 * a) / 11) {
				value = -Math.pow((11 - 6 * a - 11 * p) / 4, 2) + b * b;
				break;
			}
			a += b;
			b /= 2;
		}
		return Cs.q(value);
	}

	public static function elastic(pa:Float = 1.0, p:Float):Float {
		return Math.pow(2, 10 * --p) * Math.cos(20 * p * Math.PI * pa / 3);
	}

	public static function quint(p:Float):Float {
		return Cs.q(Math.pow(p, 5));
	}
}
