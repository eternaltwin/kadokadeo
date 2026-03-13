package kaskade2;

import mt.Timer;
import mt.bumdum.Sprite;
import mt.bumdum.Phys;
import mt.bumdum.Lib;
import common_haxe_avm1.KKApi;
import common_haxe_avm1.KeyboardManager;

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
	var root:ASprite;
	var level:Level;
	var particules:Particules;

	public var dmanager:mt.DepthManager;
	public var nlevels:Int;

	var stats:{
		$r:Int,
		$l:Int,
		$t:Array<Int>,
		$g:Array<Int>,
		$c:Array<Array<Int>>,
	};

	var cur:{x:Int, y:Int};

	public var bg:ASprite;

	var timebar:ASprite;
	var curGroup:Array<Bille>;
	var flash:Float;
	var lock:Bool;
	var time:Float;
	var ncoups:KKConst;

	public function new(kkm:kado.KadoKadeoManager) {
		this.kkm = kkm;
		root = new ASprite();
		kkm.stage.addChild(root);
		dmanager = new mt.DepthManager(root);
		particules = new Particules(dmanager);
		nlevels = 3;
		level = new Level(this);
		time = 0;
		ncoups = Const.NCOUPS;
		lock = false;
		bg = dmanager.attach("bg", Const.PLAN_BG);
		timebar = dmanager.attach("timebar", Const.PLAN_OVER);
		// FIXME: callback ?
		// bg.onMouseMove = callback(this, onMouseMove);
		// bg.onMouseDown = callback(this, onClick);
		bg.useHandCursor = false;
	}

	public function start() {}

	public function stop() {}

	public function updateGraphics(a:Float) {
		root.updateGraphics(a);
	}

	public function random(max) {
		return kkm.seed.random(max);
	}

	public function onMouseMove() {
		if (lock)
			return;

		// var xm = Std.xmouse() - Const.WIDTH / 2;
		// var ym = Std.ymouse() - Const.HEIGHT / 2;

		var delt = Math.sqrt(Const.WIDTH * Const.WIDTH + Const.HEIGHT * Const.HEIGHT) / 2;

		// var x = xm * Bille.INV_COS - ym * Bille.INV_SIN + delt / 2;
		// var y = xm * Bille.INV_SIN + ym * Bille.INV_COS + delt / 2;

		// x /= Const.BILLE_RAY;
		// y /= Const.BILLE_RAY;

		// cur = {x: x.int(), y: y.int()};

		// var b = level.billes[x.int()][y.int()];
		// if (curGroup == b.group)
		// 	return;
		// for (group in curGroup) {
		// 	group.activate(false);
		// }
		// curGroup = b.group;
		// if (b.group != null) {
		// 	for (group in curGroup) {
		// 		group.activate(true);
		// 	}
		// 	showCursor();
		// } else
		// 	hideCursor();
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

		var x = 0;
		while (x < Const.LVL_WIDTH) {
			var y = 0;
			while (y < Const.LVL_HEIGHT) {
				var b = level.billes[x][y];
				if (b.group == curGroup)
					level.billes[x][y] = null;
				y++;
			}
			x++;
		}

		var n = curGroup.length;
		ncoups = KKApi.const(KKApi.val(ncoups) - 1);

		var pts = (n * (n - 1) / 2 * KKApi.val(Const.C100)).int();
		stats.$t.push(time.int());
		stats.$g.push(n);
		stats.$c.push([cur.x, cur.y]);
		kkm.addScore(KKApi.const(pts));

		var i = 0;
		while (i < curGroup.length) {
			var j = 0;
			var b = curGroup[i];
			while (j < 3) {
				particules.addWordPart(b.mc._x, b.mc._y, b.mc._currentframe);
				j++;
			}
			var p = dmanager.attach("explosion", Const.PLAN_PART);
			p._x = b.mc._x;
			p._y = b.mc._y;
			p._rotation = Std.random(360);
			// downcast(p).sub.gotoAndPlay((Std.random(3) + 1) + "");
			p._alpha = 30 + Std.random(70);
			p.gotoAndStop(b.mc._currentframe + "");
			b.mc.removeMovieClip();
			i++;
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
		onMouseMove();
	}

	public function update(ts:Float) {
		var p = Math.pow(0.6, Timer.tmod);
		if (flash != null) {
			flash -= Timer.tmod * 3;
			if (flash < 0)
				flash = 0;
			var k = (flash * 2.55).int();
			var f = (flash / 2).int();
			// var c = new Color(dmanager.getMC());
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
