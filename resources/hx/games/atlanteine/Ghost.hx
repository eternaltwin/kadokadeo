package atlanteine;

import pixi.core.graphics.Graphics;
import pixi.core.Pixi.BlendModes;
import mt.bumdum.Phys;
import mt.bumdum.Lib;

class Ghost extends Phys {
	static var RAY = KadoKadeoManager.I(6);

	var game:Game;
	var smc:ASprite;

	// var debug:Graphics;
	var turnCol:Int;
	var angle:Float;
	var va:Float;
	var speed:Float;
	var speedFloat:Float;
	var float:Float;

	public function new(game:Game, mc:ASprite) {
		super(mc);
		this.game = game;
		game.ghostList.push(this);

		// debug = mc.createEmptyMovieClip().getGraphics();
		smc = mc.attachMovie("mcGhost");

		angle = Seed.rand() * 6.28;
		va = 0;
		speed = 1 + Seed.rand() * 1;
		speedFloat = 20 + Seed.rand() * 20;
		float = Seed.rand() * 628;

		var p = getFreePos();
		x = (p[0] + 0.5) * Game.SIZE;
		y = (p[1] + 0.5) * Game.SIZE;
	}

	override function update() {
		va += (Seed.rand() * 2 - 1) * 0.05;
		va *= Math.pow(0.92, mt.Timer.tmod);
		angle = Num.hMod(angle + va, 3.14);

		// GFX
		var fr = Std.int(Num.sMod(angle, 6.28) / 6.28 * 80) + 1;
		smc.gotoAndStop(fr);
		float = (float + speedFloat * mt.Timer.tmod) % 628;
		smc._y = Math.cos(float * 0.01) * 4 - 8;

		vx = Math.cos(angle) * speed;
		vy = Math.sin(angle) * speed;

		super.update();
		checkCols();
		updatePos();
	}

	function checkCols() {
		var px = getPos(x);
		var py = getPos(y);
		// #if debug
		// debug.clear();
		// debug.beginFill(0xFF0000, 0.5);
		// debug.drawCircle((px * Game.SIZE - x) + 30, (py * Game.SIZE - y) + 30, Game.SIZE / 2);
		// debug.endFill();
		// #end

		if (!game.isFree(px, py)) {
			explode();
			return;
		}

		var flCol = false;
		for (d in Game.DIR) {
			var nx = getPos(x + d[0] * RAY);
			var ny = getPos(y + d[1] * RAY);

			if (!game.isFree(nx, ny)) {
				var rr = RAY;
				if (d[0] != 0) {
					x = Num.mm(px * Game.SIZE + rr, x, (px + 1) * Game.SIZE - rr);
					vx *= -1;
				} else {
					y = Num.mm(py * Game.SIZE + rr, y, (py + 1) * Game.SIZE - rr);
					vy *= -1;
				}
				var da = Num.hMod(Math.atan2(vy, vx) - angle, 3.14);
				if (turnCol == null)
					turnCol = Seed.random(2) * 2 - 1;
				va += 0.05 * turnCol * mt.Timer.tmod;
				flCol = true;
			}
		}
		if (!flCol)
			turnCol = null;
	}

	//
	public function explode() {
		var max = 12;
		for (i in 0...max) {
			var p = new Phys(game.dm.attach("partCloud", Game.DP_PARTS));
			var sp = 0.2 + Seed.randVfx() * 0.5;
			var r = sp * 10;
			var a = i / max * 6.28;
			var ca = Math.cos(a);
			var sa = Math.sin(a);
			p.x = x + ca * r;
			p.y = y + sa * r - 6;
			p.vx = ca * sp;
			p.vy = sa * sp;
			p.frict = 0.95;
			p.timer = 10 + Seed.randVfx() * 20;
			p.sleep = Seed.randVfx() * 8;
			p.setScale(100 + Seed.randVfx() * 100);
			p.fadeType = 0;
			p.root.blendMode = BlendModes.ADD;
			p.weight = -Seed.randVfx() * 0.3;
			p.vr = (Seed.randVfx() * 2 - 1) * 10;
			p.root._rotation = Seed.randVfx() * 360;
			// if(Seed.randomVfx(2)==0)Col.setColor(p.root,0xCCCC00,-255);
			p.root.updateState();
		}

		kill();
	}

	// TOOLS
	function getFreePos() {
		var x = null;
		var y = null;
		var to = 0;
		do {
			x = Seed.random(game.xmax);
			y = Seed.random(game.ymax);
			if (to++ > 100) {
				trace("noFreePos!");
				break;
			}
		} while (!game.isFree(x, y));
		return [x, y];
	}

	function getPos(n:Float):Int {
		return Std.int(n / Game.SIZE);
	}

	override function kill() {
		game.ghostList.remove(this);
		super.kill();
	}

	// {
}
