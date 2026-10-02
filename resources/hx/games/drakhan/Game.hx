package drakhan;

import common_haxe_avm1.KKApi;
import common_haxe_avm1.KeyboardManager;
import common_haxe_avm1.MouseManager;
import haxe.io.UInt16Array;
import kado.TouchControlsConfig.TouchButtonShape;
import kado.TouchControlsConfig.TouchControlsMode;
import mt.DepthManager;
import mt.Timer;
import mt.bumdum.Lib;
import mt.bumdum.Sprite;
import pixi.core.text.Text;

class TextSprite extends ASprite {
	public var txt:Text;
}

@:expose('GameDrakhan')
class Game implements kado.GameInterface {
	public static var TOUCH_CONTROLS:kado.TouchControlsConfig = {
		mode: TouchControlsMode.KEYBOARD,
		passthroughMouseButtons: false,
		buttons: [
			{
				id: "launch",
				label: "🏹",
				rightPx: 20,
				bottomPx: 20,
				size: 88,
				keyCode: KeyboardManager.SPACE,
				shape: TouchButtonShape.CIRCLE,
			}
		],
	};

	public static var DP_BALL = 2;
	public static var DP_PART = 3;

	static var BLAST_TIME = 6;
	static var FALL_WAIT = 20;
	static var HAND_SPEED_COEF = 0.3;
	static inline var REPLAY_EVENT_AIM = 0;
	static inline var REPLAY_EVENT_LAUNCH = 1;
	static inline var AIM_SAMPLE_INTERVAL = 32;
	static inline var QUANTIZED_ANGLE_MAX = 65535;

	public var dm:DepthManager;
	public var gdm:DepthManager;

	var pList:Array<ASprite>;
	var nList:Array<Ball>;

	public var bList:Array<Ball>;

	var exploList:Array<Ball>;
	var deathList:Array<Ball>;

	var hand:Ball;

	public var center:Ball;

	var oxm:Float;
	var oym:Float;
	var oa:Float;

	public var grid:Array<Array<Ball>>;

	var bg:ASprite;
	var map:ASprite;
	var mcMulti:TextSprite;
	var msg:TextSprite;

	public var colorMax:Int;

	var turn:Int;

	public var combo:Int;

	var toScore:{n:Int};

	var step:Int;
	var timer:Float;

	public var angle:Float;

	var speedAngle:Float;

	var endBonus:Int;
	var generator:{ray:Int, dir:Int, dist:Int};
	var stats:{sp:Int, sc:Array<{c:Int, s:Int, t:Int}>};
	var isReplayMode:Bool;
	var lastAimSampleFrame = -1;
	var replayAimStartFrame = 0;
	var replayAimDuration = 0;
	var replayAimStartAngle = 0.0;
	var replayAimTargetAngle:Null<Float>;
	var pendingReplayLaunchAngle:Null<Int>;

	public function new(root:ASprite, ?isReplay:Bool = false) {
		isReplayMode = isReplay;
		KadoKadeoManager.kkm.replay.init({
			recordedKeys: new UInt16Array(0),
			recordInputs: false,
			recordEvents: true,
		});

		Cs.init();
		Cs.game = this;

		gdm = new DepthManager(root);
		map = gdm.attach("mcWheel", 1);
		map._x = Cs.mcw * 0.5;
		map._y = Cs.mch * 0.5;

		dm = new DepthManager(map);
		bg = gdm.attach("mcBg", 0);

		bList = new Array();
		pList = new Array();
		stats = {sp: 0, sc: []};

		grid = new Array();
		for (x in 0...2 * Cs.GRID_RAY * 2)
			grid[x] = new Array();

		colorMax = Cs.COLOR_START;
		turn = 0;
		combo = 0;

		genCenter();
		initNextList();
		initStep(Cs.STEP_SPAWN_CENTER);

		angle = 0;
		oxm = 0;
		oym = 0;
		oa = 0;
		speedAngle = 0;
		endBonus = Cs.C2000;
	}

	function initNextList():Void {
		nList = new Array();
		for (_ in 0...3)
			nList.push(newBall());
	}

	function newBall():Ball {
		var b = new Ball(gdm.attach("mcBall", 5));
		b.x = -Cs.RAY;
		b.y = Cs.mch + Cs.RAY;
		if (turn > Cs.ICE_TURN_MIN) {
			var proba = Cs.ICE_MIN + Num.mm(0, (turn - Cs.ICE_TURN_MIN) / Cs.ICE_PROGRESSION, Cs.ICE_MAX - Cs.ICE_MIN);
			if (Seed.rand() < proba) {
				b.flIce = true;
				b.updateSkin();
			}
		}
		if (turn > Cs.MU_TURN_MIN) {
			var proba = Cs.MU_MIN + Num.mm(0, (turn - Cs.MU_TURN_MIN) / Cs.MU_PROGRESSION, Cs.MU_MAX - Cs.MU_MIN);
			if (Seed.rand() < proba) {
				b.color = 20;
				b.flIce = false;
				b.root.gotoAndStop(21);
			}
		}

		bList.remove(b);

		return b;
	}

	public function initStep(s:Int):Void {
		step = s;

		switch (step) {
			case Cs.STEP_CONTROL:
				bg.cursor = "pointer";
			case Cs.STEP_FLY:
				bg.cursor = "default";
			case Cs.STEP_BLAST:
				genExploList();
				timer = BLAST_TIME;
				if (exploList.length == 0) {
					newTurn();
				} else if (combo > 1) {
					if (mcMulti != null && mcMulti._visible)
						mcMulti.removeMovieClip();
					mcMulti = cast gdm.empty(20);
					mcMulti.anchor.x = 0.5;
					mcMulti.anchor.y = 0.5;
					mcMulti._totalframes = 16;
					mcMulti.removeOnFrame = 16;
					mcMulti.play();
					mcMulti.txt = mcMulti.initTextField("txt", {
						font: "Junegull-Regular",
						size: 40,
						color: 0x000000,
						align: "left",
						x: KadoKadeoManager.I(3),
						y: KadoKadeoManager.I(3),
					});
					mcMulti.txt.text = " x" + combo + " ";
					mcMulti.onFrame.set(1, function() {
						mcMulti._xscale = mcMulti._yscale = 267;
						mcMulti._alpha = 10;
					});
					mcMulti.onFrame.set(2, function() {
						mcMulti._xscale = mcMulti._yscale = 189;
						mcMulti._alpha = 50;
					});
					mcMulti.onFrame.set(3, function() {
						mcMulti._xscale = mcMulti._yscale = 134;
						mcMulti._alpha = 78;
					});
					mcMulti.onFrame.set(4, function() {
						mcMulti._xscale = mcMulti._yscale = 101;
						mcMulti._alpha = 94;
					});
					mcMulti.onFrame.set(5, function() {
						mcMulti._xscale = mcMulti._yscale = 89;
						mcMulti._alpha = 100;
					});
					mcMulti.onFrame.set(6, () -> mcMulti._xscale = mcMulti._yscale = 95);
					mcMulti.onFrame.set(7, () -> mcMulti._xscale = mcMulti._yscale = 100);
					mcMulti.onFrame.set(8, () -> mcMulti._xscale = mcMulti._yscale = 105);
					mcMulti.onFrame.set(9, () -> mcMulti._xscale = mcMulti._yscale = 102);
					mcMulti.onFrame.set(10, () -> mcMulti._xscale = mcMulti._yscale = 100);
					mcMulti.onFrame.set(11, () -> mcMulti._xscale = mcMulti._yscale = 81);
					mcMulti.onFrame.set(12, () -> mcMulti._xscale = mcMulti._yscale = 62);
					mcMulti.onFrame.set(13, () -> mcMulti._xscale = mcMulti._yscale = 43);
					mcMulti.onFrame.set(14, () -> mcMulti._xscale = mcMulti._yscale = 25);
					mcMulti.onFrame.set(15, () -> mcMulti._xscale = mcMulti._yscale = 6);
				}
			case Cs.STEP_FALL:
				timer = FALL_WAIT;
				if (!genFallList())
					initStep(Cs.STEP_BLAST);
			case Cs.STEP_SPAWN_CENTER:
				generator = {ray: 1, dir: 0, dist: 0};
				timer = 0;
			case Cs.STEP_DEATH:
				timer = 25;
				for (i in 1...bList.length) {
					var b = bList[i];
					b.deathTimer = b.getDist({x: 0, y: 0}) * 0.2;
				}
			case _:
		}
	}

	function newTurn():Void {
		if (bList.length == 1) {
			initStep(Cs.STEP_SPAWN_CENTER);
			KadoKadeoManager.kkm.addScore(endBonus);
			setMsg("+" + KKApi.val(endBonus));
			endBonus = KKApi.cadd(endBonus, Cs.C2000);
			stats.sp++;
			return;
		}

		turn++;
		combo = 0;
		if (turn > Cs.COLOR_RYTHM[colorMax - Cs.COLOR_START])
			colorMax++;
		if (bList.indexOf(hand) >= 0 && hand.root._visible && hand.getDist({x: 0, y: 0}) > Cs.WHEEL_RAY - KadoKadeoManager.I(20))
			initStep(Cs.STEP_DEATH);
		else
			initStep(Cs.STEP_CONTROL);
	}

	public function update(delta:Float):Void {
		if (isReplayMode) {
			updateReplayAim();
			consumeReplayEvents();
		}

		timer -= Timer.tmod;
		switch (step) {
			case Cs.STEP_CONTROL:
				if (isReplayMode) {
					if (pendingReplayLaunchAngle != null) {
						var launchAngle = pendingReplayLaunchAngle;
						pendingReplayLaunchAngle = null;
						applyQuantizedLaunch(launchAngle);
					}
				} else {
					var frame = KadoKadeoManager.kkm.replay.getCurrentFrame();
					if (lastAimSampleFrame < 0)
						lastAimSampleFrame = frame;
					updateWheel();
					recordAimSample(frame);
					if (KeyboardManager.isJustDown(KeyboardManager.SPACE) || MouseManager.isButtonJustPressed(MouseManager.BUTTON_LEFT))
						recordLaunch(frame);
				}
			case Cs.STEP_FLY:
				Timer.tmod = 1;
			case Cs.STEP_BLAST:
				var c = timer / BLAST_TIME;
				for (b in exploList) {
					Col.setPercentColor(b.root, (1 - c) * 100, 0xFFFFFF);
					b.root._xscale = 100 + (1 - c) * 30;
					b.root._yscale = b.root._xscale;
					if (c < 0)
						b.explode();
				}
				if (c < 0) {
					KadoKadeoManager.kkm.addScore(toScore.n);
					initStep(Cs.STEP_FALL);
				}
			case Cs.STEP_FALL:
				if (timer < 0)
					initStep(Cs.STEP_BLAST);
			case Cs.STEP_SPAWN_CENTER:
				if (timer < 0) {
					timer = 1;
					var d = Cs.DIR[generator.dir];
					var d2 = Cs.DIR[(generator.dir + 2) % Cs.DIR.length];
					var x = d[0] * generator.ray + d2[0] * generator.dist;
					var y = d[1] * generator.ray + d2[1] * generator.dist;

					generator.dist++;
					if (generator.dist >= generator.ray) {
						generator.dist = 0;
						generator.dir++;
						if (generator.dir < Cs.DIR.length) {
							generator.dist = 0;
						} else {
							generator.dir = 0;
							generator.ray++;
							if (generator.ray > 2)
								initStep(Cs.STEP_CONTROL);
						}
					}

					var b = new Ball(dm.attach("mcBall", DP_BALL));
					b.setPos(x, y);
					b.color = Std.int(Math.abs(x - y) % colorMax);
					b.updateSkin();
					b.vs = 0;
					b.root._xscale = 0;
					b.root._yscale = 0;
				}
			case Cs.STEP_DEATH:
				if (timer < 0) {
					KadoKadeoManager.kkm.gameOver({});
					initStep(99);
				}
			case _:
		}

		updateNextList();
		Sprite.updateAll();
	}

	function updateWheel():Void {
		var dx = Cs.mcw * 0.5 - MouseManager.getX();
		var dy = Cs.mch * 0.5 - MouseManager.getY();
		var na = Math.atan2(dy, dx);
		var da = Num.hMod(oa - na, 3.14);
		var lim = 0.3;
		speedAngle += Num.mm(-lim, da * 0.4, lim) * Timer.tmod;
		oa = na;

		if (KeyboardManager.isDown(KeyboardManager.LEFT))
			speedAngle += 0.1 * Timer.tmod;
		if (KeyboardManager.isDown(KeyboardManager.RIGHT))
			speedAngle -= 0.1 * Timer.tmod;

		speedAngle *= Math.pow(0.5, Timer.tmod);
		angle += speedAngle * Timer.tmod;
		angle = Num.hMod(angle, Math.PI);
		refreshWheelRotation();

		// for (b in bList)
		// 	untyped b.root.light._rotation = -(map._rotation + b.root._rotation);
	}

	function recordAimSample(frame:Int):Void {
		if (frame - lastAimSampleFrame >= AIM_SAMPLE_INTERVAL)
			recordAimSegment(frame);
	}

	function recordAimSegment(endFrame:Int):Void {
		if (lastAimSampleFrame < 0 || endFrame <= lastAimSampleFrame)
			return;
		// Store the target at the segment start so playback can interpolate toward it.
		KadoKadeoManager.kkm.replay.recordEvent({
			t: REPLAY_EVENT_AIM,
			a: quantizeAngle(angle),
			d: endFrame - lastAimSampleFrame,
		}, lastAimSampleFrame);
		lastAimSampleFrame = endFrame;
	}

	function recordLaunch(frame:Int):Void {
		recordAimSegment(frame);
		var launchAngle = quantizeAngle(angle);
		KadoKadeoManager.kkm.replay.recordEvent({
			t: REPLAY_EVENT_LAUNCH,
			a: launchAngle,
		}, frame);
		lastAimSampleFrame = -1;
		applyQuantizedLaunch(launchAngle);
	}

	function consumeReplayEvents():Void {
		for (event in KadoKadeoManager.kkm.replay.consumeEvents()) {
			if (event == null)
				continue;
			var type:Null<Int> = Reflect.field(event, "t");
			var encodedAngle:Null<Int> = Reflect.field(event, "a");
			if (type == null || encodedAngle == null)
				continue;
			switch (type) {
				case REPLAY_EVENT_AIM:
					var duration:Null<Int> = Reflect.field(event, "d");
					if (duration != null && duration > 0) {
						replayAimStartFrame = KadoKadeoManager.kkm.replay.getCurrentFrame();
						replayAimDuration = duration;
						replayAimStartAngle = angle;
						replayAimTargetAngle = dequantizeAngle(encodedAngle);
					}
				case REPLAY_EVENT_LAUNCH:
					pendingReplayLaunchAngle = encodedAngle;
				case _:
			}
		}
	}

	function updateReplayAim():Void {
		if (replayAimTargetAngle == null || replayAimDuration <= 0)
			return;
		var elapsed = KadoKadeoManager.kkm.replay.getCurrentFrame() - replayAimStartFrame;
		var ratio = Math.min(elapsed / replayAimDuration, 1);
		var easedRatio = 1 - Math.pow(1 - ratio, 3);
		var delta = Num.hMod(replayAimTargetAngle - replayAimStartAngle, Math.PI);
		angle = Num.hMod(replayAimStartAngle + delta * easedRatio, Math.PI);
		refreshWheelRotation();
		if (ratio >= 1)
			replayAimTargetAngle = null;
	}

	function applyQuantizedLaunch(encodedAngle:Int):Void {
		angle = dequantizeAngle(encodedAngle);
		refreshWheelRotation();
		launchBall();
	}

	function quantizeAngle(value:Float):Int {
		var normalized = Num.hMod(value, Math.PI);
		return Math.round((normalized + Math.PI) * QUANTIZED_ANGLE_MAX / (Math.PI * 2));
	}

	function dequantizeAngle(value:Int):Float {
		return value * (Math.PI * 2) / QUANTIZED_ANGLE_MAX - Math.PI;
	}

	function refreshWheelRotation():Void {
		map._rotation = -angle / (Math.PI / 180);
	}

	function updateNextList():Void {
		for (i in 0...nList.length) {
			var b = nList[i];
			var r = Cs.LAUNCH_RAY + i * (Cs.RAY + KadoKadeoManager.S(2.5)) * 2;
			var pa = Math.PI * 0.75;
			var pos = {
				x: Cs.mcw * 0.5 + Math.cos(pa) * r,
				y: Cs.mch * 0.5 + Math.sin(pa) * r
			};
			b.toward(pos, KadoKadeoManager.S(0.2), KadoKadeoManager.I(10));
		}
	}

	function launchBall():Void {
		var b = nList.shift();
		hand = new Ball(dm.attach("mcBall", DP_BALL));
		hand.color = b.color;
		hand.flIce = b.flIce;
		hand.updateSkin();

		b.kill();

		var sp = KadoKadeoManager.I(18);
		var ca = Math.cos(angle - 0.775);
		var sa = Math.sin(angle - 0.775);
		hand.x = -ca * Cs.LAUNCH_RAY;
		hand.y = -sa * Cs.LAUNCH_RAY;
		hand.vx = ca * sp;
		hand.vy = sa * sp;
		hand.flFly = true;
		hand.updatePos();
		hand.root._rotation = -map._rotation;
		initStep(Cs.STEP_FLY);

		nList.push(newBall());
	}

	function getHandPos():{x:Float, y:Float} {
		var x = -Math.cos(angle - 0.775) * Cs.LAUNCH_RAY;
		var y = -Math.sin(angle - 0.775) * Cs.LAUNCH_RAY;
		return {x: x, y: y};
	}

	function genExploList():Void {
		cleanGid();
		toScore = {n: KKApi.const(0)};
		var gList:Array<Array<Ball>> = [];
		for (x in 0...Cs.GRID_RAY * 2) {
			for (y in 0...Cs.GRID_RAY * 2) {
				var b = grid[x][y];
				if (b != null && !b.flIce && b.color != 20) {
					if (b.gid == null) {
						b.gid = gList.length;
						gList.push([b]);
					}
					for (n in 0...3) {
						var nx = x + Cs.DIR[n][0];
						var ny = y + Cs.DIR[n][1];
						var b2 = grid[nx][ny];
						if (b2 != null && b.color == b2.color && !b2.flIce && b2.color != 20) {
							if (b2.gid == null) {
								b2.gid = b.gid;
								gList[b.gid].push(b2);
							} else if (b2.gid != b.gid) {
								var kgid = b2.gid;
								var list = gList[kgid];
								for (b3 in list) {
									b3.gid = b.gid;
									gList[b.gid].push(b3);
								}
								gList[kgid] = null;
							}
						}
					}
				}
			}
		}

		exploList = new Array();
		for (g in gList) {
			if (g != null && g.length > Cs.COMBO_LIMIT - 1) {
				toScore.n = KKApi.const(KKApi.val(Cs.SCORE_COMBO_BASE) + (g.length - Cs.COMBO_LIMIT) * KKApi.val(Cs.SCORE_COMBO_BONUS) * (combo + 1));
				while (g.length > 0) {
					var b = g.pop();
					exploList.push(b);
					dm.over(b.root);
				}
			}
		}
		if (exploList.length > 0)
			stats.sc.push({c: combo, s: KKApi.val(toScore.n), t: turn});
		combo++;
	}

	function genFallList():Bool {
		cleanGid();
		stick(center);
		var flFall = false;
		var list = bList.copy();
		for (b in list) {
			if (b.gid == null) {
				b.fall();
				flFall = true;
			}
		}
		return flFall;
	}

	function cleanGid():Void {
		for (b in bList)
			b.gid = null;
	}

	function stick(b:Ball):Void {
		b.gid = 0;
		for (d in Cs.DIR) {
			var nx = b.px + d[0] + Cs.GRID_RAY;
			var ny = b.py + d[1] + Cs.GRID_RAY;
			var b2 = grid[nx][ny];
			if (b2 != null && b2.gid == null)
				stick(b2);
		}
	}

	function genCenter():Void {
		center = new Ball(dm.attach("mcBall", DP_BALL));
		center.setPos(0, 0);
		center.color = 100;
		center.wg = 1;
		center.root.gotoAndStop(20);
	}

	function setMsg(txt:String):Void {
		if (msg != null && msg._visible)
			msg.removeMovieClip();
		msg = cast gdm.empty(20);
		msg.txt = msg.initTextField("txt", {
			font: "Junegull-Regular",
			size: KadoKadeoManager.I(30),
			color: 0x000000,
		});
		msg.txt.x = KadoKadeoManager.I(80);
		msg._x = Cs.mcw;
		msg.txt.text = txt;
		msg._totalframes = 18;
		msg.removeOnFrame = 18;
		msg.play();
		var compt = 32;
		msg.onFrame.set(1, () -> msg._x = Cs.mcw);
		msg.onFrame.set(2, () -> msg._x -= KadoKadeoManager.I(34));
		msg.onFrame.set(3, () -> msg._x -= KadoKadeoManager.I(34));
		msg.onFrame.set(4, () -> msg._x -= KadoKadeoManager.I(34));
		msg.onFrame.set(5, () -> msg._x -= KadoKadeoManager.I(34));
		msg.onFrame.set(6, () -> msg._x -= KadoKadeoManager.I(34));
		msg.onFrame.set(7, () -> msg._x += KadoKadeoManager.I(2));
		msg.onFrame.set(8, () -> msg._x += KadoKadeoManager.I(2));
		msg.onFrame.set(9, () -> msg._x += KadoKadeoManager.I(2));
		msg.onFrame.set(10, () -> msg._x -= KadoKadeoManager.I(2));
		msg.onFrame.set(11, () -> msg._x -= KadoKadeoManager.I(2));
		msg.onFrame.set(12, () -> {
			if (compt-- > 0) {
				msg.gotoAndPlay(11);
			}
		});
		msg.onFrame.set(13, () -> msg._x += KadoKadeoManager.I(5));
		msg.onFrame.set(14, () -> msg._x += KadoKadeoManager.I(13));
		msg.onFrame.set(15, () -> msg._x += KadoKadeoManager.I(23));
		msg.onFrame.set(16, () -> msg._x += KadoKadeoManager.I(32));
		msg.onFrame.set(17, () -> msg._x += KadoKadeoManager.I(41));
		msg.onFrame.set(18, () -> msg._x = Cs.mcw);
	}

	public function destroy():Void {
		Cs.game = null;
	}
}
