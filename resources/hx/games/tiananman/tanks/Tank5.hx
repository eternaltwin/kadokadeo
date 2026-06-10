package tiananman.tanks;

import mt.bumdum.Lib;
import pixi.core.math.shapes.Rectangle;
import pixi.core.math.Matrix;
import pixi.core.textures.RenderTexture;
import common_haxe_avm1.display.BBox;

class Tank5 extends Bad {
	public static var _preWidth:Float = Cs.s(52);
	public static var _preHeight:Float = Cs.s(52);

	public function new(a:Army) {
		super(5, a);
		centerOffsetX = _preWidth / 2;
		centerOffsetY = _preHeight / 2;

		_p = cast attachMovie("army5", "_p", 0);
		_bBoxMove = attachBBox(new BBox(Cs.s(1), Cs.s(0), Cs.s(50), Cs.s(53)), 1);
		// var gMove = _bBoxMove.getGraphics()
		// 	.beginFill(0xFF00FF, 0.25)
		// 	.drawRect(Cs.s(-3), Cs.s(-2), Cs.s(52), Cs.s(39))
		// 	.endFill();

		_bBox = attachBBox(new BBox(Cs.s(4.5), Cs.s(7), Cs.s(39.5), Cs.s(39)), 2);
		// var g = _bBox.getGraphics()
		// 	.beginFill(0xFFFF00, 0.25)
		// 	.drawRect(Cs.s(2), Cs.s(2), Cs.s(42), Cs.s(32))
		// 	.endFill();

		_left = attachBBox(new BBox(Cs.s(15), Cs.s(32), Cs.s(33.5), Cs.s(10)), 0);
		_right = attachBBox(new BBox(Cs.s(15), Cs.s(6), Cs.s(33.5), Cs.s(10)), 0);

		t = RenderTexture.create(Cs.s(15 + 10), Cs.s(42));
		initBad();
		t_left.gotoAndStop(4);
		t_right.gotoAndStop(4);
	}

	public function getWidth():Float {
		return Tank5._preWidth;
	}

	public function getHeight():Float {
		return Tank5._preHeight;
	}
}
