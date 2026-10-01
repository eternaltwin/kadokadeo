package xianxiang;

class CardID {
	public var color:Int;
	public var symbol:Int;
	public var socle:Int;

	public static function random():CardID {
		var so = Seed.random(3);
		var c = Seed.random(4);
		var sy = Seed.random(5);
		return new CardID(so, c, sy);
	}

	function new(so, c, sy) {
		this.color = c;
		this.symbol = sy;
		this.socle = so;
	}

	public function matchs(id:CardID) {
		return ((id.color == color) ? 1 : 0) + ((id.symbol == symbol) ? 1 : 0) + ((id.socle == socle) ? 1 : 0);
	}

	function toString() {
		return socle + "-" + color + "-" + symbol;
	}
}
