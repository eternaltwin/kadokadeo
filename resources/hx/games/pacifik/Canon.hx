package pacifik;

import pacifik.Anim;
import pacifik.Gfx;
import pacifik.MC.FilterDef;

class Canon {
	// null once cleaned (removed): the original keeps calling it, Flash ignores what is done on undefined
	public var mc:CanonMC;
	public var invert:Bool;
	public var cycles:Float;
	public var idx:Int;
	public var destroyed:Bool = false;
	public var startAnim:Bool;
	public var init:Bool;
	public var shield:Int;

	// GradientGlowFilter(0, 45, [0x00FF99, 0x00FF99], [0, 1], [0, 255], 4, 4, 1, 3, "outer") and DropShadowFilter(0):
	// blur 4 x 4, strength 2, black
	var glow:FilterDef;
	var ds:FilterDef;
	// DropShadowFilter(0) with a blur of 2 x 2: never used
	var game:Game;
	var locked:Bool;

	public function new(g:Game, y = 0.0, invert = false, idx:Int, shield = -1) {
		this.shield = shield;
		startAnim = false;
		init = false;
		locked = false;
		game = g;
		this.idx = idx;
		mc = game.dm.add(new CanonMC(), Const.DP_CANON);
		mc._visible = false;
		mc.y = y;
		mc._y = y;
		if (shield > 0) {
			mc.gotoAndStop(shield + 1);
			mc.smc.gotoAndStop(shield + 1);
		} else {
			mc.gotoAndStop(1);
			mc.smc.gotoAndStop(1);
		}

		this.invert = invert;
		if (invert) {
			mc._rotation = -180;
			mc.x = Const.HEIGHT + mc.width();
			mc._x = mc.x;
		} else {
			mc.x = -mc.width();
			mc._x = mc.x;
		}

		cycles = 0;
		var color = 0x00FF99;
		glow = Glow(4, 1, color, 3);
		ds = Glow(4, 2, 0x000000, 1);
	}

	public function initFire(target:Canon) {
		if (locked)
			return;
		// (if( destroyed ) true;: does nothing)

		cycles -= mt.Timer.tmod;
		if (cycles <= 0) {
			locked = true;
			var a = new MoveFireAnim(this, target);
			var me = this;
			a.onEnd = function() {
				var b = new FireAnim(me);
				b.onEnd = function() {
					me.locked = false;
					var f = KKApi.val(Const.FIRE_CYCLE) / 10;
					me.cycles = f + Seed.random(Math.ceil(f / 2));
					if (!target.destroyed) { // Si le canon ennemi n'a pas encore été détruit entre temps
						// (this canon may have been removed meanwhile: the ball starts at NaN, see getFireX)
						var c = new Ball(me.game, me.getFireX(), me.getFireY(), target);
						me.game.balls.push(c);
						#if debug
						me.game.stats.balls++;
						if (Math.isNaN(c.mc.x))
							me.game.stats.nanBalls++;
						#end
						// (the sparks are for the eye: the visual random)
						for (i in 0...15) {
							var m = me.game.dm.add(new Part("mcBallPart"), Const.DP_CANON);
							m.gotoAndStop(c.type + 1);
							m._x = me.getFireX();
							m._y = me.getFireY();
							m._rotation = (me.mc != null ? me.mc.smc._rotation : Math.NaN) - 45;
							var p = new Phys(m);
							p.timer = 10;
							var s = KKApi.val(Const.BALL_SPEED);
							var rad = m._rotation * Math.PI / 180;
							p.vx = Math.cos(rad) * s / 100 * (if (me.invert) -2 else 2);
							p.vy = Math.sin(rad) * (if (Seed.randomVfx(2) == 0) 2 else -2);
							p.vsc = 1.02;
							p.frict = 1.02;
							p.sleep = Seed.randomVfx(3);
							m.glow(Const.color(c.type), 8);
						}
					}
				}
				me.game.anim.push(b);
			};
			game.anim.push(a);
		}
	}

	public function display() {
		mc._visible = true;
	}

	public function hasShield() {
		return shield >= 0;
	}

	public function update() {
		if (mc == null)
			return;
		mc.filters = [glow, ds];
	}

	public function prepare() {
		var f = KKApi.val(Const.FIRE_CYCLE) / 10;
		cycles = f + Seed.random(Math.ceil(f / 2));
		init = true;
	}

	// (a canon removed: Flash reads undefined values, the ball and its sparks get NaN. A NaN _x / _y is ignored: they
	// stay at (0, 0), the top left corner)
	function getFireX():Float {
		if (mc == null)
			return Math.NaN;
		var rot = mc.smc._rotation * Math.PI / 180;
		if (invert)
			return mc.x - mc.smc._x - Const.q(Math.cos(rot)) * mc.smcWidth();

		return mc.x + mc.smc._x + Const.q(Math.cos(rot)) * mc.smcWidth();
	}

	function getFireY():Float {
		if (mc == null)
			return Math.NaN;
		var rot = mc.smc._rotation * Math.PI / 180;
		if (mc.smc._rotation == 0) {
			return mc._y;
		}

		if (invert)
			return mc.y - Const.q(Math.sin(rot)) * mc.smcWidth();

		return mc.y + Const.q(Math.sin(rot)) * mc.smcWidth();
	}

	public function moveX(x = 0.0) {
		if (mc == null)
			return;
		if (invert) {
			mc.x -= x;
			mc._x = mc.x;
		} else {
			mc.x += x;
			mc._x = mc.x;
		}
	}

	public function canBeTouched() {
		if (!startAnim)
			return false;
		if (!init)
			return false;
		if (destroyed)
			return false;
		return true;
	}

	public function destroy() {
		destroyed = true;

		// (the sparks are for the eye: the visual random)
		if (shield-- > 0) {
			if (invert)
				game.canon2 = idx;
			else
				game.canon1 = idx;

			for (i in 0...10) {
				var m = game.dm.add(new Part("mcCanonPart"), Const.DP_BALL);
				m.gotoAndStop(3 + shield + 1);
				m._x = mc.x;
				m._y = mc.y;
				m._rotation = Seed.randomVfx(360);
				var p = new Phys(m);
				p.timer = 20;
				var rad = m._rotation * Math.PI / 180;
				var s = KKApi.val(Const.BALL_SPEED);
				p.vx = Math.cos(rad) * s / 100 * if (invert) -3 else 3;
				p.vy = Math.sin(rad) * s / 100 * 3;
				m.glow(0xFFFFFF, 4);
			}

			return;
		}

		for (i in 0...20) {
			var m = game.dm.add(new Part("mcCanonPart"), Const.DP_BALL);
			m.gotoAndStop(Seed.randomVfx(3) + 1);
			m._x = mc.x;
			m._y = mc.y;
			m._rotation = Seed.randomVfx(360);
			var p = new Phys(m);
			p.timer = 20;
			var rad = m._rotation * Math.PI / 180;
			var s = KKApi.val(Const.BALL_SPEED);
			p.vx = Math.cos(rad) * s / 100 * if (invert) -3 else 3;
			p.vy = Math.sin(rad) * s / 100 * if (invert) -3 else 3;
			p.vr = 2;
			m.glow(0xFFFFFF, 4);
		}
	}

	public function removeMe() {
		if (shield >= 0)
			return;
		game.removeCanon(idx, invert);
	}

	public function clean() {
		if (mc != null)
			mc.removeMovieClip();
		mc = null;
	}
}
