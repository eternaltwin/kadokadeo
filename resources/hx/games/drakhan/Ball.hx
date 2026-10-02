package drakhan;

import common_haxe_avm1.KKApi;
import mt.Timer;
import mt.bumdum.Phys;

class PartSparkSprite extends ASprite {
	public var sub:ASprite;
}

class Ball extends Phys {
	static var TENSE_LIMIT = 0.2;
	static var TENSE_POWER = 0.1;
	static var RECAL_SPEED = 0.4;

	public var flFly:Bool;
	public var flIce:Bool;

	public var px:Int;
	public var py:Int;
	public var gid:Int;

	var link:Array<Ball>;

	public var wg:Float;
	public var ray:Float;
	public var deathTimer:Float;

	public var color:Int;

	var trg:{x:Float, y:Float};

	public function new(mc:ASprite) {
		super(mc);
		link = new Array();
		Cs.game.bList.push(this);
		ray = Cs.RAY;
		frict = 1;
		wg = 0.5;

		flFly = false;
		flIce = false;

		color = Seed.random(Cs.game.colorMax);
		mc.onFrame.set(21, function() {
			var newFrame = Seed.randomVfx(3);
			mc.gotoAndStop(21 + newFrame);
		});
		updateSkin();

		root._xscale = (Cs.RAY / 12 / KadoKadeoManager.S(1)) * 100;
		root._yscale = root._xscale;
		// untyped root.light = root.attachMovie("bLight");
	}

	public override function update():Void {
		super.update();
		if (flFly) {
			if (checkCol(0))
				freeze();
			if (getDist({x: 0, y: 0}) > Cs.mcw * 0.8) {
				kill();
				Cs.game.initStep(Cs.STEP_BLAST);
			}
		}

		if (deathTimer != null) {
			deathTimer -= Timer.tmod;
			var lim = 5;
			if (deathTimer < lim) {
				var c = 1 - deathTimer / lim;
				root._xscale = 100 + c * 10;
				root._yscale = root._xscale;
			}

			if (deathTimer < 0) {
				var mc = Cs.game.dm.attach("partImpact", Game.DP_PART);
				mc.play();
				mc.removeOnFrame = mc._totalframes;
				mc._x = x;
				mc._y = y;
				mc._xscale = 300;
				mc._yscale = mc._xscale;
				mc._rotation = Seed.randVfx() * 360;
				kill();
			}
		}

		if (trg != null) {
			toward(trg, RECAL_SPEED, KadoKadeoManager.I(20));
			if (getDist(trg) < KadoKadeoManager.S(0.5))
				trg = null;
		}

		if (vs != null) {
			var ds = 100 - root._xscale;
			vs += ds * 0.2 * Timer.tmod;
			vs *= Math.pow(0.7, Timer.tmod);
			root._xscale += vs * Timer.tmod;
			root._yscale = root._xscale;

			if (Math.abs(ds) < 0.5 && Math.abs(vs) < 0.5) {
				vs = null;
				root._xscale = 100;
				root._yscale = root._xscale;
			}
		}
	}

	function checkCol(n:Int):Bool {
		for (b in Cs.game.bList) {
			if (b != this && getDist({x: b.x, y: b.y}) < ray * 2 + n)
				return true;
		}
		return false;
	}

	function freeze():Void {
		flFly = false;
		var p = 0.02;
		do {
			x -= vx * p;
			y -= vy * p;
			var pos = Cs.getPos(x, y);
			px = pos.x;
			py = pos.y;
		} while (checkCol(0) || checkPos());

		if (checkAlone(px, py))
			stickNearest();

		vx = 0;
		vy = 0;
		var ox = x;
		var oy = y;
		refreshPos();
		trg = {x: x, y: y};
		x = ox;
		y = oy;

		Cs.game.initStep(Cs.STEP_BLAST);
	}

	function checkAlone(cx:Int, cy:Int):Bool {
		for (d in Cs.DIR) {
			var nx = cx + d[0];
			var ny = cy + d[1];
			var b = Cs.game.grid[nx + Cs.GRID_RAY][ny + Cs.GRID_RAY];
			if (b != null)
				return false;
		}
		return true;
	}

	function stickNearest():Void {
		for (r in 1...10) {
			for (i in 0...Cs.DIR.length) {
				var d = Cs.DIR[i];
				var bx = px + d[0] * r;
				var by = py + d[1] * r;
				for (n in 0...r) {
					var d2 = Cs.DIR[(i + 2) % Cs.DIR.length];
					var nx = bx + d2[0] * n;
					var ny = by + d2[1] * n;
					var b = Cs.game.grid[nx + Cs.GRID_RAY][ny + Cs.GRID_RAY];
					if (b == null && !checkAlone(nx, ny)) {
						px = nx;
						py = ny;
						return;
					}
				}
			}
		}
	}

	public function setPos(nx:Int, ny:Int):Void {
		px = nx;
		py = ny;
		refreshPos();
	}

	function checkPos():Bool {
		return Cs.game.grid[px + Cs.GRID_RAY][py + Cs.GRID_RAY] != null;
	}

	function refreshPos():Void {
		x = (px + py) * Cs.WW;
		y = (px - py) * Cs.HH;
		Cs.game.grid[px + Cs.GRID_RAY][py + Cs.GRID_RAY] = this;
	}

	public function fall():Void {
		var star = new Part(Cs.game.gdm.attach("partStarBack", 10));
		star.root.loop = true;
		star.root.play();
		var s = star.root.attachMovie("partStar");
		s.gotoAndStop(1 + color);
		var pos = getWorldPos(x, y);
		star.x = pos.x;
		star.y = pos.y;
		star.weight = KadoKadeoManager.S(0.2 + Seed.randVfx() * 0.5);
		star.fadeType = 0;
		star.timer = 18 + Seed.rand() * 10;
		var baseScore = Cs.SCORE_STAR[color];
		if (color == 20)
			baseScore = Cs.C1000;

		star.deathScore = KKApi.const(KKApi.val(baseScore) * (Cs.game.combo + 1));
		kill();
	}

	public function explode():Void {
		for (_ in 0...20)
			genSpark();
		for (d in Cs.DIR) {
			var nx = px + d[0];
			var ny = py + d[1];
			var b2 = Cs.game.grid[nx + Cs.GRID_RAY][ny + Cs.GRID_RAY];
			if (b2 != null && b2.flIce)
				b2.unIce();
		}

		kill();
	}

	function genSpark():Void {
		var p = new Part(Cs.game.gdm.empty(10));
		var a = Seed.randVfx() * 6.28;
		var ca = Math.cos(a);
		var sa = Math.sin(a);
		var sp = KadoKadeoManager.S(1 + Seed.randVfx() * 3);
		var pos = getWorldPos(x, y);
		p.x = pos.x + ca * ray;
		p.y = pos.y + sa * ray;
		p.vx = ca * sp;
		p.vy = sa * sp;
		p.timer = 10 + Seed.randVfx() * 12;
		var mc:PartSparkSprite = cast p.root;
		mc.sub = mc.attachMovie("partSpark");
		mc.sub.play();
		var na = a + (Seed.randomVfx(2) * 2 - 1) * 1.57;
		var dec = KadoKadeoManager.S(1 + Seed.randVfx() * 10);
		mc.sub._x = Math.cos(na) * dec;
		mc.sub._y = Math.cos(na) * dec;
		p.x -= mc.sub._x;
		p.y -= mc.sub._y;
		p.vr = (Seed.randVfx() * 2 - 1) * 20;
		mc.sub.gotoAndPlay(Seed.randomVfx(2) + 1);
		p.fadeType = 0;
	}

	function genDust():Void {
		var p = new Part(Cs.game.dm.attach("partStarBack", Game.DP_PART));
		p.root.loop = true;
		p.root.play();
		var s = p.root.attachMovie("partStar");
		s.gotoAndStop(1 + color);
		var a = Seed.randVfx() * 6.28;
		var ca = Math.cos(a);
		var sa = Math.sin(a);
		var r = Seed.randVfx() * ray * 2 * root._xscale / 100;
		p.x = x + ca * r;
		p.y = y + sa * r;
		p.weight = KadoKadeoManager.S(0.5 + (Seed.randVfx() * 2 - 1) * 0.3);
		p.timer = 10 + Seed.randVfx() * 10;
		p.setScale(10 + Seed.randVfx() * 20);
	}

	function unIce():Void {
		flIce = false;
		updateSkin();
		var max = 10;
		for (_ in 0...max) {
			var p = new Part(Cs.game.gdm.attach("partIce", 10));
			var a = Seed.randVfx() * 6.28;
			var ca = Math.cos(a);
			var sa = Math.sin(a);
			var sp = KadoKadeoManager.S(0.5 + Seed.randVfx() * 3);
			var pos = getWorldPos(x, y);
			var r = ray + KadoKadeoManager.I(2);
			p.x = pos.x + ca * r;
			p.y = pos.y + sa * r;
			p.vx = ca * sp;
			p.vy = sa * sp;
			p.vr = (Seed.randVfx() * 2 - 1) * 16;
			p.weight = KadoKadeoManager.S(0.1 + Seed.randVfx() * 0.2);
			p.root._rotation = a / 0.0157 + 90;
			p.root.gotoAndPlay(Seed.randomVfx(20) + 1);
			p.timer = 10 + Seed.randVfx() * 50;
			p.scale = 20 + Seed.randVfx() * 100;
			p.fadeType = 1;
			p.root._xscale = p.scale;
			p.root._yscale = p.scale;
		}
	}

	public function updateSkin():Void {
		var frame = color + 1;
		if (flIce)
			frame += 10;
		root.gotoAndStop(frame);
	}

	public override function kill():Void {
		if (Cs.game.center == this)
			Cs.game.center = null;
		removeFromGrid();
		Cs.game.bList.remove(this);
		super.kill();
	}

	function removeFromGrid():Void {
		if (Cs.game.grid[px + Cs.GRID_RAY] != null)
			Cs.game.grid[px + Cs.GRID_RAY][py + Cs.GRID_RAY] = null;
	}

	function getWorldPos(x:Float, y:Float):{x:Float, y:Float} {
		var a = Math.atan2(y, x);
		var dist = Math.sqrt(x * x + y * y);
		var na = a - Cs.game.angle;
		var nx = Cs.mcw * 0.5 + Math.cos(na) * dist;
		var ny = Cs.mch * 0.5 + Math.sin(na) * dist;
		return {x: nx, y: ny};
	}
}
