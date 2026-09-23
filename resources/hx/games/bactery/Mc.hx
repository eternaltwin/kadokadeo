package bactery;

import mt.bumdum.Lib;

class Mc extends ASprite {
	public static function setColor(mc:ASprite, col:Int):Void {
		Col.setPercentColor(mc, 100, col);
	}

	public static function modColor(mc:ASprite, coef:Float, inc:Float):Void {
		Col.setPercentColor(mc, (1 - coef) * 100, 0xFFFFFF, inc);
	}

	public static function setPercentColor(mc:ASprite, prc:Float, col:Int):Void {
		Col.setPercentColor(mc, prc, col);
	}
}
