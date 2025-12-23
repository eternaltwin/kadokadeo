package common_haxe_avm1.pixi;

import pixi.core.graphics.Graphics;

class GraphicsTools {
	static public function drawWedge(target:Graphics, x:Int, y:Int, radius:Int, arc:Float, startAngle:Float = 0, yRadius:Float = 0) {
		var segs = Math.ceil(Math.abs(arc) / 45);
		var segAngle = arc / segs;
		var theta = -(segAngle / 180) * Math.PI;
		var angle = -(startAngle / 180) * Math.PI;
		var ax = x + Math.cos(startAngle / 180 * Math.PI) * radius;
		var ay = y + Math.sin(-startAngle / 180 * Math.PI) * yRadius;
		var angleMid, bx, by, cx, cy;
		if (yRadius == 0)
			yRadius = radius;
		target.moveTo(x, y);
		target.lineTo(ax, ay);
		for (i in 0...segs) {
			angle += theta;
			angleMid = angle - (theta / 2);
			bx = x + Math.cos(angle) * radius;
			by = y + Math.sin(angle) * yRadius;
			cx = x + Math.cos(angleMid) * (radius / Math.cos(theta / 2));
			cy = y + Math.sin(angleMid) * (yRadius / Math.cos(theta / 2));
			target.quadraticCurveTo(cx, cy, bx, by);
		}
		target.lineTo(x, y);
	}
}
