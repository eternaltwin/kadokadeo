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

	public function onBilleClick(target:Bille) {
		var pos = getBilleGridPos(target);
		if (pos == null) {
			return;
		}
		resolveCellAction(pos.x, pos.y, true);
	}

	public function onBilleHover(target:Bille) {
		var pos = getBilleGridPos(target);
		if (pos == null) {
			return;
		}
		setHoveredCell(pos.x, pos.y, true);
	}

	public function onBilleOut(target:Bille) {
		if (lock || hoveredBille == null || target != hoveredBille) {
			return;
		}
		hoveredBille.onRollOut();
		hoveredBille = null;
		lastHoveredCell = null;
	}

	function resolveCellAction(x:Int, y:Int, recordEvent:Bool) {
		if (lock)
			return;
		setHoveredCell(x, y, recordEvent);

		if (curGroup == null) {
			return;
		}

		if (recordEvent && !isReplayMode) {
			KadoKadeoManager.kkm.replay.recordEvent({k: 2, x: x, y: y});
		}

		destroyCurrentGroup();
	}

	function setHoveredCell(x:Int, y:Int, recordEvent:Bool) {
		if (lock) {
			return;
		}

		var bille = findBilleAt(x, y);
		if (bille == hoveredBille) {
			if (bille != null) {
				lastHoveredCell = {x: x, y: y};
			}
			return;
		}

		if (hoveredBille != null) {
			hoveredBille.onRollOut();
		}

		hoveredBille = bille;
		if (hoveredBille == null) {
			lastHoveredCell = null;
			return;
		}

		lastHoveredCell = {x: x, y: y};
		hoveredBille.onRollOver();
		if (recordEvent && !isReplayMode) {
			KadoKadeoManager.kkm.replay.recordEvent({k: 0, x: x, y: y});
		}
	}

	function destroyCurrentGroup() {
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
		rehoverFromMouse();
	}

	function rehoverFromMouse() {
		var mouse = new pixi.core.math.Point(bg._xmouse, bg._ymouse);
		var best:{x:Int, y:Int, d:Float} = null;
		for (x in 0...Const.LVL_WIDTH) {
			for (y in 0...Const.LVL_HEIGHT) {
				var b = level.billes[x][y];
				if (b == null || b.mc == null || b.mc.hitArea == null)
					continue;
				var local = b.mc.toLocal(mouse);
				if (untyped b.mc.hitArea.contains(local.x, local.y)) {
					var dx = b.x - mouse.x;
					var dy = b.y - mouse.y;
					var d = dx * dx + dy * dy;
					if (best == null || d < best.d)
						best = {x: x, y: y, d: d};
				}
			}
		}
		if (best != null)
			setHoveredCell(best.x, best.y, false);
		else if (hoveredBille != null) {
			hoveredBille.onRollOut();
			hoveredBille = null;
			lastHoveredCell = null;
		}
	}

	function updateSprites() {
		Sprite.updateAll();

		// for (s in toUpdate) {
		// 	if (s.parent != null)
		// 		s.update();
		// }
	}

	public function update(ts:Float) {
		for (event in KadoKadeoManager.kkm.replay.consumeEvents()) {
			applyReplayEvent(event);
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
				setHoveredCell(x, y, false);
			case 1:
			case 2:
				resolveCellAction(x, y, false);
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
