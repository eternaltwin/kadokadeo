package logico;

import logico.Game.Step;
import pixi.core.sprites.Sprite as PixiSprite;

class Ball extends Phys {
	public static var COLORS = [0xFF0000, 0xFF9900, 0xBBFF00, 0x22BBFF, 0xBB44FF, 0xFF44EE, 0x6677CC];

	public var flMove:Bool;
	public var flIce:Bool;
	public var flStar:Bool;

	public var col:Int;
	public var group:Int;

	public var tx:Float;
	public var ty:Float;
	public var csp:Float;

	public var mcShadow:MC;
	public var mcStar:MC;

	// Game.initGameOver: `b.update = null` (the ball is not updated any more)
	public var frozen:Bool = false;

	var ballMC:BallMC;
	// the shadow is attached at (0, 0) and placed by the first update: that placement is not interpolated
	var shadowPlaced:Bool = false;

	public function new(?mc:MC) {
		if (mc == null)
			mc = Game.me.dm.add(new BallMC(), Game.DP_BALLS);
		super(mc);
		ballMC = cast root;

		csp = 0.25;
		frict = 0.4;
		group = 4;

		mcShadow = Game.me.sdm.attach("shadow", Game.DP_SHADE);
		// (root.cacheAsBitmap = true: the blend modes inside the ball are baked in its pictures)

		// (a star on one ball out of 8: commented out in the original)
	}

	public function setSkin(id:Int):Void {
		col = id;
		// root.smc.gotoAndStop(id + 1)
		ballMC.gotoAndStop(id + 1);
		root.hitR = Data.BALL_HIT[id];
	}

	// UPDATE
	override public function update():Void {
		if (frozen)
			return;
		super.update();

		var dx = tx - x;
		var dy = ty - y;

		vx += dx * csp;
		vy += dy * csp;

		x += dx * 0.2 * mt.Timer.tmod;
		y += dy * 0.2 * mt.Timer.tmod;

		if (flMove) {
			var dist = Math.sqrt(dx * dx + dy * dy);
			var speed = Math.sqrt(vx * vx + vy * vy);
			if (dist < 10 && speed < 2) {
				flMove = false;
				if (Game.me.step == Move)
					Game.me.checkCombo();
			}

			if (speed > 3) {
				Game.me.plasma.drawMc(root, col);
			}
		}

		if (!shadowPlaced) {
			shadowPlaced = true;
			mcShadow.teleport(root._x - 5, root._y + 4);
		} else {
			mcShadow._x = root._x - 5;
			mcShadow._y = root._y + 4;
		}
	}

	// the button handlers: the mouse is read by Game.buttons
	public function activate():Void {
		root.onPress = Game.me.press.bind(this);
		root.onRollOver = Game.me.ballOver.bind(this);
		root.onRollOut = Game.me.ballOut;
		root.onDragOut = Game.me.ballOut;
		root.useHandCursor = true;
		// (KKApi.registerButton(root): the anti-cheat of the KadoKado loader)
	}

	public function deactivate():Void {
		root.onPress = null;
		root.onRollOver = null;
		root.onRollOut = null;
		root.onDragOut = null;
		root.useHandCursor = false;
	}

	// filters and colour of the ball (baked in its pictures, see BallMC)
	public function setGlowOver(on:Bool):Void {
		ballMC.look = on ? -1 : 0;
	}

	public function setCombo(step:Int):Void {
		ballMC.look = step;
	}

	// EXPLODE (pieces and lights: pictures only, on the visual random)
	public function explode():Void {
		var max = 5;
		var cr = 3;
		for (n in 0...max) {
			var p = new Phys(Game.me.dm.add(new JunkMC(), Game.DP_PARTS));
			var a = (n + Seed.randVfx()) / max * 6.28;
			var sp = Seed.randVfx() * 8;
			var ca = Math.cos(a);
			var sa = Math.sin(a);
			p.frict = 0.9;
			p.x = x + ca * sp * cr;
			p.y = y + sa * sp * cr;
			p.vx = ca * sp;
			p.vy = sa * sp;
			p.timer = 10;
			p.fadeType = 0;
			p.setScale(50 + Seed.randVfx() * 100);
			p.vr = (Seed.randVfx() * 2 - 1) * 50;
			var j:JunkMC = cast p.root;
			j.gotoAndPlay(Seed.randomVfx(j._totalframes) + 1);
			j.smcFrame = Seed.randomVfx(JunkMC.SMC_FRAMES) + 1;
			// Col.setColor(p.root.smc, COLORS[col], -200): baked in the pictures of each colour
			j.color = col;
		}

		// PART LIGHT
		var max = 8;
		var cr = 6;
		for (n in 0...max) {
			var p = new Phys(Game.me.dm.add(new LightMC(), Game.DP_PARTS));
			var a = (n + Seed.randVfx()) / max * 6.28;
			var sp = 0.5 + Seed.randVfx() * 3;
			var ca = Math.cos(a);
			var sa = Math.sin(a);
			p.x = x + ca * sp * cr;
			p.y = y + sa * sp * cr;
			p.vx = ca * sp;
			p.vy = sa * sp;
			p.timer = 10 + Seed.randVfx() * 20;
			p.setScale(50 + Seed.randVfx() * 100);
			p.vr = (Seed.randVfx() * 2 - 1) * 20;
			p.fr = 0.98;

			var da = Seed.randVfx() * 6.28;
			var dec = Seed.randVfx() * 20;

			p.x -= Math.cos(da) * dec;
			p.y -= Math.sin(da) * dec;

			p.root._rotation = da / 0.0174;
			(cast p.root : LightMC).smc._x = dec;
			p.fadeType = 0;
		}

		mcShadow.removeMovieClip();
		kill();
	}
}

// mcBall: its smc on the frame of the colour (_currentframe), and the filters / colour the code gives the ball
// (look): 0 none, -1 Game.ballOver's glows, 1..12 the step of Game.updateCombo (whitening + glow)
class BallMC extends MC {
	public var look:Int = 0;

	public function new() {
		super("ball");
	}

	override function showFrame():Void {
		var c = _currentframe - 1;
		if (look == 0)
			setTexture(frames[c]);
		else if (look < 0)
			setTexture(Tex.get("ballOver")[c]);
		else
			setTexture(Tex.get("ballCombo")[c * Data.COMBO_STEPS + look - 1]);
	}
}

// partJunk: a timeline of 14 frames (playing) holding smc at depth 1 (one of 3 shapes, gotoAndStop by the code,
// coloured by Col.setColor) and, on frames 13 and 14 only, white copies of it (depths 3 and 5, playing sprites: the
// copy of depth 3 shows its frame 2 on frame 14 when it was placed on frame 13, its frame 1 when the clip was sent
// to frame 14 directly)
class JunkMC extends MC {
	public static inline var SMC_FRAMES = 3;

	public var smcFrame:Int = 1;
	public var color:Int = 0;

	var overlay:PixiSprite;
	var from13:Bool = false;

	public function new() {
		super("junk");
		_totalframes = Data.JUNK_FRAMES;
		playing = true;
		overlay = new PixiSprite();
		overlay.visible = false;
		spr.addChild(overlay);
	}

	override function goto(f:Int):Void {
		super.goto(f);
		from13 = false;
	}

	override function advance():Void {
		var was13 = playing && !removed && _currentframe == 13;
		super.advance();
		from13 = was13;
	}

	override function showFrame():Void {
		var t = frames[color * SMC_FRAMES + smcFrame - 1];
		if (spr.texture != t) {
			spr.texture = t;
			spr.anchor.copyFrom(t.defaultAnchor);
		}
		if (overlay == null)
			return;
		var w = _currentframe == 13 ? 0 : _currentframe == 14 ? (from13 ? 1 : 2) : -1;
		overlay.visible = w >= 0;
		if (w >= 0) {
			var o = Tex.get("junkW")[w];
			if (overlay.texture != o) {
				overlay.texture = o;
				overlay.anchor.copyFrom(o.defaultAnchor);
			}
		}
	}
}

// partLight: smc (2 frames, playing) at _x = dec in the clip
class LightMC extends MC {
	public var smc:MC;

	public function new() {
		super();
		smc = attach(new MC("light"));
		smc.playing = true;
	}
}
