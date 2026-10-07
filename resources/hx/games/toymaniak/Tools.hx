package toymaniak;

// the function of mt Tools the game uses (as the released SWF compiled it)
class Tools {
	// an index drawn with the weights of probas
	public static function randomProbas(probas:Array<Int>):Int {
		var n = 0;
		var i = probas.length - 1;
		while (i >= 0) {
			n += probas[i];
			i--;
		}
		n = Seed.random(n);
		i = 0;
		while (n >= probas[i]) {
			n -= probas[i];
			i++;
		}
		return i;
	}
}
