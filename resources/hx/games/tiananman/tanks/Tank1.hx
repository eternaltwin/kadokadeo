package tiananman.tanks;

import mt.bumdum.Lib;
import pixi.core.math.shapes.Rectangle;
import pixi.core.math.Matrix;
import pixi.core.textures.RenderTexture;
import common_haxe_avm1.display.BBox;

class Tank1 extends Bad {
	public static var _preWidth:Float = Cs.s(47);
	public static var _preHeight:Float = Cs.s(36);

	public function new(a:Army) {
		super(1, a);
		centerOffsetX = _preWidth / 2;
		centerOffsetY = _preHeight / 2;

		_p = cast attachMovie("army1", "_p", 0);
		_bBoxMove = attachBBox(new BBox(Cs.s(-3), Cs.s(-2), Cs.s(52), Cs.s(39)), 1);
		// var gMove = _bBoxMove.getGraphics()
		// 	.beginFill(0xFF00FF, 0.25)
		// 	.drawRect(Cs.s(-3), Cs.s(-2), Cs.s(52), Cs.s(39))
		// 	.endFill();

		_bBox = attachBBox(new BBox(Cs.s(2), Cs.s(2), Cs.s(42), Cs.s(32)), 2);
		// var g = _bBox.getGraphics()
		// 	.beginFill(0xFFFF00, 0.25)
		// 	.drawRect(Cs.s(2), Cs.s(2), Cs.s(42), Cs.s(32))
		// 	.endFill();

		_left = attachBBox(new BBox(Cs.s(2), Cs.s(29), Cs.s(42), Cs.s(6)), 0);
		_right = attachBBox(new BBox(Cs.s(2), Cs.s(0), Cs.s(42), Cs.s(6)), 0);

		t = RenderTexture.create(Cs.s(2 + 4), Cs.s(35));
		initBad();
	}

	public function getWidth():Float {
		return Tank1._preWidth;
	}

	public function getHeight():Float {
		return Tank1._preHeight;
	}
}
