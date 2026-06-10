package tiananman;

import common_haxe_avm1.display.BBox;
import mt.bumdum.Lib;
import common_haxe_avm1.MouseManager;

class ClickMe {
	public var root:ASprite;
	public var _bBox:BBox;

	public function new(mc:ASprite) {
		root = mc;
		root.loop = true;
		root.play();
		_bBox = root.attachBBox(new BBox(Cs.s(-10), Cs.s(-10), Cs.s(20), Cs.s(20)));
		_bBox.interactive = true;
		untyped _bBox.cursor = "pointer";
	}

	public function isClicked():Bool {
		if (MouseManager.isButtonJustPressed(MouseManager.BUTTON_LEFT)) {
			var mx = Num.q(MouseManager.getX());
			var my = Num.q(MouseManager.getY());
			var p = _bBox.toGlobal(new pixi.core.math.Point(0, 0));
			var d = Cs.s(10);
			if (mx >= p.x - d && mx <= p.x + d && my >= p.y - d && my <= p.y + d) {
				return true;
			}
		}
		return false;
	}
}
