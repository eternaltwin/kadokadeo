package tiananman.tanks;

import mt.bumdum.Lib;
import pixi.core.math.shapes.Rectangle;
import pixi.core.math.Matrix;
import pixi.core.textures.RenderTexture;
import common_haxe_avm1.display.BBox;

class Tank3 extends Bad {
	public static var _preWidth:Float = Cs.s(43);
	public static var _preHeight:Float = Cs.s(35);

	public function new(a:Army) {
		super(3, a);
		centerOffsetX = _preWidth / 2;
		centerOffsetY = _preHeight / 2;

		_p = cast attachMovie("army3", "_p", 0);
		_p._weapon = _p.attachMovie("army3Weapon", "_weapon", 1);
		_p._weapon._x = Cs.s(19);
		_p._weapon._y = Cs.s(18);
		_bBoxMove = attachBBox(new BBox(Cs.s(2), Cs.s(0), Cs.s(35), Cs.s(37)), 1);
		// var gMove = _bBoxMove.getGraphics()
		// 	.beginFill(0xFF00FF, 0.25)
		// 	.drawRect(Cs.s(-3), Cs.s(-2), Cs.s(52), Cs.s(39))
		// 	.endFill();

		_bBox = attachBBox(new BBox(Cs.s(6.5), Cs.s(3), Cs.s(26), Cs.s(30)), 2);
		// var g = _bBox.getGraphics()
		// 	.beginFill(0xFFFF00, 0.25)
		// 	.drawRect(Cs.s(2), Cs.s(2), Cs.s(42), Cs.s(32))
		// 	.endFill();

		_left = attachBBox(new BBox(Cs.s(4.5), Cs.s(30), Cs.s(28), Cs.s(5)), 0);
		_right = attachBBox(new BBox(Cs.s(4.5), Cs.s(3), Cs.s(28), Cs.s(5)), 0);

		t = RenderTexture.create(Cs.s(4.5 + 6.3), Cs.s(35));
		initBad();
	}

	public function getWidth():Float {
		return Tank3._preWidth;
	}

	public function getHeight():Float {
		return Tank3._preHeight;
	}
}
