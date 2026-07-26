package cookinglili;

import pixi.filters.extras.GlowFilter;
import mt.Timer;

enum Phase {
	Run;
	Stop;
	Break;
	Swap;
}

class Girl {
	static var BREAK_DIST = KadoKadeoManager.I(35); // 35
	static var BREAK_TIMER = 25;
	static var MAX_SPEED = KadoKadeoManager.I(15);
	static var MIN_X = KadoKadeoManager.I(35) + BREAK_DIST;
	static var MAX_X = Cs.GWID - MIN_X;
	static var SWAP_EVENT = 2; // frame id for swap callback
	static var SWAP_EVENT_FX = 6; // frame id for swap fx

	var game:Game;
	var shadow:ASprite;

	public var mc:ASprite;

	var actMC:ASprite;
	var dx:Float;
	var tx:Float;
	var delay:Float;
	var breakTimer:Float;

	public var onSwapCB:Void->Void;
	public var phase:Phase;
	public var swap:Level.T_Pair;
	public var shineCpt:Int;
	public var glowStep:Float;

	var baseGlow:GlowFilter;
	var stepGlow:GlowFilter;

	var swapTimeout:Float;

	/*------------------------------------------------------------------------
		CONSTRUCTOR
		------------------------------------------------------------------------ */
	public function new(g) {
		game = g;
		delay = 0;
		shadow = game.dm.attach("girlShadow", Cs.DP_GIRL);
		mc = game.dm.attach("girl", Cs.DP_GIRL);
		mc.play();
		mc.stopOnFrame = [152];
		mc.onFrame.set(60, function() { // End of Stand
			mc.gotoAndPlay(1);
		});
		mc.onFrame.set(86, function() { // End of Run
			mc.gotoAndPlay(61);
		});
		mc.onFrame.set(107, function() { // End of Action 1
			mc.gotoAndPlay(1);
			phase = Stop;
		});
		mc.onFrame.set(127, function() { // End of Action 2
			mc.gotoAndPlay(1);
			phase = Stop;
		});
		// mc.onFrame.set(152, function() { // End of Brake
		// 	mc.gotoAndPlay(128);
		// });

		for (i in [87, 108]) { // Action 1, Action 2
			mc.onFrame.set(i + SWAP_EVENT, function() {
				onSwap();
			});
			mc.onFrame.set(i + SWAP_EVENT_FX, function() {
				shineCpt = 10;
			});
		}
		mc._y = KadoKadeoManager.I(60);
		mc._x = Cs.GWID * 0.5;
		baseGlow = Type.createInstance(GlowFilter, [
			{
				distance: KadoKadeoManager.I(1),
				outerStrength: KadoKadeoManager.I(10),
				color: 0x8B072F,
				quality: 0.5
			}
		]);
		mc.filters = [baseGlow];
		stepGlow = Type.createInstance(GlowFilter, [
			{
				distance: KadoKadeoManager.I(3),
				outerStrength: KadoKadeoManager.I(3),
				innerStrength: 0,
				color: 0xFFFFFF,
				quality: 0.5
			}
		]);
		breakTimer = 0;
		dx = 0;
		phase = Stop;
		glowStep = 0;
	}

	/*------------------------------------------------------------------------
		STARTS SWAP ANIM
		------------------------------------------------------------------------ */
	public function startSwap(p, cb) {
		swapTimeout = 60;
		phase = Swap;
		swap = p;
		onSwapCB = cb;
		if (actMC != null) {
			actMC.removeMovieClip();
		}
		var id = if (p.dx == 0) 1 else 2;
		actMC = game.dm.attach("fx_action_" + id, Cs.DP_GIRL);
		actMC.play();
		actMC._x = mc._x;
		actMC._y = mc._y;
		actMC._xscale = mc._xscale;
	}

	function onSwap() {
		swapTimeout = 0;
		onSwapCB();
	}

	/*------------------------------------------------------------------------
		MAIN LOOP
		------------------------------------------------------------------------ */
	public function update() {
		// extra swap fx overlay
		if (actMC != null) {
			actMC._x = mc._x;
			actMC._y = mc._y;
			actMC._xscale = mc._xscale;
			if (actMC._currentframe == actMC._totalframes) {
				actMC.removeMovieClip();
				actMC = null;
			}
		}

		// glow when receiving a spark
		if (glowStep > 0) {
			glowStep -= Timer.tmod * 0.1;
			if (glowStep <= 0) {
				mc.filters = [baseGlow];
			} else {
				// untyped stepGlow.distance = KadoKadeoManager.S(glowStep * 20);
				stepGlow.outerStrength = KadoKadeoManager.S(glowStep * 2);
				mc.filters = [stepGlow, baseGlow];
				var fx = new ShineDrop(game, mc._x, mc._y - KadoKadeoManager.I(20));
				game.fxList.push(fx);
			}
		}

		// shine drops
		if (shineCpt > 0 && Seed.randomVfx(10) <= 8) {
			shineCpt--;
			var fx = new Shine(game, mc._x, mc._y - KadoKadeoManager.I(20), (mc._currentframe == 4));
			game.fxList.push(fx);
		}

		// moves
		var xm = game.hoverPair != null ? Level.x_ctr(game.hoverPair.x) : Cs.GWID * 0.5;
		var delta = xm - mc._x;
		var dist = Math.abs(delta);
		if (xm == 0)
			phase = Stop;

		if (swapTimeout > 0) {
			swapTimeout -= Timer.tmod;
			if (swapTimeout <= 0) {
				onSwap();
			}
		}

		switch (phase) {
			case Swap:
				if (mc._currentframe < 87 || mc._currentframe > 126) {
					if (swap.dx != 0) {
						mc.gotoAndPlay(108);
					} else {
						mc.gotoAndPlay(87);
					}
				}
				dx *= 0.92;

			case Stop:
				dx *= 0.92;
				if (dist > BREAK_DIST * 2) {
					phase = Run;
				}

			case Break:
				breakTimer -= Timer.tmod;
				dx *= 0.8;
				if (breakTimer <= 0) {
					dx = 0;
					if (dist <= BREAK_DIST) {
						phase = Stop;
						mc.gotoAndPlay(1);
					} else {
						phase = Run;
					}
				}

			case Run:
				if (delta < 0 && dx > -MAX_SPEED) {
					dx -= KadoKadeoManager.I(2) * Timer.tmod;
					mc.gotoAndPlay(61);
				}
				if (delta > 0 && dx < MAX_SPEED) {
					dx += KadoKadeoManager.I(2) * Timer.tmod;
					mc.gotoAndPlay(61);
				}

				if (dist <= BREAK_DIST || dx < 0 && mc._x < xm || dx > 0 && mc._x > xm || dx < 0 && mc._x < MIN_X || dx > 0 && mc._x > MAX_X) {
					breakTimer = BREAK_TIMER;
					phase = Break;
					mc.gotoAndPlay(128);
				}

				if (dx < 0) {
					mc._xscale = -100;
				}
				if (dx > 0) {
					mc._xscale = 100;
				}
			default:
				trace("invalid phase for girl");
		}

		if (breakTimer <= 0) {}

		if (breakTimer > 0) {}
		mc._x += dx * 0.5;
		shadow._x = mc._x + KadoKadeoManager.I(2);
		shadow._y = mc._y;
		if (mc._xscale <= 0)
			shadow._x -= KadoKadeoManager.I(4);
	}
}
