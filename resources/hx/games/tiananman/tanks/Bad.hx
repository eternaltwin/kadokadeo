package tiananman.tanks;

import mt.bumdum.Lib;
import pixi.core.math.shapes.Rectangle;
import pixi.core.math.Matrix;
import pixi.core.textures.RenderTexture;
import common_haxe_avm1.display.BBox;

class PotentiallyArmedTank extends ASprite {
	public var _weapon:ASprite;
}

class TraceSprite extends ASprite {}

abstract class Bad extends ASprite {
	static var DELTA_TRACE = Cs.s(5.0);
	static var BLOOD_TIMER = 100;

	public static var _preWidth:Float;
	public static var _preHeight:Float;

	public var _left:BBox;
	public var _right:BBox;

	var t:RenderTexture;
	var tr:ASprite;
	var t_left:ASprite;
	var t_right:ASprite;
	var matrix:Matrix;

	public var centerOffsetX:Float;
	public var centerOffsetY:Float;

	public var _p:PotentiallyArmedTank;
	public var _bBoxMove:BBox;
	public var _bBox:BBox;
	public var level:Int;
	public var army:Army;

	public var lastTrace:Array<Float>;
	public var blood:{leftTimer:Float, rightTimer:Float}; // 0 : all, 1 : left, 2 : right

	public function new(level:Int, army:Army) {
		super();
		this.level = level;
		this.army = army;
		blood = {leftTimer: null, rightTimer: null};
	}

	public function initBad() {
		tr = new ASprite();
		// tr.getGraphics()
		// 	.beginFill(0xFFFFFF, 1)
		// 	.drawRect(0, 0, Cs.s(4), Cs.s(35))
		// 	.endFill();
		t_right = tr.attachMovie("tTrace");
		t_right.gotoAndStop(level);
		t_right.position.x = _right.bboxX;
		t_right.position.y = _right.bboxY;
		// t_right.getGraphics()
		// 	.beginFill(0xFF0000, 0.8)
		// 	.drawRect(0, 0, Cs.s(4), Cs.s(5.3))
		// 	.endFill();
		t_left = tr.attachMovie("tTrace");
		t_left.gotoAndStop(level);
		t_left.position.x = _left.bboxX;
		t_left.position.y = _left.bboxY + _left.bboxHeight;
		t_left.scale.y = -1;
		// t_left.getGraphics()
		// 	.beginFill(0x00FF00, 0.8)
		// 	.drawRect(0, 0, Cs.s(4), Cs.s(5.3)) // .drawRect(0, Cs.s(35 - 5.3), Cs.s(4), Cs.s(5.3))
		// 	.endFill();
		matrix = new Matrix();
	}

	public function travelDone(?delta:Float = 0.0):Bool {
		delta = Cs.s(delta);
		switch (army.typeDir) {
			case 0: // from north
				return army.y - getHeight() > Cs.mch[1] + Cs.HIDE_END - delta;
			case 1: // from east
				return army.x + getWidth() < Cs.mcw[0] - Cs.HIDE_END + delta;
			case 2: // from south
				return army.y + getHeight() < Cs.mch[0] - Cs.HIDE_END + delta;
			case 3: // from west
				return army.x - getWidth() > Cs.mcw[1] + Cs.HIDE_END - delta;
			case _:
				return true;
		}
		return false;
	}

	abstract public function getWidth():Float;

	abstract public function getHeight():Float;

	public function getTraces(leftBlood:Bool, rightBlood:Bool):RenderTexture {
		t.clearRect(new Rectangle(0, 0, t.width, t.height));
		if (leftBlood) {
			Col.setPercentColor(t_left, 95, 0xBA0202);
		} else {
			t_left.filters = [];
		}
		if (rightBlood) {
			Col.setPercentColor(t_right, 95, 0xBA0202);
		} else {
			t_right.filters = [];
		}

		t.draw(tr, matrix);
		return t;
	}

	public function makeTraces() {
		if (lastTrace == null || Math.abs(army.x - lastTrace[0]) >= DELTA_TRACE || Math.abs(army.y - lastTrace[1]) >= DELTA_TRACE) {
			lastTrace = [army.x, army.y];

			var t = Game.me.mdm.empty(Game.DP_GROUND);
			// var t_left = t.attachMovie("tTrace");
			// var t_right = t.attachMovie("tTrace");
			// t_left.gotoAndStop(level + 1);
			// t_right.gotoAndStop(level + 1);
			// t_left._xscale = -100;

			var c = getCenter();

			var pc = 0.80;
			switch (army.typeDir) {
				case 0:
					t._rotation = -90;
				case 1:
				case 2:
					t._rotation = 90;
				case 3:
					t._rotation = -180;
			}

			t._x = army.x;
			t._y = army.y;
			// t._x = c.x;
			// t._y = c.y;

			if (blood.leftTimer == null || blood.rightTimer == null) {
				for (b in Game.BloodList) {
					if (b == null || b.root == null || b.timer <= 0.0) {
						Game.BloodList.remove(b);
						continue;
					}

					if (blood.leftTimer == null && b.root._alpha > 50 && b._bBox.hitTestBbox(_left))
						blood.leftTimer = BLOOD_TIMER;
					if (blood.rightTimer == null && b.root._alpha > 50 && b._bBox.hitTestBbox(_right))
						blood.rightTimer = BLOOD_TIMER;
				}
			}

			var leftCt = null;
			var rightCt = null;
			t.attachBitmap(getTraces(blood.leftTimer != null, blood.rightTimer != null));

			if (blood.leftTimer != null) {
				leftCt = Cs.bloodCt;
				blood.leftTimer = Math.max(0, blood.leftTimer - 1.0 * mt.Timer.tmod);
				//	trace("timer : " + blood.leftTimer) ;
				if (blood.leftTimer == 0)
					blood.leftTimer = null;
			}
			if (blood.rightTimer != null) {
				rightCt = Cs.bloodCt;
				blood.rightTimer = Math.max(0, blood.rightTimer - 1.0 * mt.Timer.tmod);
				if (blood.rightTimer == 0)
					blood.rightTimer = null;
			}

			// Game.me.plasma.drawMc(t_left, c.x + Cs.s(-16), c.y + Cs.s(0), rightCt);
			// Game.me.plasma.drawMc(t_right, c.x + Cs.s(14), c.y + Cs.s(0), leftCt);
			Game.me.plasma.drawMc(t);
			t.removeMovieClip();
		}
	}

	public function getCenter():{x:Float, y:Float} {
		var cx = centerOffsetX;
		var cy = centerOffsetY;
		switch (army.typeDir) {
			case 0:
				return {x: army.x + cy, y: army.y - cx};
			case 1:
				return {x: army.x + cx, y: army.y + cy};
			case 2:
				return {x: army.x - cy, y: army.y + cx};
			case 3:
				return {x: army.x - cx, y: army.y - cy};
			case _:
				trace("bad dir for getCenter");
				return null;
		}
		return null;
	}

	public function kill() {
		tr.removeMovieClip();
		t.destroy();
		removeMovieClip();
	}
}
