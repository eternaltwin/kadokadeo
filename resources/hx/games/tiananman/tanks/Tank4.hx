package tiananman.tanks;

import mt.bumdum.Lib;
import pixi.core.math.shapes.Rectangle;
import pixi.core.math.Matrix;
import pixi.core.textures.RenderTexture;
import common_haxe_avm1.display.BBox;

class Tank4 extends Bad {
	public static var _preWidth:Float = Cs.s(40);
	public static var _preHeight:Float = Cs.s(20);

	public function new(a:Army) {
		super(4, a);
		centerOffsetX = _preWidth / 2;
		centerOffsetY = _preHeight / 2;

		_p = cast attachMovie("army4", "_p", 0);
		_bBoxMove = attachBBox(new BBox(Cs.s(0), Cs.s(-2), Cs.s(43), Cs.s(23)), 1);
		// var gMove = _bBoxMove.getGraphics()
		// 	.beginFill(0xFF00FF, 0.25)
		// 	.drawRect(Cs.s(-3), Cs.s(-2), Cs.s(52), Cs.s(39))
		// 	.endFill();

		_bBox = attachBBox(new BBox(Cs.s(4), Cs.s(1.5), Cs.s(33.5), Cs.s(15)), 2);
		// var g = _bBox.getGraphics()
		// 	.beginFill(0xFFFF00, 0.25)
		// 	.drawRect(Cs.s(2), Cs.s(2), Cs.s(42), Cs.s(32))
		// 	.endFill();

		_left = attachBBox(new BBox(Cs.s(7), Cs.s(15), Cs.s(28), Cs.s(3)), 0);
		_right = attachBBox(new BBox(Cs.s(7), Cs.s(0), Cs.s(28), Cs.s(3)), 0);

		t = RenderTexture.create(Cs.s(7 + 3), Cs.s(28));
		initBad();
		t_left.gotoAndStop(2);
		t_left.scale.y = 0.6;
		t_right.gotoAndStop(2);
		t_right.scale.y = 0.6;
	}

	public function getWidth():Float {
		return Tank4._preWidth;
	}

	public function getHeight():Float {
		return Tank4._preHeight;
	}
}
