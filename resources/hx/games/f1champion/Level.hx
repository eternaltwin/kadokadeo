package f1champion;

import pixi.core.graphics.Graphics;
import pixi.core.math.Point;

class Level {
	public static var DELTA = KadoKadeoManager.I(300);

	var game:Game;
	var dmanager:DepthManager;
	var scroll:ASprite;
	var bg:ASprite;

	public var middle:ASprite;

	var middle_mask:Graphics;

	public var walls:ASprite;
	public var walls_mask:Graphics;

	var wall_test_point:Point;
	var middle_test_point:Point;

	public var pos:Float;
	public var cur_speed:Float;

	var points_up:Array<{
		x:Float,
		y:Float,
		tx:Float,
		ty:Float
	}>;
	var points_down:Array<{
		x:Float,
		y:Float,
		tx:Float,
		ty:Float
	}>;

	var wallspacing:Float;
	var frequency:{min:Float, max:Float};

	public var speed:Float;

	public function new(g:Game) {
		this.game = g;

		pos = 0;
		speed = Cs.MINSPEED;
		cur_speed = 0;
		wallspacing = KadoKadeoManager.I(110);
		frequency = {min: KadoKadeoManager.I(150), max: KadoKadeoManager.I(200)};

		scroll = game.dmanager.empty(Cs.PLAN_BG);
		dmanager = new DepthManager(scroll);
		bg = dmanager.attach("bg", 0);
		middle = dmanager.attach("tex1", 0);
		middle_mask = dmanager.empty(0).getGraphics();
		middle.mask = middle_mask;
		walls = dmanager.attach("tex2", 0);
		walls_mask = dmanager.empty(0).getGraphics();
		walls.mask = walls_mask;
		wall_test_point = new Point();
		middle_test_point = new Point();

		points_up = new Array();
		points_down = new Array();

		initLevel();
	}

	function initLevel() {
		genLevel();
		drawLevel(middle_mask, false);
		drawLevel(walls_mask, true);
	}

	function genLevel() {
		var n = 0;
		for (i in 0...points_up.length) {
			var p = points_up[i];
			if (p.y > DELTA)
				n = i;
			p.y += DELTA;
		}
		points_up.splice(0, n);

		var pstart = points_up.length;
		n = 0;
		for (i in 0...points_down.length) {
			var p = points_down[i];
			if (p.y > DELTA)
				n = i;
			p.y += DELTA;
		}
		points_down.splice(0, n);

		var fmin = frequency.min;
		var fampl = Std.int(frequency.max - frequency.min);
		var ampl = KadoKadeoManager.I(40);

		var y = KadoKadeoManager.I(650) + fmin;

		if (points_up.length > 0 && points_up[points_up.length - 1].y < y)
			y = points_up[points_up.length - 1].y;
		if (points_down.length > 0 && points_down[points_down.length - 1].y < y)
			y = points_down[points_down.length - 1].y;

		y -= fmin;

		var space = KadoKadeoManager.I(150) - wallspacing;
		var delta:Float = 0;

		if (Seed.random(3) == 0)
			delta = wallspacing - KadoKadeoManager.I(140);

		if (Seed.random(5) == 0) {
			ampl = KadoKadeoManager.I(Std.int(Math.min(100 * cur_speed / Cs.MINSPEED, 150)));
			space = KadoKadeoManager.I(40);
			delta = 0;
		}

		while (true) {
			var dy = fmin + Seed.random(fampl);
			var p = {
				x: delta + space + Seed.random(ampl),
				y: y,
				tx: 0.,
				ty: -dy / (3 + Seed.random(30) / 20)
			};
			points_up.push(p);
			if (y < 0)
				break;
			y -= dy;
		}

		for (i in pstart...points_up.length) {
			var p = points_up[i];
			var p2 = {
				x: p.x + (Cs.WIDTH - space * 2 - ampl),
				y: p.y,
				tx: p.tx,
				ty: p.ty
			};
			points_down.push(p2);
		}
	}

	function point(mc:ASprite, x:Float, y:Float, color:Int) {
		mc.moveTo(x, y);
		mc.lineStyle(KadoKadeoManager.I(5), color, 1);
		mc.lineTo(x + KadoKadeoManager.S(0.5), y + KadoKadeoManager.S(0.5));
	}

	function curve(mc:Graphics, p1:{
		x:Float,
		y:Float,
		tx:Float,
		ty:Float
	}, p2:{
		x:Float,
		y:Float,
		tx:Float,
		ty:Float
	}) {
		var c1x = p1.x + p1.tx;
		var c1y = p1.y + p1.ty;
		var c2x = p2.x - p2.tx;
		var c2y = p2.y - p2.ty;

		var cx = (p2.x + p1.x) / 2;
		var cy = (p2.y + p1.y) / 2;

		mc.quadraticCurveTo(c1x, c1y, cx, cy);
		mc.quadraticCurveTo(c2x, c2y, p2.x, p2.y);
	}

	function drawLevel(mc:Graphics, a:Bool) {
		mc.clear();
		mc.beginFill(0, 0.5);
		mc.moveTo(0, points_up[0].y);
		mc.lineTo(points_up[0].x, points_up[0].y);

		var i = 1;
		if (a) {
			while (i < points_up.length) {
				var p1 = points_up[i - 1];
				var p2 = points_up[i];
				p1 = {
					x: p1.x - KadoKadeoManager.I(4),
					y: p1.y,
					tx: p1.tx,
					ty: p1.ty
				};
				p2 = {
					x: p2.x - KadoKadeoManager.I(4),
					y: p2.y,
					tx: p2.tx,
					ty: p2.ty
				};
				curve(mc, p1, p2);
				i++;
			}
		} else {
			while (i < points_up.length) {
				curve(mc, points_up[i - 1], points_up[i]);
				i++;
			}
		}
		mc.lineTo(0, points_up[i - 1].y);
		mc.lineTo(0, points_up[0].y);
		mc.endFill();

		mc.beginFill(0, 0.5);
		mc.moveTo(Cs.WIDTH, points_down[0].y);
		mc.lineTo(points_down[0].x, points_down[0].y);

		i = 1;
		if (a) {
			while (i < points_down.length) {
				var p1 = points_down[i - 1];
				var p2 = points_down[i];
				p1 = {
					x: p1.x + KadoKadeoManager.I(4),
					y: p1.y,
					tx: p1.tx,
					ty: p1.ty
				};
				p2 = {
					x: p2.x + KadoKadeoManager.I(4),
					y: p2.y,
					tx: p2.tx,
					ty: p2.ty
				};
				curve(mc, p1, p2);
				i++;
			}
		} else {
			while (i < points_down.length) {
				curve(mc, points_down[i - 1], points_down[i]);
				i++;
			}
		}
		mc.lineTo(Cs.WIDTH, points_down[i - 1].y);
		mc.lineTo(Cs.WIDTH, points_down[0].y);
		mc.endFill();
	}

	public inline function wallContains(x:Float, y:Float):Bool {
		wall_test_point.x = x;
		wall_test_point.y = y + (scroll.position.y - scroll._y);
		return walls_mask.containsPoint(wall_test_point);
	}

	public inline function middleContains(x:Float, y:Float):Bool {
		middle_test_point.x = x;
		middle_test_point.y = y + (scroll.position.y - scroll._y);
		return middle_mask.containsPoint(middle_test_point);
	}

	public function main():Float {
		if (Timer.tmod > 10)
			Timer.tmod = 10;

		if (wallspacing > KadoKadeoManager.I(50))
			wallspacing -= KadoKadeoManager.S(0.01 * Timer.tmod);

		speed += KadoKadeoManager.S(0.002 * Timer.tmod);
		var ps = Math.pow(0.96, Timer.tmod);
		cur_speed = cur_speed * ps + (1 - ps) * speed;
		if (cur_speed > KadoKadeoManager.I(22))
			cur_speed = KadoKadeoManager.I(22);
		var dp = cur_speed * Timer.tmod;
		pos += dp;
		if (pos > DELTA) {
			game.chkdata.n++;
			game.km_without_out_of_bounds += 1;
			pos -= DELTA;
			scroll._prevState.y = pos - DELTA - dp;
			initLevel();
		}
		scroll._y = pos - DELTA;
		return dp;
	}
}
