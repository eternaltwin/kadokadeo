package safari;

import common_haxe_avm1.KeyboardManager;
import pixi.core.graphics.Graphics;
import pixi.filters.colormatrix.ColorMatrixFilter;

// Data of the original
class Data {
	// *** DEPTHS
	public static inline var DP_BG = 0;
	public static inline var DP_SHADOW = 1;
	public static inline var DP_CAR_BODY = 2;
	public static inline var DP_CAR_DRAW = 3;
	public static inline var DP_CAR_WHEEL = 4;
	public static inline var DP_TARGET = 5;
	public static inline var DP_FX = 6;
	public static inline var DP_INTERF = 7;

	public static inline var DRONE = 0;
	public static inline var BIG = 1;
	public static inline var WARPER = 2;
	public static inline var OPTION = 3;

	public static inline var PROBA_SPAWN = 100;
	public static inline var PROBA_BIG = 35;
	public static inline var PROBA_DRONE = 900;
	public static inline var PROBA_WARPER = 100;

	// *** SCROLLER
	public static inline var SLICES = 26;
	public static inline var SLICE_HEIGHT = 2;
	public static inline var MIN_SPEED = 3;
	public static inline var SCROLLER_SPEED = 19.0;

	public static inline var GROUND_Y = 280;
	public static inline var GROUND_SPEED = 0.9;

	// *** GAMEPLAY
	public static inline var GRAVITY = 2;
	public static inline var COMBO_TIMER = 30;
	public static inline var LEVELING_SPEED = 0.0010;
	public static inline var MAX_WARP = 8;
	public static inline var SHOCKWAVE_FACTOR = 3;
	public static inline var MIN_TARGETS = 2;
	public static inline var MAX_MISSES = 3;
	public static inline var MULTI_TIMER = 300;

	// *** CAR
	public static inline var CAR_X = 190;
	public static inline var CAR_WIDTH = 50;
	public static inline var BODY_Y = 15;
	public static inline var WHEEL_SCALE = 100;
	public static inline var CANON_X = -10;
	public static inline var CANON_Y = -55;

	public static inline var AMMO = 12;
	public static inline var AMMO_X = 5;
	public static inline var AMMO_Y = 295;
	public static inline var AMMO_WIDTH = 7;
	public static inline var RELOAD = 1.5;
	public static inline var HEAT = 3;

	// *** FX
	public static inline var SMOKE = 1;
	public static inline var EXPLOSION = 2;
	public static inline var SHOCKWAVE = 3;
	public static inline var GIB_MISC = 1;
	public static inline var GIB_DRONE = 2;
	public static inline var GIB_BIG = 3;
	public static inline var GIB_WARPER = 4;
	public static inline var GIB_OPTION = 5;

	public static inline var C25 = 25;
}

// ---------------------------------------------------------------- Entity
// A MovieClip of the original with its class: the clip of the SWF is `skin`. Its position (x, y) and alpha of the
// code are px, py, alph (x, y, alpha are the properties of the display object).
class Entity extends ASprite {
	static var ZERO:Array<Float> = [0, 0, 0, 0];
	static var filtersOf:Map<Int, ColorMatrixFilter> = new Map();

	public var game:Game;
	public var skin:Clip;

	public var px:Float;
	public var py:Float;
	public var radius:Float;
	public var shockFactor:Float;
	public var alph:Float;
	public var weight:Float;

	public var fl_kill:Bool;
	public var fl_destroy:Bool;
	public var fl_count:Bool;
	public var fl_useless:Bool;

	public var mover:Mover;

	var light:Float;
	var lightTimer:Float;

	var lifeTimer:Null<Float>;

	public var removed(default, null):Bool;

	public function new(clip:String) {
		super();
		skin = new Clip(clip);
		addChild(skin);
		removed = false;
		px = 0;
		py = 0;
		fl_destroy = false;
		fl_kill = false;
		fl_count = false;
		fl_useless = false;
		alph = 100;
		weight = 1.0;
		shockFactor = 1.0;
		lifeTimer = null;
		lightTimer = 0;
		setLuminosity(0);
	}

	// INITIALISATION
	public function init(g:Game, x:Float, y:Float) {
		game = g;
		this.px = x;
		this.py = y;
		radius = getW() / 2;
		register();
		endStep();
		updateState();
	}

	// MISE EN LISTE
	function register() {
		game.entityList.push(this);
		if (fl_count)
			game.targets++;
	}

	public static function clearFilters() {
		filtersOf = new Map();
	}

	// new Color(mc).setTransform: the same offset on red, green and blue (multiplied by 100%)
	public static function colorOf(mc:ASprite, offset:Float) {
		if (mc == null)
			return;
		var o = Std.int(offset);
		if (o == 0) {
			mc.filters = null;
			return;
		}
		var f = filtersOf.get(o);
		if (f == null) {
			f = new ColorMatrixFilter();
			var v = o / 255;
			f.matrix = [1, 0, 0, 0, v, 0, 1, 0, 0, v, 0, 0, 1, 0, v, 0, 0, 0, 1, 0];
			filtersOf.set(o, f);
		}
		mc.filters = [f];
	}

	// DÉFINI LA LUMINOSITÉ DE L'ENTITÉ
	public function setLuminosity(offset:Float) {
		colorOf(this, offset);
		light = offset;
		if (light > 0)
			lightTimer = 2;
	}

	// DESTRUCTION
	public function kill() {
		if (removed)
			return;
		if (fl_count) {
			game.targets--;
			fl_count = false;
		}
		removed = true;
		removeMovieClip();
	}

	// EVENT: CRASH AU SOL
	public function onCrash() {
		_rotation = Seed.randomVfx(360);
		lifeTimer = 50;
	}

	// UPDATE GRAPHIQUE
	public function endStep() {
		_x = px;
		_y = py;
		_alpha = alph;
	}

	// MAIN
	public function step() {
		if (mover != null)
			mover.update();
		if (removed)
			return;

		if (lightTimer > 0) {
			lightTimer -= Timer.tmod;
			if (lightTimer <= 0)
				setLuminosity(0);
		}

		if (lifeTimer != null) {
			lifeTimer -= Timer.tmod;
			if (lifeTimer <= 0) {
				alph -= Timer.tmod;
				if (alph <= 0)
					kill();
			}
		}
	}

	public function gotoAndStopSkin(f:Int) {
		skin.gotoAndStop(f);
	}

	// _width / _height of the clip (bounds of the SWF shapes of its frame, scaled and rotated like Flash)
	function boundsKey():String {
		return null;
	}

	function localBounds():Array<Float> {
		var k = boundsKey();
		var b = k != null ? Art.BOUNDS.get(k) : null;
		return b != null ? b : ZERO;
	}

	function aabb(w:Bool):Float {
		var b = localBounds();
		var sx = _xscale / 100;
		var sy = _yscale / 100;
		var r = _rotation * Math.PI / 180;
		var c = Math.cos(r);
		var s = Math.sin(r);
		var x0 = 1e9, x1 = -1e9, y0 = 1e9, y1 = -1e9;
		for (i in 0...4) {
			var lx = (i & 1 == 0 ? b[0] : b[2]) * sx;
			var ly = (i & 2 == 0 ? b[1] : b[3]) * sy;
			var gx = lx * c - ly * s;
			var gy = lx * s + ly * c;
			if (gx < x0)
				x0 = gx;
			if (gx > x1)
				x1 = gx;
			if (gy < y0)
				y0 = gy;
			if (gy > y1)
				y1 = gy;
		}
		return w ? Cs.qt(x1 - x0) : Cs.qt(y1 - y0);
	}

	public function getW():Float {
		return aabb(true);
	}

	public function getH():Float {
		return aabb(false);
	}

	// _width = w (_xscale so that the clip is w wide)
	public function setW(w:Float) {
		var b = localBounds();
		if (b[2] - b[0] > 0)
			_xscale = w / (b[2] - b[0]) * 100;
	}

	public function setH(h:Float) {
		var b = localBounds();
		if (b[3] - b[1] > 0)
			_yscale = h / (b[3] - b[1]) * 100;
	}
}

// ---------------------------------------------------------------- Target
class Target extends Entity {
	var energy:Float;
	var baseEnergy:Float;

	public var bonus:Null<Int>;

	var delayedHit:Array<{timer:Float, power:Float}>;

	var shadow:Clip;
	var shadowY:Float;

	var targetId:Null<Int>;

	public function new(clip:String) {
		super(clip);
		baseEnergy = 1;
		bonus = 0;
		fl_count = true;
		delayedHit = [];
		shadowY = Seed.randomVfx(500) / 100;
	}

	override public function init(g:Game, x:Float, y:Float) {
		shadow = g.depthMan.add(new Clip("shadow"), Data.DP_SHADOW);
		super.init(g, x, y);
		initTarget();
		skin.stop();
		endStep();
		updateState();
		shadow.updateState();
	}

	override function boundsKey():String {
		return skin.clipName + skin.frame;
	}

	// INITIALISATION SPÉCIFIQUE
	function initTarget() {
		energy = baseEnergy;
	}

	// DÉTRUIT
	function explode() {
		if (fl_kill)
			return;
		if (fl_count) {
			game.targets--;
			fl_count = false;
		}

		setLuminosity(-70);
		game.kills++;
		if (bonus != null)
			game.getBonus(bonus, null, px, py - 10);
		fl_kill = true;
		mover = new Death(this);
		shockwave();
	}

	// TOUCHÉ
	public function hit(damage:Float) {
		energy -= Math.max(1, damage);

		var n = 2;
		if (game.fl_fast)
			n = 3;

		if (Seed.randomVfx(n) == 0)
			Gib.attach(game, Data.GIB_MISC, null, px, py);
		if (energy <= 0)
			explode();
		else
			setLuminosity(255);
	}

	// ONDE DE CHOC D'EXPLOSION
	function shockwave() {
		var shockRadius = radius * Data.SHOCKWAVE_FACTOR * shockFactor;
		var fx = Instant.attach(game, px, py, 3);
		fx.mover = null;
		fx.setW(shockRadius * 2);
		fx.setH(fx.getW());
		fx.updateState();

		for (e in game.entityList) {
			if (!e.fl_kill && !e.removed && Std.isOfType(e, Target)) {
				var dist = Math.sqrt((px - e.px) * (px - e.px) + (py - e.py) * (py - e.py));
				if (dist <= shockRadius)
					(cast e : Target).delayedHit.push({
						timer: Seed.random(40) / 10 + 2,
						power: baseEnergy
					});
			}
		}
	}

	// EXPLOSION DE TOUTES LES PARTIES
	function explodeFullGibs(id:Int) {
		skin.gotoAndStop(2);
		var fx = Gib.attach(game, id, 1, px, py);
		var n = fx.sub != null ? fx.sub._totalframes : 1;
		if (game.fl_fast)
			n = Math.floor(n * 0.5);
		for (i in 2...n)
			Gib.attach(game, id, i, px, py);
	}

	// FUITE
	function flee() {
		if (targetId != null)
			game.miss(targetId);
		kill();
	}

	// DESTRUCTION
	override public function kill() {
		if (shadow != null)
			shadow.removeMovieClip();
		super.kill();
	}

	// MISE À JOUR GRAPHIQUE
	override public function endStep() {
		super.endStep();
		if (shadow == null)
			return;
		shadow._x = px;
		shadow._y = shadowY + Data.GROUND_Y - 5;
		var s = Math.max(0.5, 1 - ((shadow._y - py) / 300));
		shadow._yscale = 7;
		shadow._xscale = radius * 2 * s;
	}

	// MAIN
	override public function step() {
		super.step();
		if (removed)
			return;

		// Sortie
		if (px >= 310 + getW() && !fl_kill) {
			flee();
			return;
		}
		if (px <= -getW() && fl_kill) {
			kill();
			return;
		}

		// Hits en décalé
		var i = 0;
		while (i < delayedHit.length) {
			var h = delayedHit[i];
			h.timer -= Timer.tmod;
			if (h.timer <= 0) {
				hit(h.power);
				delayedHit.splice(i, 1);
				i--;
			}
			i++;
		}
	}
}

class Drone extends Target {
	var flame:Clip;

	public function new() {
		super("drone");
		baseEnergy = 1;
		bonus = 50;
		targetId = Data.DRONE;
		flame = skin.getClip("flame");
		if (flame != null)
			flame.scripted = true;
	}

	override function initTarget() {
		super.initTarget();
		mover = new Curves(this);
		radius = 18;
	}

	override function explode() {
		super.explode();
		if (flame != null)
			flame._visible = false;
	}

	override public function onCrash() {
		super.onCrash();
		explodeFullGibs(Data.GIB_DRONE);
	}

	// the flame (scaled by the code) is in the bounds of the drone while it flies
	override function localBounds():Array<Float> {
		var b = super.localBounds();
		if (skin.frame != 1 || flame == null || !flame._visible)
			return b;
		var f = Art.BOUNDS.get("flame");
		var s = flame._xscale / 100;
		var o = Art.FLAME_POS;
		return [
			Math.min(b[0], o[0] + f[0] * s),
			Math.min(b[1], o[1] + f[1]),
			Math.max(b[2], o[0] + f[2] * s),
			Math.max(b[3], o[1] + f[3])
		];
	}

	override public function endStep() {
		super.endStep();
		// (before initTarget there is no mover yet: NaN in Flash, the scale does not change)
		if (!fl_kill && flame != null && Std.isOfType(mover, Curves)) {
			var c:Curves = cast mover;
			if (c.amp != 0) {
				var ratio = (py - c.baseY) / c.amp;
				flame._xscale = 20 + 30 * Math.abs(ratio);
			}
		}
	}

	public static function attach(g:Game, x:Float, y:Float) {
		var e = g.depthMan.add(new Drone(), Data.DP_TARGET);
		e.init(g, x, y);
	}
}

class Big extends Target {
	public function new() {
		super("bigUFO");
		baseEnergy = 15;
		bonus = 500;
		targetId = Data.BIG;
	}

	override function initTarget() {
		super.initTarget();
		var c = new Curves(this);
		mover = c;
		c.amp = 10;
		mover.dx = Seed.random(200) / 100 + 1;
		radius = 28;
		shockFactor = 1.5;
	}

	override public function onCrash() {
		super.onCrash();
		explodeFullGibs(Data.GIB_BIG);
		skin.gotoAndStop(2);
	}

	public static function attach(g:Game, x:Float, y:Float) {
		var e = g.depthMan.add(new Big(), Data.DP_TARGET);
		e.init(g, x, y);
	}
}

class Warper extends Target {
	public function new() {
		super("warper");
		baseEnergy = 2;
		bonus = 100;
		shockFactor = 1.5;
		targetId = Data.WARPER;
	}

	override function initTarget() {
		super.initTarget();
		mover = new Warp(this);
		radius = 19;
	}

	override public function onCrash() {
		super.onCrash();
		explodeFullGibs(Data.GIB_WARPER);
	}

	public static function attach(g:Game, x:Float, y:Float) {
		var e = g.depthMan.add(new Warper(), Data.DP_TARGET);
		e.init(g, x, y);
	}
}

class Option extends Target {
	public function new() {
		super("option");
		baseEnergy = 1;
		bonus = null;
	}

	override function initTarget() {
		super.initTarget();
		mover = new Linear(this);
		radius = 18;
	}

	override function explode() {
		if (fl_kill)
			return;
		game.multi++;
		game.multiTimer += Data.MULTI_TIMER;
		var fx = game.depthMan.add(new Game.DisplayBonus(" x" + game.multi + " "), Data.DP_FX);
		fx._x = px;
		fx._y = py;
		fx.updateState();
		game.anims.push(fx);

		super.explode();
	}

	override public function onCrash() {
		super.onCrash();
		explodeFullGibs(Data.GIB_OPTION);
	}

	public static function attach(g:Game, x:Float, y:Float) {
		var e = g.depthMan.add(new Option(), Data.DP_TARGET);
		e.init(g, x, y);
	}
}

// ---------------------------------------------------------------- Fx
class Fx extends Entity {
	public function new(clip:String) {
		super(clip);
		fl_kill = true;
		fl_useless = true;
	}

	override public function step() {
		super.step();
		if (removed)
			return;
		alph -= 2 * Timer.tmod;
		if (alph <= 0)
			kill();
	}
}

class Cartridge extends Fx {
	public function new() {
		super("cartridge");
	}

	override function boundsKey():String {
		return "cartridge1";
	}

	override public function init(g:Game, x:Float, y:Float) {
		super.init(g, x, y);
		mover = new Fall(this);
		mover.dx = -Seed.randomVfx(200) / 10;
		mover.dy = -Seed.randomVfx(100) / 10 - 4;
		mover.dr = Seed.randomVfx(50) / 10 + 5;
		_rotation = Seed.randomVfx(360);
		updateState();
	}

	public static function attach(g:Game, x:Float, y:Float):Cartridge {
		var e = g.depthMan.add(new Cartridge(), Data.DP_FX);
		e.init(g, x, y);
		return e;
	}
}

class Gib extends Fx {
	public var sub(get, never):Clip;

	function get_sub():Clip {
		return skin.getClip("sub");
	}

	public function new() {
		super("gib");
	}

	override function boundsKey():String {
		var s = sub;
		return "gib" + skin.frame + "_" + (s != null ? s.frame : 1);
	}

	override public function init(g:Game, x:Float, y:Float) {
		super.init(g, x, y);
		mover = new Fall(this);
		mover.dx = -Seed.randomVfx(150) / 10;
		mover.dy = -Seed.randomVfx(100) / 10 - 5;
		mover.dr = -Seed.randomVfx(50) / 10 - 5;
		_xscale = Seed.randomVfx(50) + 50;
		_yscale = _xscale;
		_rotation = Seed.randomVfx(360);
		updateState();
	}

	// modifie le skin
	public function setSkin(frame:Int, subFrame:Null<Int>) {
		skin.gotoAndStop(frame);
		var s = sub;
		if (s == null)
			return;
		if (subFrame == null)
			s.gotoAndStop(Seed.randomVfx(s._totalframes) + 1);
		else
			s.gotoAndStop(subFrame);
	}

	public static function attach(g:Game, frame:Int, subFrame:Null<Int>, x:Float, y:Float):Gib {
		var e = g.depthMan.add(new Gib(), Data.DP_FX);
		e.init(g, x, y);
		e.setSkin(frame, subFrame);
		return e;
	}
}

class Instant extends Fx {
	public function new() {
		super("instantFx");
	}

	function sub():Clip {
		return skin.getClip("sub");
	}

	override function boundsKey():String {
		var s = sub();
		return "instantFx" + skin.frame + "_" + (s != null ? s.frame : 1);
	}

	override public function init(g:Game, x:Float, y:Float) {
		super.init(g, x, y);
		skin.stop();
		mover = new Mover(this);
		mover.dx = -game.scroller.speed * 0.5;
	}

	public static function attach(g:Game, x:Float, y:Float, frame:Int):Instant {
		var e = g.depthMan.add(new Instant(), Data.DP_FX);
		e.init(g, x, y);
		e.skin.gotoAndStop(frame);
		return e;
	}

	// ALTÉRATIONS ALÉATOIRES
	public function randomize() {
		randomizeScale();
		randomizeRotation();
	}

	public function randomizeScale() {
		_xscale = Seed.randomVfx(50) + 50;
		_yscale = _xscale;
		updateState();
	}

	public function randomizeRotation() {
		_rotation = Seed.randomVfx(360);
		updateState();
	}

	override public function step() {
		super.step();
		if (removed)
			return;
		var s = sub();
		if (s == null)
			return;
		if (s._currentframe == s._totalframes) {
			kill();
			return;
		}
		s.nextFrame();
		if (game.fl_fast)
			s.nextFrame();
	}
}

// ---------------------------------------------------------------- movers
class Mover {
	var e:Entity;

	public var dx:Float;
	public var dy:Float;
	public var dr:Float;

	public function new(e:Entity) {
		this.e = e;
		dx = 0;
		dy = 0;
		dr = 0;
	}

	// EVENT: SOL
	function onHitGround() {
		dy = -dy * 0.6;
		e.py = Data.GROUND_Y - e.getH() / 2;
	}

	public function update() {
		e.px += dx * Timer.tmod;
		e.py += dy * Timer.tmod;
		e._rotation += dr * Timer.tmod;

		if (e.py + e.radius / 2 >= Data.GROUND_Y && dy > 0)
			onHitGround();
	}
}

class Curves extends Mover {
	public var baseY:Float;
	public var amp:Float;

	public function new(e:Entity) {
		super(e);
		dx = Seed.random(15) / 10 + 1 + Math.min(2.5, e.game.level * 0.5);
		baseY = e.py;
		amp = Math.min(2.5, 0.5 * e.game.level) * (Seed.random(30) + 10);
	}

	override public function update() {
		super.update();
		e.py = Cs.cos(e.px * 0.03) * amp + baseY;
	}
}

class Death extends Mover {
	var fl_fly:Bool;

	public function new(e:Entity) {
		super(e);
		dx += 5;
		fl_fly = true;
		var fx = Instant.attach(e.game, e.px + 15, e.py, Data.EXPLOSION);
		fx.randomizeRotation();
		fx._xscale = 70;
		fx._yscale = fx._xscale;
		fx.updateState();
	}

	override function onHitGround() {
		dy = -Math.abs(dy * 0.9);
		e.py = Data.GROUND_Y - e.getH() / 2;

		// Destruction immédiate pour le gameover
		if (e.game.fl_gameOver) {
			var fx = Instant.attach(e.game, e.px, e.py, Data.EXPLOSION);
			fx.randomizeRotation();
			fx._xscale = 60;
			fx._yscale = fx._xscale;
			fx.updateState();
			e.kill();
		}

		if (fl_fly) {
			// Crash
			fl_fly = false;
			dx -= e.game.scroller.speed * Data.GROUND_SPEED;
			dy = -Seed.randomVfx(10) - 2;
			var s = Math.round(e.game.scroller.speed);
			dr = -(Seed.randomVfx(s) + s * 1.5) * Timer.tmod;
			if (!e.removed)
				e.onCrash();
		} else {
			dx -= (dx + e.game.scroller.speed * Data.GROUND_SPEED) * 0.8;
		}
	}

	override public function update() {
		if (fl_fly) {
			if (Seed.randomVfx(2) == 0) {
				// Fumée
				var fx = Instant.attach(e.game, e.px + Seed.randomVfx(30) / 10, e.py + Seed.randomVfx(30) / 10, Data.SMOKE);
				fx.randomize();
			}
			dy += 0.4 * e.weight * Timer.tmod;
			dr = (Seed.randomVfx(3) + 2) * Timer.tmod;
		} else {
			// Roule sous la voiture
			var car = e.game.car;
			if (e.px >= car.x + Data.CAR_WIDTH && e.px <= car.x + Data.CAR_WIDTH * 1.5) {
				var h = e.radius * (0.6 + Seed.randomVfx(30) / 100);
				car.jump((Seed.randomVfx(2) * 2 - 1) * Seed.randomVfx(30) / 10, -Math.min(15, h));
				e.py = Data.GROUND_Y - e.getH() / 2;
				dy = 0;
			}
			dr *= Math.pow(0.9, Timer.tmod);
			dy += Data.GRAVITY * e.weight * Timer.tmod;
		}
		super.update();
	}
}

class Fall extends Mover {
	public function new(e:Entity) {
		super(e);
		dx += 5;
	}

	override function onHitGround() {
		super.onHitGround();
		var s = Math.round(e.game.scroller.speed);
		dr = -(Seed.randomVfx(s) + s * 1.5) * Timer.tmod;
		dx -= (dx + e.game.scroller.speed * Data.GROUND_SPEED) * 0.5;
	}

	override public function update() {
		super.update();
		dy += Data.GRAVITY * e.weight * Timer.tmod;
	}
}

class Linear extends Mover {
	public function new(e:Entity) {
		super(e);
		dx = Seed.random(20) / 10 + 1 + Math.min(6, e.game.level);
	}
}

class Warp extends Mover {
	var tx:Float;
	var ty:Float;
	var ang:Float;
	var speed:Float;

	var timer:Float;
	var warps:Int;

	public function new(e:Entity) {
		super(e);
		speed = 25;
		timer = 0.1;
		warps = 0;
		tx = 0;
		ty = 0;
		ang = 0;
	}

	// VISER
	function aim(x:Float, y:Float) {
		tx = x;
		ty = y;
		ang = Cs.atan2(y - e.py, x - e.px);
		dx = Cs.cos(ang) * speed;
		dy = Cs.sin(ang) * speed;
		e.alph = 50;
		warps++;
	}

	// ARRÊT ET ATTENTE
	function halt() {
		timer = 70 * Math.max(0.6, 1.5 * 1 / e.game.level);
		e.alph = 100;
	}

	override public function update() {
		if (timer > 0) {
			dx *= Math.pow(0.5, Timer.tmod);
			dy *= Math.pow(0.5, Timer.tmod);
			timer -= Timer.tmod;
			if (timer <= 0) {
				if (warps >= Data.MAX_WARP)
					aim(350, e.py);
				else
					aim(Seed.random(240) + 30, Seed.random(170) + 40);
				timer = 0;
			}
		}

		e._rotation = 3 * dx;
		super.update();

		// Point dépassé
		if (timer == 0) {
			if (Math.abs(Cs.atan2(ty - e.py, tx - e.px) - ang) >= 1.57)
				halt();
		}
	}
}

// ---------------------------------------------------------------- Car
class Car {
	// empty clips l, r, m of carBody: the fixings of the springs
	static var FIX_L = [-21.75, -9.4];
	static var FIX_R = [20.95, -9.4];
	static var FIX_M = [0.05, -0.85];

	var game:Game;

	public var x:Float;
	public var y:Float;

	var width:Float;

	public var dx:Float;
	public var dy:Float;

	public var left:Clip;
	public var right:Clip;
	public var body:Clip;

	var shadow:Clip;
	var draw:CarDraw;
	var wheelH:Float;

	var elastX:Float;
	var elastY:Float;

	public var stableBodyY:Float;

	var fl_stable:Bool;
	var fl_inGame:Bool;
	var fl_shoot:Bool;

	public function new(g:Game) {
		game = g;
		x = -100;
		y = Data.GROUND_Y;

		dx = 0;
		dy = 0;
		width = Data.CAR_WIDTH;
		fl_stable = true;
		fl_inGame = false;
		fl_shoot = false;

		elastX = 0;
		elastY = 0;
		stableBodyY = Data.BODY_Y;

		// Corps
		body = g.depthMan.add(new Clip("carBody"), Data.DP_CAR_BODY);
		body._x = x + width / 2;
		body._y = Data.GROUND_Y - stableBodyY;

		var gat = body.getClip("gat");
		gat.stop();
		var canon = gat.getClip("canon");
		if (canon != null) {
			canon.scripted = true;
			canon._rotation = -75;
		}

		// Roues
		left = g.depthMan.add(new Clip("wheel"), Data.DP_CAR_WHEEL);
		right = g.depthMan.add(new Clip("wheel"), Data.DP_CAR_WHEEL);
		for (w in [left, right]) {
			var s = w.getClip("sub");
			s.scripted = true;
			s._rotation = Seed.randomVfx(360);
			w._xscale = Data.WHEEL_SCALE;
			w._yscale = w._xscale;
		}
		var wb = Art.BOUNDS.get("wheel1");
		wheelH = (wb[3] - wb[1]) * Data.WHEEL_SCALE / 100;

		// Ombre
		shadow = game.depthMan.add(new Clip("shadow"), Data.DP_SHADOW);

		draw = game.depthMan.add(new CarDraw(this), Data.DP_CAR_DRAW);
		endUpdate();
		for (m in [body, left, right, shadow])
			m.updateState();
	}

	// ARRIVÉE EN JEU !
	public function enterGame() {
		// Saut
		x = -70;
		jump(9, -25);

		// Débris
		for (i in 0...15) {
			var fx = Gib.attach(game, Data.GIB_DRONE, null, -Seed.randomVfx(50), Seed.randomVfx(50) + 150);
			fx.mover.dx = Math.abs(dx) * (0.5 + Seed.randomVfx(100) / 100);
		}
		for (i in 0...7) {
			var fx = Gib.attach(game, Data.GIB_MISC, null, -Seed.randomVfx(50), Seed.randomVfx(50) + 150);
			fx.mover.dx = Math.abs(dx) * (0.3 + Seed.randomVfx(50) / 100);
		}

		fl_inGame = true;
	}

	// SAUT
	public function jump(dx:Float, dy:Float) {
		if (!fl_stable || game.fl_gameOver)
			return;

		this.dx = dx;
		this.dy = dy;
		fl_stable = false;
	}

	// ATTERRISSAGE
	function land() {
		fl_stable = true;
		dy = 0;
		y = Data.GROUND_Y;
	}

	// ANIM DE TIR
	public function shoot() {
		fl_shoot = true;
	}

	public function stopShoot() {
		fl_shoot = false;
	}

	// TRACÉ DES FIXATIONS (the points of the body, from the shown position of the body and the wheels)
	public function fixings(bx:Float, by:Float, brot:Float):Array<Array<Float>> {
		var out = [];
		for (p in [FIX_L, FIX_R, FIX_M]) {
			var dist = Math.sqrt(p[0] * p[0] + p[1] * p[1]);
			var ang = Math.atan2(p[1], p[0]) + brot;
			out.push([bx + Math.cos(ang) * dist, by + Math.sin(ang) * dist]);
		}
		return out;
	}

	public function wheelTop():Float {
		return wheelH / 2;
	}

	// UPDATE GRAPHIQUE
	function endUpdate() {
		var speed = game.scroller.speed;

		// Placement des parties
		left._x = x;
		right._x = x + width;
		if (fl_stable) {
			left._y = y - Seed.randomVfx(Math.round(Math.min(8, speed * 0.5)));
			right._y = y - Seed.randomVfx(Math.round(Math.min(8, speed * 0.5)));
		} else {
			left._y = y;
			right._y = y;
		}

		// Elasticité
		elastX = (left._x - speed * 0.3 - body._x + width / 2 + 5) * 0.2 + 0.8 * elastX;
		elastY = (left._y - body._y) * 0.35 + 0.65 * elastY;
		body._x += elastX;
		body._y += elastY - stableBodyY;
		body._y = Math.min(Data.GROUND_Y - stableBodyY * 0.8, body._y);
		body._rotation = (left._x - speed - body._x + width / 2) * 0.5;

		// Rotations roues
		var wheelSpeed = game.scroller.speed * 2.3 * Timer.tmod;
		for (w in [left, right]) {
			var s = w.getClip("sub");
			s.gotoAndStop(wheelSpeed >= 30 ? 2 : 1);
			s._rotation += wheelSpeed;
		}

		// Canon
		if (game.fl_gameRunning) {
			var tx = game.cross._x;
			var ty = game.cross._y;
			var ang = Math.atan2(Data.CANON_Y + y - ty, Data.CANON_X + x - tx);
			if (ang > 0) {
				var gat = body.getClip("gat");
				var canon = gat.getClip("canon");
				if (canon != null)
					canon._rotation = ang * 180 / Math.PI - 90;
				gat.gotoAndStop(Math.round(Math.min(1, ang / Math.PI) * gat._totalframes));
			}
		}

		// Ombre
		shadow._x = body._x;
		shadow._y = Data.GROUND_Y - 5;
		shadow._yscale = 7;
		shadow._xscale = Data.CAR_WIDTH * 1.5;
	}

	// MAIN
	public function update() {
		var gat = body.getClip("gat");
		var f = fl_shoot ? 2 : 1;
		for (n in ["canon", "s1", "s2", "s3", "s4"]) {
			var c = gat.getClip(n);
			if (c != null)
				c.gotoAndStop(f);
		}

		if (fl_inGame) {
			if (!fl_stable) {
				// Gravité
				dy += Data.GRAVITY * Timer.tmod;
			} else {
				// Recentrage
				if (!game.fl_gameOver) {
					if (x > Data.CAR_X)
						dx -= 1.5 * Timer.tmod;
					if (x < Data.CAR_X)
						dx += 1.5 * Timer.tmod;
					if (Math.abs(dx) <= 0.7 && Math.abs(x - Data.CAR_X) <= 4) {
						x = Data.CAR_X;
						dx = 0;
					}
				}
			}

			// Frictions
			if (fl_stable) {
				if (Math.abs(x - Data.CAR_X) <= 30)
					dx *= Math.pow(0.85, Timer.tmod);
				else
					dx *= Math.pow(0.6, Timer.tmod);
			}

			x += dx * Timer.tmod;
			y += dy * Timer.tmod;

			if (!fl_stable && y >= Data.GROUND_Y)
				land();
		}

		endUpdate();
	}
}

// the lines between the body and the wheels (Car.redraw), drawn from the shown (interpolated) positions
class CarDraw extends ASprite {
	var car:Car;
	var g:Graphics;

	public function new(car:Car) {
		super();
		this.car = car;
		g = new Graphics();
		addChild(g);
	}

	static inline function lerp(a:Float, b:Float, t:Float):Float {
		return a + (b - a) * t;
	}

	static function at(m:ASprite, t:Float):Array<Float> {
		var p = m._prevState != null ? m._prevState : m._curState;
		var c = m._curState;
		var dr = c.rotation - p.rotation;
		while (dr > Math.PI)
			dr -= Math.PI * 2;
		while (dr < -Math.PI)
			dr += Math.PI * 2;
		return [lerp(p.x, c.x, t), lerp(p.y, c.y, t), p.rotation + dr * t];
	}

	override public function updateGraphics(a:Float) {
		super.updateGraphics(a);
		var b = at(car.body, a);
		var l = at(car.left, a);
		var r = at(car.right, a);
		var pts = car.fixings(b[0], b[1], b[2]);
		var top = car.wheelTop();
		g.clear();
		g.lineStyle(2, 0x0, 1);
		// Gauche
		g.moveTo(pts[0][0], pts[0][1]);
		g.lineTo(l[0], l[1] - top);
		// Droite
		g.moveTo(pts[1][0], pts[1][1]);
		g.lineTo(r[0], r[1] - top);
		// Centrales
		g.moveTo(pts[2][0], pts[2][1]);
		g.lineTo(l[0], l[1] - top);
		g.moveTo(pts[2][0], pts[2][1]);
		g.lineTo(r[0], r[1] - top);
	}
}

// ---------------------------------------------------------------- Scroller
class Scroller {
	var game:Game;

	var sky:Clip;
	var back:Clip;
	var front:Clip;
	var under:Clip;

	public var speed:Float;

	var grounds:Array<Clip>;
	var groundW:Array<Float>;

	public function new(g:Game) {
		game = g;
		sky = game.depthMan.add(new Clip("sky"), Data.DP_BG);
		back = game.depthMan.add(new Clip("back"), Data.DP_BG);
		under = game.depthMan.add(new Clip("under"), Data.DP_BG);
		front = game.depthMan.add(new Clip("front"), Data.DP_BG);

		grounds = [];
		groundW = [];
		attachGrounds();
		speed = Data.MIN_SPEED;
	}

	// ATTACH: SLICES DU SOL (bitmaps of 600 x 2)
	function attachGrounds() {
		for (i in 0...Data.SLICES) {
			var mc = game.depthMan.add(new Clip("ground"), Data.DP_BG);
			mc.gotoAndStop(i + 1);
			mc._y = 248 + i * Data.SLICE_HEIGHT;
			mc._xscale = 100 + 100 * i / Data.SLICES;
			var w = 600 * mc._xscale / 100;
			groundW.push(w);
			mc._x = 150 - w / 2;
			mc.updateState();
			grounds.push(mc);
		}
	}

	public function hideGround() {
		for (mc in grounds)
			mc._visible = false;
	}

	public function showGround() {
		for (mc in grounds)
			mc._visible = true;
	}

	// MISE À JOUR DE LA VITESSE SELON LA DIFFICULTÉ
	public function updateSpeed() {
		speed = Data.SCROLLER_SPEED + game.level * 3;
	}

	// a wrap of a scrolling layer: the shown position jumps with it (no slide back)
	static function jump(mc:ASprite, d:Float) {
		mc._x += d;
		if (mc._prevState != null)
			mc._prevState.x += d;
	}

	public function update() {
		// Controle du speed
		if (KeyboardManager.isDown(KeyboardManager.ARROW_LEFT))
			speed = Math.max(Data.MIN_SPEED, speed - 0.5 * Timer.tmod);

		if (KeyboardManager.isDown(KeyboardManager.ARROW_RIGHT))
			speed += 0.5 * Timer.tmod;

		// Plans de décor
		back._x -= Timer.tmod * speed * 0.2;
		under._x -= Timer.tmod * speed * 0.35;
		front._x -= Timer.tmod * speed * 0.5;
		if (back._x <= -300)
			jump(back, 300);
		if (under._x <= -300)
			jump(under, 300);
		if (front._x <= -300)
			jump(front, 300);

		// Sol mode 7
		var guide = grounds[0];
		var gw = groundW[0];
		guide._x -= Timer.tmod * speed * 0.5;
		var wrap = 0.0;
		if (guide._x <= 300 - gw) {
			wrap = gw / 2;
			jump(guide, wrap);
		}
		var center = guide._x + gw / 2;

		for (i in 1...grounds.length) {
			var mc = grounds[i];
			var offset = (center - 150) / 300 * 300 * i / Data.SLICES;
			mc._x = guide._x - 300 * i / Data.SLICES + offset;
			if (wrap != 0 && mc._prevState != null)
				mc._prevState.x += wrap * (1 + i / Data.SLICES);
		}
	}
}
