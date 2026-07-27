package cookinglili;

import mt.bumdum.Lib.Filt;
import pixi.filters.blur.BlurFilter;
import pixi.filters.extras.GlowFilter;
import common_haxe_avm1.KKApi;
import haxe.io.UInt16Array;
import mt.Timer;
import mt.bumdum.Plasma;
import cookinglili.Level;
import cookinglili.Girl;
import pixi.core.text.Text;
import pixi.filters.colormatrix.ColorMatrixFilter;
import pixi.core.Pixi.BlendModes;
import common_haxe_avm1.MouseManager;

enum Step {
	Play;
	Resolve;
	GameOver;
}

class T_ScoreMC extends ASprite {
	public var field:Text;
	public var timer:Float;
}

typedef T_Swap = {
	pair:T_Pair,
	step:Float,
}

typedef T_LogTurn = {
	t:Float,
	dp:Int,
	sc:Int,
}

@:expose('GameCookingLili')
class Game implements kado.GameInterface {
	public static var FALL_SPEED = KadoKadeoManager.S(8);
	public static var RAISE_SPEED = KadoKadeoManager.S(12);
	public static var FALL_DELAY = 9;

	public var step:Step;
	public var dm:mt.DepthManager;
	public var fxDm:mt.DepthManager;
	public var level:Level;

	var swapPair:T_Pair;

	public var root:ASprite;
	public var swapper:ASprite;

	var falls:Int;
	var explList:Array<Token>;
	var unarmList:Array<Token>;
	var warnings:Array<Token> = [];
	var warnStep:Float;
	var raiseCpt:Int;

	public var girl:Girl;

	//	var sparkList			: Array<Spark>;
	//	var iceList				: Array<Ice>;
	public var fxList:Array<Fx>;
	public var hoverPair:T_Pair;

	var shortFxList:Array<ASprite>;
	var scoreList:Array<T_ScoreMC>;
	var swapAnim:T_Swap;
	var lastPair:T_Pair;
	var goStep:Float;
	var explTimer:Float;
	var isReplayMode:Bool;

	var plasma:Plasma;
	var fxMc:ASprite;

	var upTimer:Float;

	var log:List<T_LogTurn>;
	var currentRound:T_LogTurn;
	var time:Float;

	var warnGlow:GlowFilter;

	static public var me:Game;

	/*------------------------------------------------------------------------
		CONSTRUCTEUR
		------------------------------------------------------------------------ */
	public function new(root:ASprite, ?isReplay:Bool = false) {
		isReplayMode = isReplay;
		KadoKadeoManager.kkm.replay.init({
			recordedKeys: new UInt16Array(0),
			recordInputs: false,
			recordEvents: true,
			recordMousePosition: false,
			recordedMouseButtons: new UInt16Array(0),
		});

		this.root = root;
		me = this;
		fxList = new Array();
		shortFxList = new Array();
		scoreList = new Array();
		upTimer = 0;
		dm = new mt.DepthManager(root);
		var bg = dm.attach("bg", Cs.DP_BG);
		bg.gotoAndStop(Seed.randomVfx(bg._totalframes));
		log = new List();
		time = 0;

		plasma = new Plasma(dm.empty(Cs.DP_PLASMA), Cs.GWID, Cs.GHEI);
		plasma.filters = [new BlurFilter()];
		plasma.filters[0].blur = KadoKadeoManager.I(5);
		plasma.ct = new ColorMatrixFilter();
		// plasma.ct.matrix = [1, 1, 1, 1, 0, 0, 0, -4];
		plasma.ct.matrix = [
			1, 0, 0, 0,       0,
			0, 1, 0, 0,       0,
			0, 0, 1, 0,       0,
			0, 0, 0, 1, -4 / 255,
		];
		plasma.root.blendMode = BlendModes.ADD;
		fxMc = dm.empty(Cs.DP_FX);
		fxDm = new mt.DepthManager(fxMc);

		step = Play;

		girl = new Girl(this);

		swapper = dm.attach("swapper", Cs.DP_INTERF);
		// swapper._xscale = 100 * (Cs.TWID * 2) / 40;
		// swapper._yscale = 100 * (Cs.THEI) / 20;
		//      1
		// 50   40

		warnGlow = Type.createInstance(GlowFilter, [
			{
				distance: KadoKadeoManager.I(4),
				outerStrength: 0,
				color: 0xFF0000,
				quality: 0.5
			}
		]);

		// generation
		level = new Level();
		for (x in 0...level.map.length) {
			var col = level.map[x];
			for (y in 0...col.length) {
				if (col[y] == null) {
					continue;
				}
				col[y].attach(x, y);
			}
		}
	}

	/*------------------------------------------------------------------------
		ADD SCORE
		------------------------------------------------------------------------ */
	public function addScore(sc:KKConst, x, y) {
		currentRound.sc += KKApi.val(sc);
		KadoKadeoManager.kkm.addScore(sc);
		var mc:T_ScoreMC = cast dm.empty(Cs.DP_INTERF);
		mc._x = x;
		mc._y = y;
		mc.field = mc.initTextField("field", {
			font: "Arial Black",
			size: 30,
			color: 0xFFFFFF,
			strokeThickness: 3,
			stroke: "#000000",
		});
		mc.field.text = "" + KKApi.val(sc);
		mc.timer = 0;
		//		mc._x = Cs.GWID*0.5;
		//		mc._y = Cs.GHEI*0.5;
		//		mc._xscale = 800;
		//		mc._yscale = mc._xscale;
		//		mc.blendMode = "overlay";
		scoreList.push(mc);
	}

	/*------------------------------------------------------------------------
		EVENT: CLICK
		------------------------------------------------------------------------ */
	function onClick() {
		swapPair = hoverPair;
		if (swapPair != null && level.different(swapPair)) {
			girl.startSwap(swapPair, onSwapAnim);
			step = Resolve;
			currentRound = {
				t: time,
				dp: 0,
				sc: 0,
			}
		}
	}

	function onSwapAnim() {
		redraw();
		clearWarnings();
		explTimer = 0;
		level.swap(swapPair);
		swapAnim = {pair: swapPair, step: 0.0};
	}

	/*------------------------------------------------------------------------
		GETS THE PAIR UNDER MOUSE
		------------------------------------------------------------------------ */
	function getPair() {
		return getPairAt(MouseManager.getX(), MouseManager.getY());
	}

	function getPairAt(mx:Float, my:Float) {
		var x = Level.x_rtc(mx);
		var y = Level.y_rtc(my);
		var dx = 0;
		var dy = 0;
		var xCenter = Level.x_ctr(x) + Cs.TWID * 0.5;
		var yCenter = Level.y_ctr(y) + Cs.THEI * 0.5;
		var ang = Math.atan2(yCenter - my, xCenter - mx) * 180 / Math.PI;
		if (ang < 0) {
			ang += 360;
		}
		if (ang <= 45 || ang > 315) {
			// left
			dx = 1;
			x--;
		} else if (ang <= 135) {
			// up
			dy = 1;
			y--;
		} else if (ang <= 225) {
			// right
			dx = 1;
		} else if (ang <= 315) {
			// down
			dy = 1;
		}
		return level.getPair(x, y, dx, dy);
	}

	/*------------------------------------------------------------------------
		CHECKS BEFORE END OF ROUND
		------------------------------------------------------------------------ */
	function check() {
		var l = level.check(true);
		if (l != null) {
			currentRound.dp++;
			var lists = level.explode(l);
			explList = lists.explNow;
			unarmList = lists.explArm;
			for (token in unarmList) {
				for (i in 0...Seed.randomVfx(4) + 2) {
					var ice = new Ice(this, token.mc._x, token.mc._y);
					token.mc.ice._visible = false;
					var fx = dm.attach("fx_ice_break", Cs.DP_FX);
					fx.play();
					fx._x = token.mc._x;
					fx._y = token.mc._y;
					fx._rotation = token.mc.ice._rotation;
					shortFxList.push(fx);
					fxList.push(ice);
				}
			}
		} else {
			endRound();
		}
	}

	/*------------------------------------------------------------------------
		FX: SPARK
		------------------------------------------------------------------------ */
	function addSpark(x:Float, y:Float, id) {
		var s = new Spark(this, fxDm, x + Seed.randomVfx(Cs.TWID) * (Seed.randomVfx(2) * 2 - 1), y + Seed.randomVfx(Cs.THEI) * (Seed.randomVfx(2) * 2 - 1), id);
		fxList.push(s);
	}

	/*------------------------------------------------------------------------
		STOPS WARNING ANIMATION
		------------------------------------------------------------------------ */
	function clearWarnings() {
		for (w in warnings) {
			w.mc._x = Level.x_token(w.x);
			w.mc._y = Level.y_token(w.y);
			w.mc.filters = [];
		}
		warnings = [];
	}

	/*------------------------------------------------------------------------
		FULL REDRAW
		------------------------------------------------------------------------ */
	function redraw() {
		for (y in 0...Level.HEI) {
			for (x in 0...Level.WID) {
				var t = level.map[x][y];
				if (t == null) {
					continue;
				}
				t.mc._x = Level.x_token(t.x);
				t.mc._y = Level.y_token(t.y);
			}
		}
	}

	// *** GAME EVENTS

	/*------------------------------------------------------------------------
		EVENT: END OF EXPLOSIONS
		------------------------------------------------------------------------ */
	function onEndSwap() {
		check();
	}

	/*------------------------------------------------------------------------
		EVENT: END OF EXPLOSIONS
		------------------------------------------------------------------------ */
	function onEndExplosion() {
		falls = level.gravity();
		if (falls == 0)
			check();
	}

	/*------------------------------------------------------------------------
		EVENT: END OF FALLS
		------------------------------------------------------------------------ */
	function onFelt() {
		for (x in 0...Level.WID) {
			for (y in 0...Level.HEI) {
				var t = level.map[x][y];
				if (t != null) {
					if (t.mc._x != Level.x_token(x) || t.mc._y != Level.y_token(y)) {
						trace("invalid pos for token @ " + x + "," + y + " !");
						t.mc._alpha = 35;
					}
					if (t.fall != 0)
						trace("invalid fall value for token @ " + x + "," + y + " !");
				}
			}
		}
		check();
	}

	/*------------------------------------------------------------------------
		EVENT: LINE COMPLETLY ADDED
		------------------------------------------------------------------------ */
	function onLineAdded() {
		warnings = level.getWarnings();
		warnStep = 0;
		step = Play;
	}

	/*------------------------------------------------------------------------
		EVENT: DEATH !
		------------------------------------------------------------------------ */
	function onGameOver() {
		goStep = 0;
		/***
			// HACK
			for (i in 0...300)
				log.add({
					t	: Seed.random(10)*1.0,
					dp	: Seed.random(4)+1,
					sc	: Seed.random(9999),
				});
			/***/
		// var scores = new Array();
		// var times = new Array();
		// var depths = new Array();
		// var limit = 70;
		// for(l in log) {
		// scores.push(l.sc);
		// depths.push(l.dp);
		// times.push(Std.int(l.t));
		// if ( --limit<=0 )
		// break;
		// }
		//
		// KKApi.gameOver( {cpt:log.length, sc:scores, dp:depths, t:times} );
		KadoKadeoManager.kkm.gameOver({});
		step = GameOver;
	}

	/*------------------------------------------------------------------------
		END OF A ROUND (AFTER RESOLVE)
		------------------------------------------------------------------------ */
	function endRound() {
		upTimer = 0;
		step = Resolve;
		if (currentRound != null) {
			currentRound.t = time - currentRound.t;
			log.add(currentRound);
		}
		if (!level.addLine()) {
			onGameOver();
			return;
		}
		level.endRound();
		raiseCpt = Level.WID;
		for (x in 0...Level.WID) {
			var t = level.map[x][Level.HEI - 1];
			t.attach(x, Level.HEI - 1);
			t.mc._y += Cs.THEI;
		}
	}

	// *** UPDATES

	/*------------------------------------------------------------------------
		MAIN LOOPS
		------------------------------------------------------------------------ */
	public function update(delta:Float) {
		time += Timer.deltaT;
		for (event in KadoKadeoManager.kkm.replay.consumeEvents()) {
			applyReplayEvent(event);
		}
		if (!isReplayMode && step == Play) {
			pollLiveReplayEvents();
		}
		if (lastPair != null) {
			lastPair.t1.mc.filters = [];
			lastPair.t2.mc.filters = [];
			lastPair = null;
		}
		switch (step) {
			case Play:
				updateGame();
			case Resolve:
				updateResolve();
			case GameOver:
				updateGameOver();
			default:
				trace("unknown step");
		}
		updateFx();
	}

	/*------------------------------------------------------------------------
		FX LOOP
		------------------------------------------------------------------------ */
	function updateFx() {
		// plasma!
		fxMc.updateGraphics(1);
		plasma.drawMc(fxMc);
		plasma.update();

		// warnings
		warnStep += 0.2 * Timer.tmod;
		for (w in warnings) {
			w.mc._x = Level.x_token(w.x) + KadoKadeoManager.S(Seed.randomVfx(10) / 10) * (Seed.randomVfx(2) * 2 - 1);
			w.mc._y = Level.y_token(w.y) + KadoKadeoManager.S(Seed.randomVfx(10) / 10) * (Seed.randomVfx(2) * 2 - 1);
			warnGlow.outerStrength = KadoKadeoManager.S(Math.abs(Math.cos(warnStep)));
			w.mc.filters = [warnGlow];
		}

		// score pops
		var i = 0;
		while (i < scoreList.length) {
			var sc = scoreList[i];
			sc.timer += 0.05 * Timer.tmod;
			sc._alpha = Math.cos(Math.PI * 0.5 * sc.timer) * 100;
			sc._y -= KadoKadeoManager.S(0.5) * Timer.tmod;
			if (sc.timer >= 1) {
				sc.removeMovieClip();
				scoreList.splice(i, 1);
				i--;
			}
			i++;
		}

		// sparks
		var i = 0;
		while (i < fxList.length) {
			var fx = fxList[i];
			fx.update();
			if (fx.mc == null) {
				fxList.splice(i, 1);
				i--;
			}
			i++;
		}

		// ice
		//		i=0;
		//		while (i<iceList.length) {
		//			var ice = iceList[i];
		//			ice.update();
		//			if (ice.mc._y>=Cs.GHEI+5 ) {
		//				ice.mc.removeMovieClip();
		//				iceList.splice(i,1);
		//				i--;
		//			}
		//			i++;
		//		}

		// clean up
		i = 0;
		while (i < shortFxList.length) {
			var mc = shortFxList[i];
			if (mc._currentframe == mc._totalframes) {
				mc.removeMovieClip();
				shortFxList.splice(i, 1);
				i--;
			}
			i++;
		}
	}

	/*------------------------------------------------------------------------
		GAMEOVER LOOP
		------------------------------------------------------------------------ */
	function updateGameOver() {
		swapper._visible = false;
		var fact = 1 - Math.cos(goStep);
		for (y in 0...Level.HEI) {
			if (y / Level.HEI <= fact) {
				for (x in 0...Level.WID) {
					var token = level.map[x][y];
					if (token != null) {
						token.mc._x -= Timer.tmod * KadoKadeoManager.S(1.5 + Seed.randomVfx(3));
						token.mc._rotation -= Timer.tmod * 5;
						if (x % 3 == 0 || (x + y) % 3 == 0) {
							token.mc._y -= Timer.tmod * KadoKadeoManager.I(1);
							token.mc._rotation -= Timer.tmod * 2;
						}
						if ((x + y) % 6 == 0) {
							token.mc._x -= Timer.tmod * KadoKadeoManager.I(Seed.randomVfx(4));
						}
						token.mc._alpha -= Timer.tmod * (2 + Seed.randomVfx(6));
						if (token.mc._alpha <= 0) {
							token.mc.removeMovieClip();
							level.map[x][y] = null;
						}
					}
				}
			}
		}
		goStep += 0.05 * Timer.tmod;

		girl.update();
	}

	function updateResolve() {
		swapper._visible = false;

		// swapping
		if (swapAnim != null) {
			swapAnim.step += Timer.tmod * 0.1;
			if (swapAnim.step >= 1) {
				swapAnim.step = 1;
			}
			swapAnim.pair.t1.mc._x = Level.x_token(swapAnim.pair.x) + swapAnim.pair.dx * Cs.TWID * swapAnim.step;
			swapAnim.pair.t1.mc._y = Level.y_token(swapAnim.pair.y) + swapAnim.pair.dy * Cs.THEI * swapAnim.step;
			swapAnim.pair.t1.mc._xscale = 100 + 50 * Math.sin(swapAnim.step * Math.PI);
			swapAnim.pair.t1.mc._yscale = swapAnim.pair.t1.mc._xscale;
			swapAnim.pair.t1.mc._x -= KadoKadeoManager.I(4) * Math.sin(swapAnim.step * Math.PI);
			swapAnim.pair.t1.mc._y -= KadoKadeoManager.I(4) * Math.sin(swapAnim.step * Math.PI);
			dm.over(swapAnim.pair.t1.mc);

			swapAnim.pair.t2.mc._x = Level.x_token(swapAnim.pair.x) + swapAnim.pair.dx * Cs.TWID - swapAnim.pair.dx * Cs.TWID * swapAnim.step;
			swapAnim.pair.t2.mc._y = Level.y_token(swapAnim.pair.y) + swapAnim.pair.dy * Cs.THEI - swapAnim.pair.dy * Cs.THEI * swapAnim.step;
			swapAnim.pair.t2.mc._xscale = 100 - 50 * Math.sin(swapAnim.step * Math.PI);
			swapAnim.pair.t2.mc._yscale = swapAnim.pair.t2.mc._xscale;
			swapAnim.pair.t2.mc._x += KadoKadeoManager.I(4) * Math.sin(swapAnim.step * Math.PI);
			swapAnim.pair.t2.mc._y += KadoKadeoManager.I(4) * Math.sin(swapAnim.step * Math.PI);

			if (swapAnim.step >= 1) {
				swapAnim = null;
				onEndSwap();
			}
		}

		// explosions
		if (explTimer > 0 || explList != null && explList.length > 0) {
			var i = 0;
			while (i < explList.length) {
				var token = explList[i];
				var bx = Seed.randomVfx(5);
				var by = 5 - bx;
				token.mc.filters = [
					new GlowFilter(KadoKadeoManager.I(10), KadoKadeoManager.I(3), KadoKadeoManager.I(3), 0xffffff, 0.5),
					new GlowFilter(KadoKadeoManager.I(Seed.randomVfx(15)), KadoKadeoManager.I(3), KadoKadeoManager.I(3), 0xffffff, 0.5)
				];
				//				token.mc._alpha = 50+Seed.randomVfx(50);
				token.mc._x = Level.x_token(token.x) + KadoKadeoManager.S(Seed.randomVfx(20) / 10) * (Seed.randomVfx(2) * 2 - 1);
				token.mc._y = Level.y_token(token.y) + KadoKadeoManager.S(Seed.randomVfx(20) / 10) * (Seed.randomVfx(2) * 2 - 1);
				var chance = 4;
				if (explList.length <= 2) {
					chance = 2;
				}
				if (token.explDelay < 0) {
					token.explDelay = Seed.random(chance) + 1;
				}
				token.explDelay--;
				if (token.explDelay <= 0) {
					var exp = fxDm.attach("fx_explode", Cs.DP_FX);
					exp.play();
					exp._x = token.mc._x;
					exp._y = token.mc._y;
					exp._xscale = 100 + Seed.randomVfx(50);
					exp._yscale = exp._xscale;
					exp._rotation = Seed.randomVfx(360);
					for (i in 0...1) {
						addSpark(exp._x, exp._y, token.id);
					}
					token.mc.removeMovieClip();
					explList.splice(i, 1);
					shortFxList.push(exp);
					i--;
					if (explList.length <= 0) {
						explTimer = FALL_DELAY;
					}
				}
				i++;
			}
			if (explTimer > 0) {
				explTimer -= Timer.tmod;
				if (explTimer <= 0) {
					onEndExplosion();
				}
			}
		}

		// falls
		if (falls > 0) {
			for (x in 0...Level.WID) {
				for (y in 0...Level.HEI) {
					var token = level.map[x][y];
					if (token != null && token.fall > 0) {
						token.mc._y += FALL_SPEED;
						token.moveDist += FALL_SPEED;
						if (token.moveDist >= Cs.THEI) { // felt from 1 token height
							token.fall--;
							token.moveDist -= Cs.THEI;
							if (token.fall <= 0) {
								token.mc._y = Level.y_token(y);
								falls--;
							}
						}
					}
				}
			}
			// full redraw
			if (falls == 0) {
				onFelt();
			}
		}

		// line added
		if (raiseCpt > 0) {
			for (x in 0...Level.WID) {
				var d = KadoKadeoManager.I(2) * (Math.sin(Math.PI * x / Level.WID) + 1);
				var fl_done = false;
				for (y in 0...Level.HEI) {
					var token = level.map[x][y];
					if (token != null && token.mc._y > Level.y_token(token.y)) {
						fl_done = false;
						token.mc._y -= d;
						token.moveDist += d;
						if (token.mc != null && token.mc._y <= Level.y_token(token.y)) {
							fl_done = true;
							token.attach(token.x, token.y);
						}
					}
				}
				if (fl_done) {
					raiseCpt--;
					//					level.map[x][Level.HEI-1].attach(x,Level.HEI-1);
				}
			}
			if (raiseCpt <= 0) {
				onLineAdded();
			}
		}

		girl.update();
	}

	/*------------------------------------------------------------------------
		GAME LOOP
		------------------------------------------------------------------------ */
	function updateGame() {
		// auto up
		var t = Math.min(4, Math.max(Timer.tmod, 0.5));
		upTimer += t;
		if (upTimer >= 0.75 * KKApi.val(Cs.AUTOUP_TIMER)) {
			for (col in level.map) {
				var t = col[Level.HEI - 1];
				if (t != null) {
					t.mc._y = Level.y_token(t.y) + KadoKadeoManager.S(Seed.randomVfx(10) / 10) * (Seed.randomVfx(2) * 2 - 1);
				}
				t = col[Level.HEI - 2];
				if (t != null) {
					t.mc._y = Level.y_token(t.y) + KadoKadeoManager.S(Seed.randomVfx(6) / 10) * (Seed.randomVfx(2) * 2 - 1);
				}
			}
		}
		if (upTimer >= KKApi.val(Cs.AUTOUP_TIMER)) {
			redraw();
			endRound();
		}

		// cursor
		var p = hoverPair;
		if (p == null) {
			swapper._visible = false;
		} else {
			swapper._x = Level.x_ctr(p.x);
			swapper._y = Level.y_ctr(p.y);
			if (swapper._visible == false) {
				swapper._visible = true;
				swapper.updateState();
			}
			if (p.dx > 0) {
				swapper._x += Cs.TWID;
				swapper._y += Cs.THEI * 0.5;
				swapper._rotation = 0;
			} else {
				swapper._rotation = 90;
				swapper._x += Cs.TWID * 0.5;
				swapper._y += Cs.THEI;
			}
			p.t1.mc.filters = [
				new GlowFilter(KadoKadeoManager.I(7), KadoKadeoManager.I(7), KadoKadeoManager.I(7), 0xffffff, 0.5)
			];
			p.t2.mc.filters = [
				new GlowFilter(KadoKadeoManager.I(7), KadoKadeoManager.I(7), KadoKadeoManager.I(7), 0xffffff, 0.5)
			];
			dm.over(p.t2.mc);
			dm.over(p.t1.mc);
		}
		lastPair = p;

		// girl
		girl.update();
	}

	function pollLiveReplayEvents() {
		var pair = getPair();
		if (!samePair(pair, hoverPair)) {
			if (pair != null) {
				recordAndApplyReplayEvent({
					k: 4,
					x: pair.x,
					y: pair.y,
					dx: pair.dx,
					dy: pair.dy
				});
			} else {
				applyHoverPair(null);
			}
		} else if (pair != null) {
			applyHoverPair(pair);
		}

		if (MouseManager.isButtonJustPressed(MouseManager.BUTTON_LEFT) && hoverPair != null) {
			recordAndApplyReplayEvent({k: 5});
		}
	}

	function recordAndApplyReplayEvent(event:Dynamic) {
		KadoKadeoManager.kkm.replay.recordEvent(event, KadoKadeoManager.kkm.replay.getCurrentFrame());
		applyReplayEvent(event);
	}

	function applyReplayEvent(event:Dynamic) {
		if (event == null || step != Play) {
			return;
		}

		var kind:Null<Int> = Reflect.field(event, "k");
		if (kind == null) {
			return;
		}

		switch (kind) {
			case 4:
				var x:Null<Int> = Reflect.field(event, "x");
				var y:Null<Int> = Reflect.field(event, "y");
				var dx:Null<Int> = Reflect.field(event, "dx");
				var dy:Null<Int> = Reflect.field(event, "dy");
				if (x == null || y == null || dx == null || dy == null) {
					return;
				}
				applyHoverPair(level.getPair(x, y, dx, dy));
			case 5:
				refreshHoverPair();
				onClick();
			default:
		}
	}

	function refreshHoverPair() {
		if (hoverPair != null) {
			hoverPair = level.getPair(hoverPair.x, hoverPair.y, hoverPair.dx, hoverPair.dy);
		}
	}

	function applyHoverPair(pair:T_Pair) {
		hoverPair = pair;
	}

	function samePair(a:T_Pair, b:T_Pair) {
		if (a == null || b == null) {
			return a == b;
		}
		return a.x == b.x && a.y == b.y && a.dx == b.dx && a.dy == b.dy;
	}

	public function destroy():Void {}
}
