package tiananman.tanks;

import mt.bumdum.Lib;
import pixi.core.math.shapes.Rectangle;
import pixi.core.math.Matrix;
import pixi.core.textures.RenderTexture;
import common_haxe_avm1.display.BBox;

class Tank2 extends Bad {
	public static var _preWidth:Float = Cs.s(48);
	public static var _preHeight:Float = Cs.s(32);

	public function new(a:Army) {
		super(2, a);
		centerOffsetX = _preWidth / 2;
		centerOffsetY = _preHeight / 2;

		_p = cast attachMovie("army2", "_p", 0);
		_bBoxMove = attachBBox(new BBox(Cs.s(0), Cs.s(-1), Cs.s(35), Cs.s(33)), 1);
		// var gMove = _bBoxMove.getGraphics()
		// 	.beginFill(0xFF00FF, 0.25)
		// 	.drawRect(Cs.s(-3), Cs.s(-2), Cs.s(52), Cs.s(39))
		// 	.endFill();

		_bBox = attachBBox(new BBox(Cs.s(3), Cs.s(3), Cs.s(28), Cs.s(25)), 2);
		// var g = _bBox.getGraphics()
		// 	.beginFill(0xFFFF00, 0.25)
		// 	.drawRect(Cs.s(2), Cs.s(2), Cs.s(42), Cs.s(32))
		// 	.endFill();

		_left = attachBBox(new BBox(Cs.s(3), Cs.s(22), Cs.s(27), Cs.s(4)), 0);
		_right = attachBBox(new BBox(Cs.s(3), Cs.s(0), Cs.s(27), Cs.s(4)), 0);

		t = RenderTexture.create(Cs.s(3 + 3), Cs.s(27));
		initBad();
	}

	public function getWidth():Float {
		return Tank2._preWidth;
	}

	public function getHeight():Float {
		return Tank2._preHeight;
	}
}
