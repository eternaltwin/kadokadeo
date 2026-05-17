package common_haxe_avm1;

using Lambda;

abstract KKConst(Int) from Int to Int {}

class KKApi {
	static public var score:Int = 0;
	static public var scoreDiv:js.html.DivElement;

	public static function setScore(s:Int):Void {
		score = s;
		updateScore();
	}

	public static function flagCheater() {}

	public static function registerButton(d:Dynamic) {}

	public static function gameOver(d:Dynamic) {
		// js.Browser.document.getElementById("gameOver").style.display = "block";
	}

	public static function cadd(s:KKConst, a:KKConst):KKConst {
		return (s : Int) + (a : Int);
	}

	public static function cmult(s:KKConst, a:KKConst):KKConst {
		return (s : Int) * (a : Int);
	}

	public static function addScore(s:Int):Int {
		score += s;
		updateScore();
		return score;
	}

	public static function val(n:KKConst):Int {
		return n;
	}

	public static function aconst(n:Array<Int>):Array<KKConst> {
		return n.map((v) -> v);
	}

	public static function const(n:Int):KKConst {
		return n;
	}

	static public function getScore() {
		return 0;
	}

	static function updateScore() {}

	public static function processing(v:Bool) {}
}
