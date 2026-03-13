package kaskade2;

import mt.bumdum.Sprite;
import mt.Timer;
import common_haxe_avm1.KKApi;

@:expose('GameKaskade2')
class Game implements kado.GameInterface {
	public var kkm:kado.KadoKadeoManager;

	// !TRICHE! Partie de fish1976 (User #799259) score annoncé : 584540
	// static var replaySeed = 244383;
	// static var replay =  [[5, 5], [4, 5], [4, 5], [4, 4], [5, 5], [6, 4], [7, 5], [4, 2], [2, 3], [3, 3], [3, 4], [6, 4], [7, 5], [4, 6], [6, 3], [1, 6], [0, 1], [2, 3], [3, 1], [4, 2], [3, 1], [7, 7], [5, 6], [0, 2], [0, 3], [0, 4], [1, 0], [1, 0], [2, 1], [7, 7], [7, 4], [1, 1], [1, 1], [1, 1], [1, 0], [0, 5], [4, 4], [7, 3], [4, 4], [0, 1]];
	// OK score=402300
	// static var replaySeed = 581825;
	// static var replay = [[2, 3], [6, 2], [6, 4], [5, 3], [5, 4], [2, 3], [3, 3], [6, 4], [4, 2], [4, 0], [4, 3], [4, 3], [4, 1], [7, 3], [7, 3], [7, 2], [6, 2], [4, 4], [5, 2], [6, 2]];
	// OK score=390300
	// static var replaySeed = 10426;
	// static var replay = [[4, 3], [6, 2], [5, 2], [2, 3], [4, 3], [3, 1], [5, 4], [2, 2], [4, 4], [6, 2], [2, 4], [4, 4], [4, 3], [5, 4], [5, 4], [4, 2], [4, 2], [7, 4], [7, 3], [7, 4]];
	// score=402300,
	// CORRECT Partie correcte pour tester replay
	// static var replaySeed = 10426;
	// static var replay = [[4, 3], [6, 2], [5, 2], [2, 3], [4, 3], [3, 1], [5, 4], [2, 2], [4, 4], [6, 2], [2, 4], [4, 4], [4, 3], [5, 4], [5, 4], [4, 2], [4, 2], [7, 4], [7, 3], [7, 4]];
	var level:Level;
	var particules:Particules;

	public var dm:mt.DepthManager;
	public var nlevels:Int;
	public var curGroup:Array<Bille>;

	var stats:{t:Array<Int>, g:Array<Int>} = {t: [], g: []};

	public var bg:ASprite;
	public var lock:Bool;

	var timebar:ASprite;
	var flash:Float;
	var time:Float;
	var ncoups:KKConst;

	public function new(kkm:kado.KadoKadeoManager, root:ASprite) {
		this.kkm = kkm;
		dm = new mt.DepthManager(root);
		particules = new Particules(dm);
		nlevels = 3;
		level = new Level(this);
		time = 0;
		ncoups = Const.NCOUPS;
		lock = false;
		bg = dm.attach("bg", Const.PLAN_BG);
		timebar = dm.attach("timebar", Const.PLAN_OVER);
		bg.useHandCursor = false;
		root.onRelease = onClick;
	}

	public function random(max) {
		return kkm.seed.random(max);
	}

	public function showCursor() {
		bg.useHandCursor = true;
		// Mouse.hide();
		// Mouse.show();
	}

	public function hideCursor() {
		bg.useHandCursor = false;
		// Mouse.hide();
		// Mouse.show();
	}

	public function onClick() {
		if (lock || curGroup == null)
			return;

		for (x in 0...Const.LVL_WIDTH) {
			for (y in 0...Const.LVL_HEIGHT) {
				var b = level.billes[x][y];
				if (b.group == curGroup) {
					level.billes[x][y].kill();
					level.billes[x][y] = null;
				}
			}
		}

		var n = curGroup.length;
		ncoups = KKApi.const(KKApi.val(ncoups) - 1);

		var pts = (n * (n - 1) / 2 * KKApi.val(Const.C100)).int();
		stats.t.push(time.int());
		stats.g.push(n);
		kkm.addScore(KKApi.const(pts));

		for (b in curGroup) {
			// for (j in 0...3) {
			// 	particules.addWordPart(b.mc._x, b.mc._y, b.mc._currentframe);
			// }
			var p = dm.attach("explosion", Const.PLAN_PART);
			p._x = b.x;
			p._y = b.y;
			p._rotation = Std.random(360);
			p.gotoAndPlay(1);
			p._alpha = 30 + Std.random(70);
			// p.gotoAndStop(b.mc._currentframe + ""); // replace by tint
			b.kill();
		}
		lock = true;
		level.gravity();
	}

	public function nextTurn() {
		if (KKApi.val(ncoups) == 0) {
			this.gameOver();
			return;
		}
		curGroup = null;
		lock = false;
	}

	function updateSprites() {
		var list = Sprite.spriteList.copy();
		for (sp in list)
			sp.update();

		// for (s in toUpdate) {
		// 	if (s.parent != null)
		// 		s.update();
		// }
	}

	public function update(ts:Float) {
		dm.root_mc.update();
		updateSprites();
		var p = Math.pow(0.6, Timer.tmod);
		if (flash != null) {
			flash -= Timer.tmod * 3;
			if (flash < 0)
				flash = 0;
			var k = (flash * 2.55).int();
			var f = (flash / 2).int();
			// var c = new Color(dm.getMC());
			// c.setTransform({
			// 	ra: 100 - f,
			// 	rb: k,
			// 	ga: 100 - f,
			// 	gb: 0,
			// 	ba: 100 - f,
			// 	bb: 0,
			// 	aa: 100,
			// 	ab: 0
			// });
			if (flash == 0)
				flash = null;
		}
		time += Timer.deltaT;
		timebar.gotoAndStop((KKApi.val(ncoups) + 1).int());
		particules.update();
		level.update();
	}

	public function gameOver() {
		kkm.gameOver(stats);
	}

	public function destroy() {}
}
