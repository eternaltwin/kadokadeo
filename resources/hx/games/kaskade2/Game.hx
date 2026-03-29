package kaskade2;

import haxe.io.UInt16Array;
import mt.bumdum.Sprite;
import mt.Timer;
import common_haxe_avm1.KKApi;
import mt.bumdum.Lib;

@:expose('GameKaskade2')
class Game implements kado.GameInterface {
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
	var isReplayMode:Bool;
	var hoveredBille:Bille;
	var lastHoveredCell:{x:Int, y:Int};

	public function new(root:ASprite, ?isReplay:Bool = false) {
		this.isReplayMode = isReplay;
		KadoKadeoManager.kkm.replay.init({
			recordedKeys: new UInt16Array(0),
			recordInputs: false,
			recordEvents: true,
		});

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
		root.onPress = onClick;
	}

	public function random(max) {
		return KadoKadeoManager.kkm.seed.random(max);
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

		var clicked = lastHoveredCell;
		if (clicked == null && curGroup.length > 0) {
			clicked = getBilleGridPos(curGroup[0]);
		}
		if (clicked != null) {
			KadoKadeoManager.kkm.replay.recordEvent({k: 2, x: clicked.x, y: clicked.y});
		}

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
		KadoKadeoManager.kkm.addScore(KKApi.const(pts));

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
			p.removeOnFrame = 11;
			var color;
			if (b.id == 0)
				color = 0xFF4242;
			else if (b.id == 1)
				color = 0x4242FF;
			else
				color = 0x42FF42;
			Filt.replaceColor(p, 0x4C4C4C, color, 0.5);
			Filt.glow(p, 10, 2, color);
			b.kill();
		}
		lock = true;
		hoveredBille = null;
		lastHoveredCell = null;
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
		for (event in KadoKadeoManager.kkm.replay.consumeEvents()) {
			applyReplayEvent(event);
		}

		if (!isReplayMode) {
			updateHoverFromMouse();
		}

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

	function updateHoverFromMouse() {
		if (lock) {
			return;
		}

		var cell = screenToGrid(dm.root_mc._xmouse, dm.root_mc._ymouse);
		var bille:Bille = null;
		if (cell != null) {
			bille = findBilleAt(cell.x, cell.y);
		}

		if (bille == hoveredBille) {
			return;
		}

		if (hoveredBille != null) {
			hoveredBille.onRollOut();
		}

		hoveredBille = bille;
		lastHoveredCell = cell;

		if (hoveredBille != null && cell != null) {
			hoveredBille.onRollOver();
			KadoKadeoManager.kkm.replay.recordEvent({k: 0, x: cell.x, y: cell.y});
		}
	}

	function screenToGrid(mx:Float, my:Float):{x:Int, y:Int} {
		var dx = mx - Const.DELTA_X;
		var dy = my - Const.DELTA_Y;

		var px = dx * Bille.COS + dy * Bille.SIN;
		var py = -dx * Bille.SIN + dy * Bille.COS;

		var halfW = (Const.LVL_WIDTH * Const.BILLE_RAY) / 2;
		var halfH = (Const.LVL_HEIGHT * Const.BILLE_RAY) / 2;
		var gx = Std.int(Math.round((px + halfW) / Const.BILLE_RAY)) - 1;
		var gy = Std.int(Math.round((py + halfH) / Const.BILLE_RAY));

		if (gx < 0 || gy < 0 || gx >= Const.LVL_WIDTH || gy >= Const.LVL_HEIGHT) {
			return null;
		}

		return {x: gx, y: gy};
	}

	function applyReplayEvent(event:Dynamic) {
		if (event == null) {
			return;
		}

		var kind:Int = Reflect.field(event, "k");
		var x:Null<Int> = Reflect.field(event, "x");
		var y:Null<Int> = Reflect.field(event, "y");
		if (kind == null || x == null || y == null) {
			return;
		}

		switch (kind) {
			case 0:
				var b = findBilleAt(x, y);
				if (b != null) {
					hoveredBille = b;
					lastHoveredCell = {x: x, y: y};
					b.onRollOver();
				}
			case 1:
			case 2:
				var b = findBilleAt(x, y);
				if (b != null) {
					hoveredBille = b;
					lastHoveredCell = {x: x, y: y};
					b.onRollOver();
				}
				onClick();
			default:
		}
	}

	function findBilleAt(x:Int, y:Int):Bille {
		if (x < 0 || y < 0 || x >= Const.LVL_WIDTH || y >= Const.LVL_HEIGHT) {
			return null;
		}
		return level.billes[x][y];
	}

	function getBilleGridPos(target:Bille):{x:Int, y:Int} {
		if (target == null) {
			return null;
		}

		for (x in 0...Const.LVL_WIDTH) {
			for (y in 0...Const.LVL_HEIGHT) {
				var b = level.billes[x][y];
				if (b == target) {
					return {x: x, y: y};
				}
			}
		}

		return null;
	}

	public function gameOver() {
		KadoKadeoManager.kkm.gameOver(stats);
	}

	public function destroy() {}
}
