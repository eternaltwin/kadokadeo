package klinkersurprise;

// a Phys on the wrapping map (a torus of ZW x ZH pixels): its position is kept in the map, its clip is drawn at the
// copy nearest to its relPoint (the selector, at the centre of the screen)
class Rel extends Phys {
	public static var ZW:Float;
	public static var ZH:Float;

	public var relType:Int;
	public var flNoRel:Bool = false;
	public var relPoint:Sprite;

	public function new(mc:MC) {
		super(mc);
		// (the clip jumps by a period when the nearest copy changes: see MC.wrap)
		mc.wrap = ZW;
	}

	override public function update():Void {
		if (flNoRel) {
			super.update();
			return;
		}

		x = getRelX(x);
		y = getRelY(y);

		super.update();

		if (relPoint != null) {
			var dx = Num.hMod(relPoint.x - x, ZW * 0.5);
			var dy = Num.hMod(relPoint.y - y, ZH * 0.5);
			root._x = relPoint.x - dx;
			root._y = relPoint.y - dy;
		}
	}

	// TOOLS
	public function getDist(o:{x:Float, y:Float}):Float {
		var dx = Num.hMod(o.x - x, ZW * 0.5);
		var dy = Num.hMod(o.y - y, ZH * 0.5);
		return Math.sqrt(dx * dx + dy * dy);
	}

	public function getAng(o:{x:Float, y:Float}):Float {
		var dx = Num.hMod(o.x - x, ZW * 0.5);
		var dy = Num.hMod(o.y - y, ZH * 0.5);
		return Math.atan2(dy, dx);
	}

	public function toward(o:{x:Float, y:Float}, c:Float, ?lim:Float):Void {
		if (lim == null)
			lim = Math.POSITIVE_INFINITY;
		var dx = Num.hMod(o.x - x, ZW * 0.5);
		var dy = Num.hMod(o.y - y, ZH * 0.5);
		x += Num.mm(-lim, dx * c, lim);
		y += Num.mm(-lim, dy * c, lim);
	}

	public static function getRelX(x:Float):Float {
		return Num.sMod(x, ZW);
	}

	public static function getRelY(y:Float):Float {
		return Num.sMod(y, ZH);
	}
}
