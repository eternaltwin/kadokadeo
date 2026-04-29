package ironchouquette;

import common_haxe_avm1.KKApi;
import mt.DepthManager;
import mt.bumdum.Lib;

class Bonus extends Phys {
	public static var ID_MAX = 4;
	public static var SPEED = 3 * Cs.NEW_GEN_SCALE;
	public static var SCORE = KKApi.aconst([1000, 3000, 12000]);

	public static var WP_PLASMA = 0;
	public static var WP_SIDER = 1;
	public static var WP_LASER = 2;
	public static var WP_SPEED = 3;
	public static var WP_VOID = 4;
	public static var WP_MISSILE = 5;

	public static var NB = 0;

	public static var STATS = [
		100, // PLASMA;
		60, // SIDER;
		50, // LASER;
		70, // SPEED;
		70, // VOID;
		70, // MISSILE;
		30, // SLOT;
		0, // GREEN;
		0, // BLUE;
		0 // PINK;
	];

	public var id:Int;
	public var dm:DepthManager;

	public function new(mc, ?forcedId:Int, ?forcedDir:Int) {
		Cs.game.bonusList.push(this);

		ray = 15 * Cs.NEW_GEN_SCALE;
		id = forcedId == null ? getRandomId() : forcedId;
		// id = 3;
		var dir = forcedDir == null ? Seed.random(2) : forcedDir;
		var a = 0.775 + dir * 1.57;
		if (mc == null)
			mc = Cs.game.dm.attach("mcBonus" + (id + 1), Game.DP_BADS);
		super(mc);
		root.loop = true;
		root.play();
		dm = new DepthManager(root);
		vx = Math.cos(a) * SPEED;
		vy = Math.sin(a) * SPEED;
	}

	public static function getRandomId() {
		var max = 0;
		for (i in 0...STATS.length) {
			max += STATS[i];
		}
		var rnd = Seed.random(max);
		var cur = 0;
		for (i in 0...STATS.length) {
			cur += STATS[i];
			if (cur > rnd) {
				return i;
			}
		}
		return 0;
	}

	public override function update() {
		super.update();
		if (collide(Cs.game.hero))
			take();

		checkBounds();
		if (isOut(ray * 2))
			kill();

		if (id >= 15 && id <= 17) {
			for (i in 0...2) {
				var p = new Part(dm.attach("partRay", 1));
				p.root.gotoAndStop(id - 14);
				p.vr = (Seed.randVfx() * 2 - 1) * 10;
				p.fadeType = 3;
				p.scale = 50 + Seed.randVfx() * 100;
				p.root._xscale = 10 + Seed.randVfx() * 20;
				p.root._yscale = p.scale;
				p.root._rotation = Seed.randVfx() * 360;
				p.timer = 10 + Seed.randVfx() * 10;
				p.root._x = 0;
				p.root._y = 0;
			}
		}
	}

	public function take() {
		switch (id) {
			case 0 | 1 | 2 | 3 | 4 | 5:
				Cs.game.hero.addWeapon(id);
			case 6:
				Cs.game.hero.addBox();
		}
		Cs.game.stats.b.push([Std.int(Stykades.dif), id]);
		kill();
	}

	/*
		function exploPaillette(){

			var max = 24*Game.PM;
			for (i in 0...max) {
				var p = new Part(Cs.game.dm.attach("partPaillette",Game.DP_PARTS));
				p.root.gotoAndStop(Std.string(id - 14));
				var a = Math.random()*6.28;
				var ca = Math.cos(a);
				var sa = Math.sin(a);
				var r = 5+Math.random()*ray;
				var sp = 0.5+Math.random()*2;
				p.x = x+ca*r;
				p.y = y+sa*r;
				p.vx = ca*sp;
				p.vy = sa*sp;
				p.vr = (Math.random()*2-1)*20;
				p.timer = 10+Math.random()*20;
				p.setScale(10+Math.random()*50);
				p.root._rotation = Math.random()*360;
				p.fadeType = 0;

			}
			for (i in 0...12) {
				var p = newPart("partLight",ray,1+Math.random()*3);
				p.setScale(50+Math.random()*100);
			}

		}

		function newPart(link,r,sp){
			var p = new Part(Cs.game.dm.attach(link,Game.DP_PARTS));
			var a = Math.random()*6.28;
			var ca = Math.cos(a);
			var sa = Math.sin(a);
			p.x = x+ca*r;
			p.y = y+sa*r;
			p.vx = ca*sp;
			p.vy = sa*sp;
			p.timer = 10+Math.random()*10;
			p.fadeType = 0;
			return p;
		}
	 */
	public function checkBounds() {
		if (x < ray || x > Cs.mcw - ray) {
			vx *= -1;
			x = Num.mm(ray, x, Cs.mcw - ray);
		}
		if (y > Cs.mch - ray) {
			vy *= -1;
			y = Num.mm(ray, y, Cs.mch - ray);
		}
	}

	public override function kill() {
		Cs.game.bonusList.remove(this);
		super.kill();
	}
}
