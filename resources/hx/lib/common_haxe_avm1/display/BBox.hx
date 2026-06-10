package common_haxe_avm1.display;

import mt.bumdum.Phys;
import mt.bumdum.Lib;
import pixi.core.math.Point;

class BBox extends ASprite {
	public var bboxX:Float;
	public var bboxY:Float;
	public var bboxWidth:Float;
	public var bboxHeight:Float;

	public function new(x:Float, y:Float, width:Float, height:Float) {
		super();
		this.bboxX = x;
		this.bboxY = y;
		this.bboxWidth = width;
		this.bboxHeight = height;
		// get random color for debug
		// var color = Std.int(Std.random(0xFFFFFF));
		// getGraphics().beginFill(color, 0.5).drawRect(bboxX, bboxY, bboxWidth, bboxHeight).endFill();
	}

	public override function hitTest(x:Float, y:Float, shapeFlag:Bool = false):Bool {
		var p = toLocal(new Point(x, y));
		var px = Num.q(p.x);
		var py = Num.q(p.y);
		return (px >= Num.q(bboxX) && py >= Num.q(bboxY) && px <= Num.q(bboxX + bboxWidth) && py <= Num.q(bboxY + bboxHeight));
	}

	public function hitTestObject(obj:ASprite):Bool {
		var p = obj.toGlobal(new Point(0, 0));
		return hitTest(p.x, p.y);
	}

	public function hitTestBbox(obj:BBox):Bool {
		var a = getGlobalCorners();
		var b = obj.getGlobalCorners();
		return polygonsIntersect(a, b);
	}

	public function hitTestPolygon(obj:Array<Point>):Bool {
		var a = getGlobalCorners();
		var b = obj;
		return polygonsIntersect(a, b);
	}

	public function getGlobalCorners():Array<Point> {
		return [
			quantPoint(toGlobal(new Point(bboxX, bboxY))),
			quantPoint(toGlobal(new Point(bboxX + bboxWidth, bboxY))),
			quantPoint(toGlobal(new Point(bboxX + bboxWidth, bboxY + bboxHeight))),
			quantPoint(toGlobal(new Point(bboxX, bboxY + bboxHeight))),
		];
	}

	inline function quantPoint(p:Point):Point {
		p.x = Num.q(p.x);
		p.y = Num.q(p.y);
		return p;
	}

	static public function polygonsIntersect(a:Array<Point>, b:Array<Point>):Bool {
		if (a == null || b == null || a.length < 3 || b.length < 3)
			return false;

		return !hasSeparatingAxis(a, b) && !hasSeparatingAxis(b, a);
	}

	static function hasSeparatingAxis(a:Array<Point>, b:Array<Point>):Bool {
		for (i in 0...a.length) {
			var p1 = a[i];
			var p2 = a[(i + 1) % a.length];
			var axisX = Num.q(-(p2.y - p1.y));
			var axisY = Num.q(p2.x - p1.x);
			if (axisX == 0 && axisY == 0)
				continue;
			var pa = project(a, axisX, axisY);
			var pb = project(b, axisX, axisY);

			if (pa.max < pb.min || pb.max < pa.min)
				return true;
		}

		return false;
	}

	static function project(points:Array<Point>, axisX:Float, axisY:Float):{min:Float, max:Float} {
		var first = Num.q(points[0].x * axisX + points[0].y * axisY);
		var min = first;
		var max = first;

		for (i in 1...points.length) {
			var v = Num.q(points[i].x * axisX + points[i].y * axisY);
			if (v < min)
				min = v;
			if (v > max)
				max = v;
		}

		return {min: min, max: max};
	}

	public function toString():String {
		return "BBox(" + bboxX + ", " + bboxY + ", " + bboxWidth + ", " + bboxHeight + ")";
	}
}
