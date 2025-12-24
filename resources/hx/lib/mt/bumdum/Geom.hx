package mt.bumdum;

import pixi.core.display.Container;
import mt.bumdum.Lib.Point;

class Geom {
	static public function getDist(o1:Point, o2:Point) {
		var dx = o1.x - o2.x;
		var dy = o1.y - o2.y;
		return Math.sqrt(dx * dx + dy * dy);
	}

	static public function getAng(o1:Point, o2:Point) {
		var dx = o1.x - o2.x;
		var dy = o1.y - o2.y;
		return Math.atan2(dy, dx);
	}

	static public function getParentCoord(mc:Container, parent:Container) {
		var par = null;
		var to = 0;
		var x:Float = mc.x;
		var y:Float = mc.y;
		while (true) {
			par = mc.parent;
			if (par.rotation != 0) {
				var dist = Math.sqrt(x * x + y * y);
				var a = Math.atan2(y, x);
				a += par.rotation * 0.0174;
				x = Math.cos(a) * dist;
				y = Math.sin(a) * dist;
			}

			x *= par.scale.x * 0.01;
			y *= par.scale.y * 0.01;

			x += par.x;
			y += par.y;

			if (par == parent || par == null) {
				return {x: x, y: y};
			}
			mc = par;
			if (to++ > 20) {
				trace("GET PARENT COORD ERROR");
				break;
			}
		}
		return null;
	}
}
