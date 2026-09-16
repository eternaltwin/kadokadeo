package alchimie;

import kado.TouchControlsConfig.TouchControlsMode;
import mt.bumdum.Phys;
import mt.bumdum.Sprite;

class PointIconSprite extends ASprite {
	public var coin:ASprite;
	public var shadow:ASprite;
}

class PointsSprite extends ASprite {
	public var field:Text;
	public var ico:PointIconSprite;
}

@:expose('GameAlchimie')
class Game implements kado.GameInterface {
	public static var TOUCH_CONTROLS:kado.TouchControlsConfig = {
		mode: TouchControlsMode.KEYBOARD,
		buttons: [
			{
				id: "rotate",
				label: "",
				size: 4000,
				action: "tap_rotate",
				invisible: true,
			}
		],
		swipe: {
			leftAction: "swipe_left",
			rightAction: "swipe_right",
			downAction: "swipe_down",
			minDistance: 48,
			maxDurationMs: 300,
		},
	};

	public var dmanager:DepthManager;

	var particules:Particules;
	var level:Level;
	var c1:Coin;
	var c2:Coin;
	var rot:Int;
	var tr:Int;
	var tx:Int;
	var rot_activate:Bool;
	var lock:Bool;
	var way:Int;
	var bg:ASprite;
	var points:Array<PointsSprite>;
	var piece:{mc:ASprite, dmanager:DepthManager};
	var pendingVirtualKeyUps:Array<{keyCode:Int, framesLeft:Int}>;

	var stats:{
		k:Int,
		b:Array<Int>
	};

	public function new(root:ASprite, ?isReplay:Bool = false) {
		var replayKeys = new UInt16Array(11);
		replayKeys[0] = KeyboardManager.ARROW_LEFT;
		replayKeys[1] = KeyboardManager.ARROW_RIGHT;
		replayKeys[2] = KeyboardManager.ARROW_DOWN;
		replayKeys[3] = KeyboardManager.ARROW_UP;
		replayKeys[4] = KeyboardManager.SPACE;
		replayKeys[5] = KeyboardManager.A;
		replayKeys[6] = KeyboardManager.Q;
		replayKeys[7] = KeyboardManager.D;
		replayKeys[8] = KeyboardManager.S;
		replayKeys[9] = KeyboardManager.W;
		replayKeys[10] = KeyboardManager.Z;
		KadoKadeoManager.kkm.replay.init({
			recordedKeys: replayKeys,
			recordInputs: true,
			recordEvents: false,
		});
		pendingVirtualKeyUps = [];

		dmanager = new DepthManager(root);
		bg = dmanager.attach("bg", Cs.PLAN_BG);
		stats = {
			k: 0,
			b: []
		};
		particules = new Particules(dmanager);
		level = new Level(this);
		level.initLevel();
		initPoints();
		updatePoints();
		initCoin();
		nextTurn();
		way = 0;
		Cs.game = this;
	}

	function initPoints():Void {
		points = [];
		for (i in 0...Cs.POINTS.length) {
			var mc:PointsSprite = cast dmanager.attach("mcScoreInfo", Cs.PLAN_INTERF);
			mc.field = mc.initTextField('field', {
				font: "Arial",
				size: 20,
				color: 0xFFFFFF,
				x: KadoKadeoManager.I(8),
				y: KadoKadeoManager.I(4),
			});
			mc.field.alpha = 0.5;
			mc.ico = cast mc.createEmptyMovieClip();
			mc.ico._x = -KadoKadeoManager.I(22);
			mc.ico._y = KadoKadeoManager.I(3);
			mc.ico._xscale = 70;
			mc.ico._yscale = 70;
			mc.ico.coin = mc.ico.attachMovie("coin");
			mc.ico.shadow = mc.ico.attachMovie("coinShadow");
			mc._x = KadoKadeoManager.I(32);
			mc._y = KadoKadeoManager.S(3 + i * 24.5);
			mc.field.text = Std.string(KKApi.val(Cs.POINTS[i]));
			points.push(mc);
		}
	}

	function updatePoints():Void {
		for (i in 0...points.length) {
			var mc = points[i];
			if (i < Cs.ID_COUNT) {
				mc.ico.coin._visible = true;
				mc.ico.shadow._visible = false;
			} else {
				mc.ico.coin._visible = false;
				mc.ico.shadow._visible = true;
			}
			mc.ico.coin.gotoAndStop(i + 1);
			mc.ico.shadow.gotoAndStop(i + 1);
		}
	}

	function initCoin():Void {
		var mc = dmanager.empty(Cs.PLAN_COIN);
		piece = {mc: mc, dmanager: new DepthManager(mc)};
		c1 = new Coin(piece, 0, 0);
		c2 = new Coin(piece, 0, 0);
		c1.mc._x = Cs.COIN_SIZE / 2;
		c2.mc._x = -Cs.COIN_SIZE / 2;
		c1.mc._y = 0;
		c2.mc._y = 0;
		mc._x = KadoKadeoManager.I(150);
		tr = 0;
		rot = 0;
	}

	function rotate():Void {
		rot++;
		rot %= 4;
		switch (rot) {
			case 0:
				tr = 0;
			case 1:
				tr = 90;
				piece.dmanager.over(c1.mc);
			case 2:
				tr = 180;
			case 3:
				tr = -90;
				piece.dmanager.over(c2.mc);
		}
	}

	function fall():Void {
		var px = Std.int((piece.mc._x - Cs.POS_X + KadoKadeoManager.I(5)) / Cs.COIN_SIZE);
		var dy = 0;
		var p1:{x:Int, y:Int} = null;
		var p2:{x:Int, y:Int} = null;
		switch (rot) {
			case 0:
				dy = Std.int(Cs.COIN_SIZE / 2);
				p1 = {x: px + 1, y: 0};
				p2 = {x: px, y: 0};
			case 1:
				p1 = {x: px, y: 1};
				p2 = {x: px, y: 0};
			case 2:
				dy = Std.int(Cs.COIN_SIZE / 2);
				p1 = {x: px, y: 0};
				p2 = {x: px + 1, y: 0};
			case 3:
				p1 = {x: px, y: 0};
				p2 = {x: px, y: 1};
		}

		var cc1 = new Coin(this, p1.x, p1.y);
		cc1.setId(c1.id);
		level.coins[p1.x][p1.y] = cc1;

		var cc2 = new Coin(this, p2.x, p2.y);
		cc2.setId(c2.id);
		level.coins[p2.x][p2.y] = cc2;

		stats.k++;

		piece.mc._visible = false;
		level.gravity();
		cc1.dy -= dy;
		cc1.mc._y += dy;
		cc2.dy -= dy;
		cc2.mc._y += dy;
		lock = true;
	}

	function nextTurn():Void {
		for (i in 0...Cs.WIDTH) {
			if (level.coins[i][1] != null) {
				KadoKadeoManager.kkm.gameOver(stats);
				lock = true;
				return;
			}
		}

		c1.setId(Seed.random(Cs.ID_COUNT - 1));
		c2.setId(Seed.random(Cs.ID_COUNT - 1));
		piece.mc._y = -Cs.COIN_SIZE;
		piece.mc._visible = true;
		piece.mc.updateState();
	}

	function calcPoints():Void {
		var s = 0;
		for (i in 0...stats.b.length) {
			stats.b[i] = 0;
		}
		for (x in 0...Cs.WIDTH) {
			for (y in 0...Cs.HEIGHT) {
				var c = level.coins[x][y];
				if (c != null) {
					if (stats.b[c.id] == null) {
						stats.b[c.id] = 0;
					}
					stats.b[c.id]++;
					s += KKApi.val(Cs.POINTS[c.id]);
				}
			}
		}
		KadoKadeoManager.kkm.score = s;
		KadoKadeoManager.kkm.addScore(0);
	}

	public function update(delta:Float):Void {
		Sprite.updateAll();
		flushPendingVirtualKeyUps();

		if (lock) {
			if (!level.update()) {
				lock = level.gravity();
				if (!lock) {
					lock = level.explode();
					calcPoints();
					updatePoints();
					if (!lock) {
						nextTurn();
					}
				}
			}
			return;
		}

		piece.mc._y = (piece.mc._y + Cs.COIN_SIZE) / 2;

		var moving = false;
		if (piece.mc._rotation != tr * 1.0) {
			var dr = tr - piece.mc._rotation;
			while (dr > 180) {
				dr -= 360;
			}
			while (dr <= -180) {
				dr += 360;
			}
			piece.mc._rotation += dr * 0.4 * Timer.tmod;
			moving = Math.abs(dr) > 5;

			c1.mc._rotation = -piece.mc._rotation;
			c2.mc._rotation = -piece.mc._rotation;
		}

		var calcx = Std.int((piece.mc._x - Cs.POS_X) / Cs.COIN_SIZE);
		var bigx = Math.round((piece.mc._x - Cs.POS_X) / Cs.COIN_SIZE);
		var maxx = Cs.WIDTH - ((rot == 0 || rot == 2) ? 2 : 1);

		if (tx == null) {
			tx = calcx;
		}

		if (calcx < 0) {
			calcx = 0;
		} else if (calcx > maxx) {
			calcx = maxx;
		}
		if (tx > maxx) {
			tx = maxx;
		} else if (tx < 0) {
			tx = 0;
		}

		var s = Math.min(KadoKadeoManager.I(5) * Timer.tmod, KadoKadeoManager.I(20));
		var ds = 0.0;
		if ((KeyboardManager.isDown(KeyboardManager.LEFT)
			|| KeyboardManager.isDown(KeyboardManager.A)
			|| KeyboardManager.isDown(KeyboardManager.Q))
			&& bigx > 0) {
			tx = bigx - 1;
			ds = -s;
			moving = true;
		} else if ((KeyboardManager.isDown(KeyboardManager.RIGHT) || KeyboardManager.isDown(KeyboardManager.D)) && calcx < maxx) {
			tx = calcx + 1;
			ds = s;
			moving = true;
		} else {
			var px = (tx + (((rot & 1) == 0) ? 0.5 : 0)) * Cs.COIN_SIZE + Cs.POS_X;
			var p = Math.pow(0.7, Timer.tmod);
			moving = Math.abs(piece.mc._x - px) > KadoKadeoManager.I(4);
			piece.mc._x = piece.mc._x * p + px * (1 - p);
		}
		piece.mc._x += ds;

		if (KeyboardManager.isJustDown(KeyboardManager.DOWN) || KeyboardManager.isJustDown(KeyboardManager.S)) {
			if (!moving) {
				fall();
			}
		}
		if ((rot_activate
			|| KeyboardManager.isJustDown(KeyboardManager.SPACE)
			|| KeyboardManager.isJustDown(KeyboardManager.UP)
			|| KeyboardManager.isJustDown(KeyboardManager.W)
			|| KeyboardManager.isJustDown(KeyboardManager.Z))
			&& !moving) {
			rot_activate = false;
			rotate();
		}
	}

	public function onTouchAction(action:String):Void {
		switch (action) {
			case "tap_rotate":
				queueVirtualTap(KeyboardManager.SPACE);
			case "swipe_left":
				queueVirtualTap(KeyboardManager.ARROW_LEFT);
			case "swipe_right":
				queueVirtualTap(KeyboardManager.ARROW_RIGHT);
			case "swipe_down":
				queueVirtualTap(KeyboardManager.ARROW_DOWN);
		}
	}

	function queueVirtualTap(keyCode:Int):Void {
		KeyboardManager.queueVirtualKeyDown(keyCode);
		pendingVirtualKeyUps.push({
			keyCode: keyCode,
			framesLeft: 4
		});
	}

	function flushPendingVirtualKeyUps():Void {
		var keep:Array<{keyCode:Int, framesLeft:Int}> = [];
		for (entry in pendingVirtualKeyUps) {
			entry.framesLeft--;
			if (entry.framesLeft <= 0) {
				KeyboardManager.queueVirtualKeyUp(entry.keyCode);
			} else {
				keep.push(entry);
			}
		}
		pendingVirtualKeyUps = keep;
	}

	public function destroy():Void {}

	public function newPart(link:String):Phys {
		var mc = dmanager.attach(link, Cs.PLAN_PART);
		var part = new Phys(mc);
		return part;
	}
}
