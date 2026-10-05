package schizofuzz;

import haxe.io.UInt16Array;
import kado.TouchControlsConfig.TouchButtonShape;
import kado.TouchControlsConfig.TouchControlsMode;
import schizofuzz.MC.Plans;

typedef Part = {
	mc:MC,
	dx:Null<Float>,
	dy:Null<Float>
}

enum State {
	Wait;
	Start(inc:Bool);
	WaitSpace(s:State);
	WaitFrames(n:Int);
	Angle;
	Run;
}

// Game.hx of the original (Haxe 2 for Flash 8), line by line
@:expose('GameSchizoFuzz')
class Game implements kado.GameInterface {
	// Space launches (held to charge, released then pressed again to throw), up / down steer in the air
	public static var TOUCH_CONTROLS:kado.TouchControlsConfig = {
		mode: TouchControlsMode.KEYBOARD,
		buttons: [
			{
				id: "up",
				label: "▲",
				leftPx: 20,
				bottomPx: 104,
				size: 72,
				keyCode: KeyboardManager.UP,
				shape: TouchButtonShape.SQUARE,
			},
			{
				id: "down",
				label: "▼",
				leftPx: 20,
				bottomPx: 20,
				size: 72,
				keyCode: KeyboardManager.DOWN,
				shape: TouchButtonShape.SQUARE,
			},
			{
				id: "space",
				label: "●",
				rightPx: 20,
				bottomPx: 30,
				size: 104,
				keyCode: KeyboardManager.SPACE,
			},
		],
	};

	// ZQSD / WASD move like the arrows, Enter launches like Space
	public static var KEY_ALIASES = KeyboardManager.ALIASES_MOVE.concat(KeyboardManager.ALIASES_ENTER_SPACE);

	// Flash played Schizo Fuzz at 40 frames/s (the rate of the SWF and of the KadoKado loader) with
	// Timer.wantedFPS = 32
	public static inline var FLASH_FPS = 40;

	static var BOTTOM = 280.0;
	static var SCROLL_SPEEDS = [
		1, // grass
		0.6,
		0.3, // trees
		0.2, // forest
		0.1,
		0,
	];

	var state:State;
	var dmanager:Plans;
	var bgs:Array<MC>;
	var scroll:Float;
	var speed:Float;
	var angle:Float;
	var pos:{x:Float, y:Float, dx:Float, dy:Float};
	var nextObject:Int;
	// (never set before the first tree: undefined, equal to no frame)
	var lastTree:Null<Int> = null;
	var objects:Array<MC>;
	var items:Array<{mc:MC, k:Int, active:Bool}>;
	var hframe:Int;
	var stats:{_d:Int};
	var gameover:Bool = false;
	var itemDist:Float;
	var vangle:Float;
	var qpos:Float;
	var aim:MC;
	var arrow:MC;
	var arrowTxt:Digits;
	var plate:MC;
	var hero:MC;
	var nexts:Array<MC>;
	var nextItems:Array<Int>;
	var nextPos:Int;
	var dispPos:Int;
	var bonus:Bool;

	var plist:Array<Part>;
	var genFxTimer:Float = 0;

	public static var me:Game;

	var root:ASprite;
	var isReplay:Bool;
	// the constructor runs the original's init(), which polls the keys before the first frame: no key yet
	var constructing:Bool;
	// Flash frames still owed, in quarters (5 per step)
	var frameAcc:Int = 0;
	var frameCount:Int = 0;
	#if debug
	// test harness: items hit (0-5; 9, 10: stump, shield hit with the shield)
	var hits = [for (i in 0...11) 0];
	#end

	public function new(mc:ASprite, ?isReplay:Bool = false) {
		this.isReplay = isReplay;
		var keys = new UInt16Array(5);
		keys[0] = KeyboardManager.LEFT;
		keys[1] = KeyboardManager.RIGHT;
		keys[2] = KeyboardManager.UP;
		keys[3] = KeyboardManager.DOWN;
		keys[4] = KeyboardManager.SPACE;
		KadoKadeoManager.kkm.replay.init({
			recordedKeys: keys,
			recordInputs: true,
			recordEvents: false,
			recordMousePosition: false,
			recordedMouseButtons: new UInt16Array(0),
		});
		MC.clearAll();
		Clip.reset();
		Const.reset();
		// mt.Timer before its first update (Manager.init creates the game before the first Manager.main)
		Timer.tmod = 1;
		constructing = true;
		me = this;

		// the original's 300x300 pixels, drawn x2
		root = mc.createEmptyMovieClip("scene", 0);
		root._xscale = root._yscale = 100 * Clip.K;
		root.updateState();

		dmanager = new Plans(root);
		bgs = new Array();
		for (i in 0...6) {
			bgs[i] = dmanager.attach("bg_plan" + i, (if (i == 0) Const.PLAN_FRONT else Const.PLAN_BG));
			dmanager.under(bgs[i]);
			bgs[i].wrapX = 500;
		}
		bgs[0]._y = 300 - Data.BG_HEIGHT[0];
		bgs[1]._y = 300 - Data.BG_HEIGHT[1];
		bgs[2]._y = 300 - Data.BG_HEIGHT[2];
		bgs[3]._y = 290 - Data.BG_HEIGHT[3];
		bgs[4]._y = 170 - Data.BG_HEIGHT[4];
		plist = new Array();
		nexts = new Array();
		for (i in 0...3) {
			var n = dmanager.attach("next", Const.PLAN_ARROW);
			nexts.push(n);
			n._x = 210 + i * 35;
			n._y = 20;
		}
		stats = {_d: 0};
		init();
		constructing = false;

		MC.displayAll(1);
		warmShaders();
	}

	public function stageRoot():ASprite {
		return root;
	}

	// the glow filter (hero, arrow) compiles its shader now, not when the hero is launched
	function warmShaders() {
		var renderer:Dynamic = KadoKadeoManager.kkm.renderer;
		if (renderer == null)
			return;
		var holder = new pixi.core.display.Container();
		var s = new pixi.core.sprites.Sprite(pixi.core.textures.Texture.WHITE);
		s.filters = [new FlashGlow(3, 3, 1, 0x945060)];
		holder.addChild(s);
		var rt:Dynamic = (cast pixi.core.textures.RenderTexture : Dynamic).create({width: 32, height: 32});
		renderer.render(holder, {renderTexture: rt, clear: true});
		holder.destroy({children: true});
		rt.destroy(true);
	}

	function init() {
		scroll = 150.0;
		pos = {
			x: 200.0,
			y: BOTTOM - 10,
			dx: 0.0,
			dy: 0.0
		};
		angle = 0;
		qpos = 0;
		speed = 10;
		// (the trees only: visual random)
		nextObject = 100 + Seed.randomVfx(400);
		itemDist = 0;
		state = Wait;
		nextPos = 0;
		dispPos = 0;
		bonus = false;
		nextItems = [
			randomProbas(Const.PROBAS),
			randomProbas(Const.PROBAS),
			randomProbas(Const.PROBAS)
		];
		objects = new Array();
		items = new Array();
		plate = dmanager.attach("startPlat", Const.PLAN_BG);
		objects.push(plate);
		flashUpdate();
		updateObjects();
	}

	function randomProbas(tbl:Array<Int>):Int {
		var t = 0;
		for (i in 0...tbl.length)
			t += tbl[i];
		t = Seed.random(t);
		var i = 0;
		while (true) {
			t -= tbl[i];
			if (t < 0)
				return i;
			i += 1;
		}
		return null;
	}

	// Math.cos, sin, atan2, pow of the gameplay rounded (they may differ in the last bits between browsers): a
	// replay must give the same flight everywhere
	static inline function q(v:Float):Float {
		return Math.round(v * 4294967296.0) / 4294967296.0;
	}

	inline function key(k:Int):Bool {
		return !constructing && KeyboardManager.isDown(k);
	}

	function setAngle(a:Float) {
		var amax = Math.PI * 7 / 16;
		if (a > amax)
			a = amax;
		angle = a;
		pos.dx = q(Math.cos(a) * speed);
		pos.dy = q(-Math.sin(a) * speed);
	}

	// update() of the original: one Flash frame, in 5 sub-steps
	function flashUpdate() {
		var count = 5;
		for (i in 0...count)
			doUpdate(Timer.tmod / count, i == 0);
	}

	function updatePos(tmod:Float) {
		pos.x += pos.dx / 2 * tmod;
		pos.y -= pos.dy / 2 * tmod;
		pos.dy -= 0.1 * tmod;
		if (pos.y > BOTTOM) {
			pos.y = BOTTOM;
			pos.dx *= 0.7;
			pos.dy *= -0.65;
			if (speed > 10) {
				hero.gotoAndStop(2);
				genFxTimer = 70;
				state = WaitFrames(4);
			} else if (speed < 3)
				pos.dy = 1;
		}
		speed = Math.sqrt(pos.dx * pos.dx + pos.dy * pos.dy);
		if (speed > 20) {
			var p = q(Math.pow(0.999, tmod));
			speed *= p;
			pos.dx *= p;
			pos.dy *= p;
		}
		angle = q(Math.atan2(-pos.dy, pos.dx));
		vangle = angle;
		hframe = 1;
		if (pos.y > BOTTOM - 20 && speed < 10) {
			hframe = 6;
			pos.dx = speed * q(Math.pow(0.95, tmod));
			pos.dy = 0;
			pos.y = BOTTOM;
		} else if (key(KeyboardManager.LEFT) || key(KeyboardManager.UP)) {
			var mina = 0.05 + (BOTTOM - pos.y) / 10000;
			if (angle > mina) {
				angle -= 0.03 * Math.sqrt(speed) / 4 * tmod;
				if (angle < mina)
					angle = mina;
				setAngle(angle);
			}
			vangle = -Math.PI / 4;
			hframe = 3;
		} else if (key(KeyboardManager.RIGHT) || key(KeyboardManager.DOWN)) {
			pos.dy -= 0.1 * tmod;
			vangle = Math.PI / 4;
			hframe = 4;
		}
	}

	function updateScroll(tmod:Float):Int {
		var p = q(Math.pow(0.825, tmod));
		var old = Std.int(scroll);
		scroll = scroll * p + (pos.x - 50) * (1 - p);
		var i = 0;
		for (bg in bgs) {
			var bgpos = Std.int((scroll * SCROLL_SPEEDS[i]) % 500);
			bg._x = -bgpos;
			i++;
		}
		return Std.int(scroll) - old;
	}

	// the particles only change the pictures: visual random
	function particle(id:Int, x:Float, y:Float, ds:Float) {
		var mc = dmanager.attach("part", Const.PLAN_FX);
		var dx:Null<Float> = null;
		var dy:Null<Float> = null;
		mc._xscale = Seed.randomVfx(70) + 30;
		mc._yscale = mc._xscale;
		mc._alpha = Seed.randomVfx(40) + 60;
		mc._rotation = Seed.randomVfx(360);
		// (gotoAndStop("" + id): a string holding a number is that frame)
		mc.gotoAndStop(id);

		if (id == 1) {
			// fumée
			mc._x = x + 25 + Seed.randomVfx(10) * (Seed.randomVfx(2) * 2 - 1);
			mc._y = y + Seed.randomVfx(7) * (Seed.randomVfx(2) * 2 - 1);
			if (ds <= 1) {
				mc._xscale *= 0.5;
				mc._yscale *= 0.5;
			}
		} else {
			mc._x = x + Seed.randomVfx(15) * (Seed.randomVfx(2) * 2 - 1);
			mc._y = y + Seed.randomVfx(15) * (Seed.randomVfx(2) * 2 - 1);
			dx = ds * (Seed.randomVfx(10) / 10);
			if (id >= 6) {
				// terre
				dy = -Seed.randomVfx(20) / 10;
			} else {
				// feuilles
				dy = -Seed.randomVfx(10) / 10;
				if (id == 5) {
					dx *= 0.5 * (Seed.randomVfx(2) * 2 - 1);
				}
			}
			if (ds <= 1) {
				dy *= 0.5;
			}
		}
		plist.push({mc: mc, dx: dx, dy: dy});
	}

	function updateObjects() {
		while (itemDist > 500) {
			itemDist -= 500;

			while (nextItems.length <= nextPos + 3)
				nextItems.push(randomProbas(Const.PROBAS));

			var id = nextItems[nextPos++];
			var mc = dmanager.attach("item", if (id == 1) Const.PLAN_ITEM_FRONT else Const.PLAN_ITEM);
			items.push({mc: mc, k: id, active: false});
			mc.gotoAndStop(1 + id);
			if (id == 4)
				mc.sub("sub").gotoAndStop(if (bonus) 2 else 1);
			mc._x = 400 + itemDist;
			mc._y = BOTTOM;
		}

		if (scroll >= nextObject) {
			nextObject += 140 + Seed.randomVfx(500);
			var obj = dmanager.attach("bgItem", Const.PLAN_BG);
			var f;
			do {
				f = 1 + Seed.randomVfx(obj._totalframes);
			} while (f == lastTree);
			obj.gotoAndStop(f);
			lastTree = obj._currentframe;
			obj._x = 300 + width(obj);
			obj._y = BOTTOM + 30;
			objects.push(obj);
		}
		for (i in 0...3)
			nexts[i].gotoAndStop(nextItems[dispPos + i] + 1);
	}

	// o._width of the decor objects (measured in the SWF: Data)
	function width(o:MC):Float {
		if (o == plate) {
			var s = o.sub("sub");
			return s == null ? 0 : Data.PLATE_WIDTH[s.frame - 1];
		}
		return Data.BG_ITEM_WIDTH[o._currentframe - 1];
	}

	// o.mc.hitTest(x, y): the point in the bounds of the item in the stage (the game is at the origin of the
	// KadoKado loader), computed by Flash in twips; the bounds of the item are measured in the SWF (Data)
	function hitTest(o:{mc:MC, k:Int, active:Bool}, x:Float, y:Float):Bool {
		var mc = o.mc;
		var s = mc.sub("sub");
		var b = if (o.k == 4 && s != null && s.frame == 2) Data.SHIELD_BOUNDS2 else Data.ITEM_BOUNDS[o.k];
		var tx = Math.round(mc._x * 20);
		var ty = Math.round(mc._y * 20);
		var px = Std.int(x * 20);
		var py = Std.int(y * 20);
		return px >= tx + Math.round(b[0] * 20) && px <= tx + Math.round(b[1] * 20) && py >= ty + Math.round(b[2] * 20)
			&& py <= ty + Math.round(b[3] * 20);
	}

	function checkObjects(ds:Float) {
		var i = 0;
		while (i < objects.length) {
			var o = objects[i];
			o._x -= ds * 0.7;
			if (o._x < -width(o)) {
				o.removeMovieClip();
				objects.splice(i, 1);
			} else
				i++;
		}

		var i = 0;
		while (i < items.length) {
			var o = items[i];
			o.mc._x -= ds;
			if (o.mc._x < -30) {
				o.mc.removeMovieClip();
				items.splice(i, 1);
				dispPos++;
				Const.PROBAS[3]++;
			} else {
				if (!o.active && hitTest(o, pos.x - scroll, pos.y) && !gameover) {
					// start anim
					o.active = true;
					#if debug
					hits[o.k + (bonus && (o.k == 3 || o.k == 4) ? 6 : 0)]++;
					#end
					if (bonus && (o.k == 3 || o.k == 4)) {
						bonus = false;
						setShield(hero, false);
						if (o.k == 4)
							o.mc.sub("sub").gotoAndStop(1);
					} else {
						var sub = o.mc.sub("sub");
						if (sub != null)
							sub.play();
						addScore(KKApi.val(Const.POINTS[o.k]));
						switch (o.k) {
							case 0: // MOULIN
								if (Math.abs(angle) < 0.3)
									setAngle(-0.3);
								pos.dx += 20;
								if (pos.dx > 30)
									pos.dx = 30;
								hero._visible = false;
								state = WaitFrames(21);

							case 1: // BUISSON
								angle += Math.PI / 5;
								setAngle(angle);
								for (n in 0...10) {
									particle(5, o.mc._x, o.mc._y, ds);
								}
								genFxTimer = 60;
								if (pos.dy <= 4)
									pos.dy = 4;

							case 2: // TREMPLIN
								pos.dy = Math.abs(pos.dy) + 10;
								if (pos.dy > 30)
									pos.dy = 30;

							case 3: // SOUCHE
								speed = 0;
								pos.dx = 0.01;
								pos.dy = 0;
								hero.removeMovieClip();

							case 4: // SHIELD
								bonus = true;
								setShield(hero, true);
								pos.dx += 10;

							case 5: // GLAND
								pos.dx += 15;
						}
					}
				}
				i++;
			}
		}
	}

	// mc.sub.smc._visible = v (arrow.sub has no smc: only the hero's)
	function setShield(mc:MC, v:Bool) {
		var s = mc != null ? mc.sub("sub") : null;
		if (s != null)
			s.setVisible("smc", v);
	}

	function updateHero(tmod:Float) {
		hero._x = Std.int(pos.x - scroll);
		hero._y = pos.y;

		if (hero._y < -30) {
			if (arrow == null || arrow.removed) {
				arrow = dmanager.attach("arrow", Const.PLAN_ARROW);
				arrowTxt = new Digits(Clip.K * arrow.clip.def.r);
				// the GlowFilter of the text field (blur 2, strength 3.5)
				arrowTxt.filters = [new FlashGlow(2, 2, 3.5, 0x7D4560)];
				arrow.clip.addChildAt(arrowTxt, 1);
			}
			arrow._x = hero._x;
			arrowTxt.setText(Std.int(-hero._y / 10) + "m");
			arrow._xscale = arrow._yscale = 100 - Math.sqrt(-hero._y);
		} else if (arrow != null)
			arrow.removeMovieClip();

		var ca = hero._rotation * Math.PI / 180;
		ca += Math.sin(vangle - ca) * Math.max(speed / 30, 0.03) * tmod;
		hero._rotation = ca * 180 / Math.PI;
		if (state.match(Run) && hframe != hero._currentframe && hero._currentframe != 2)
			hero.gotoAndStop(hframe);

		qpos += speed / 20;
		var hsub = hero.sub("sub");
		var q = hsub != null ? hsub.getClip("q") : null;
		if (q != null) {
			q.gotoAndStop(Std.int(qpos % q._totalframes) + 1);
			setRotation(q, -hero._rotation + angle * 180 / Math.PI);
		}
		var asub = arrow != null ? arrow.sub("sub") : null;
		if (asub != null) {
			asub.gotoAndStop(hero._currentframe);
			setRotation(asub, hero._rotation);
		}

		if (speed < 1 && pos.y > BOTTOM - 20 && pos.dy <= 0 && !gameover) {
			stats._d = Std.int(pos.x);
			gameOver();
			if (hsub != null)
				hsub.gotoAndPlay("end");
		}

		setShield(hero, bonus);
	}

	// a nested clip turned by the code: its timeline no longer moves it (Flash), NaN is ignored
	static function setRotation(c:Clip, r:Float) {
		if (!Math.isFinite(r))
			return;
		c.scripted = true;
		c._rotation = r;
	}

	function updateParticles(ds:Float) {
		if (genFxTimer > 0) {
			genFxTimer -= 1;
			if (Seed.randomVfx(5) == 0) {
				particle(2 + Seed.randomVfx(3), hero._x, hero._y, ds);
			}
			if (hero._y >= BOTTOM - 15 && Seed.randomVfx(8) == 0) { // terre
				particle(6 + Seed.randomVfx(3), hero._x, hero._y, ds);
			}
		}

		if (hero._y >= BOTTOM - 5) {
			if (ds >= 1) {
				particle(1, hero._x, BOTTOM - 2, ds);
			}
		}

		var i = 0;
		while (i < plist.length) {
			var p = plist[i];
			var fl_kill = false;

			if (p.mc._currentframe == 1) { // fumée
				p.mc._x -= ds;
				p.mc._y -= 0.25;
				p.mc._xscale -= 1 + Seed.randomVfx(2);
				p.mc._yscale = p.mc._xscale;
				if (p.mc._xscale <= 5) {
					fl_kill = true;
				}
			} else {
				p.mc._x -= ds * 0.6;
				p.mc._rotation -= Seed.randomVfx(5);
				//				p.mc._alpha -= 0.5;
				if (p.mc._alpha <= 0 || p.mc._x <= -10 || p.mc._y >= 310) {
					fl_kill = true;
				}
			}
			if (p.dx != null && p.dy != null) {
				p.mc._x += p.dx;
				p.mc._y += p.dy;
				if (p.mc._currentframe >= 6) {
					// terre
					p.dx -= ds * 0.006;
					p.dy += 0.01;
				} else {
					p.dx -= ds * 0.01;
					p.dy += 0.006;
				}
			}
			if (fl_kill) {
				p.mc.removeMovieClip();
				plist.splice(i, 1);
				i--;
			}
			i++;
		}
	}

	public function doUpdate(tmod:Float, first:Bool) {
		switch (state) {
			case WaitSpace(s):
				if (!key(KeyboardManager.SPACE))
					state = s;
			case Wait:
				updateScroll(tmod);
				if (key(KeyboardManager.SPACE)) {
					plate.sub("sub").gotoAndStop("back");
					state = WaitSpace(Start(false));
					speed = 10;
				}
			case Start(press):
				speed += tmod / 2;
				if (speed > 30)
					speed = 30;
				plate.sub("sub").gotoAndStop(Std.int(43 + (speed - 10) * 80 / 20));
				pos.x = 200 - speed * 3;
				var ds = updateScroll(tmod);
				updateObjects();
				checkObjects(ds);
				if (press && !key(KeyboardManager.SPACE)) {
					aim = dmanager.attach("aim", Const.PLAN_ARROW);
					aim._x = pos.x - 100 + speed * 2;
					aim._y = 250;
					state = Angle;
				} else if (!press && (key(KeyboardManager.SPACE) || speed == 30))
					state = Start(true);
			case Angle:
				angle += speed * tmod / 50;
				var a = angle % Math.PI;
				if (a > Math.PI / 2)
					a = Math.PI - a;
				var a = ((a / (Math.PI / 2)) * 0.4 + 0.05) * Math.PI / 2;
				aim._rotation = -a * 180 / Math.PI;
				if (key(KeyboardManager.SPACE)) {
					plate.sub("sub").gotoAndPlay("launch");
					plate._x += 100;
					hero = dmanager.attach("hero", Const.PLAN_HERO);
					setShield(hero, false);
					Clip.globalHero = hero;
					aim.removeMovieClip();
					var s = q(Math.pow(speed - 10, 0.7)) + 30;
					pos.dx = q(Math.cos(a) * s);
					pos.dy = q(Math.sin(a) * s);
					pos.x += pos.dx;
					pos.y -= pos.dy;
					state = Run;
				}
			case Run:
				updatePos(tmod);
				var ds = updateScroll(tmod);
				itemDist += ds;
				if (!gameover)
					addScore(ds);
				updateObjects();
				checkObjects(ds);
				updateHero(tmod);
				updateParticles(ds);
				if (first && plate != null && !plate.removed) {
					var apos = if (plate._x < 0) 0 else plate._x;
					var nframes = 20;
					var f = Std.int(200 - apos * nframes / 250);
					if (f < 200 - nframes)
						f = 200 - nframes;
					plate.sub("sub").gotoAndStop(f);
				}
			case WaitFrames(n):
				updateParticles(0);
				if (!first)
					return;
				if (n == 0)
					hero._visible = true;
				state = if (n == 0) Run else WaitFrames(n - 1);
		}
	}

	function addScore(n:Int) {
		// (KKApi.addScore: nothing after KKApi.gameOver, the original checks gameover before each call)
		if (!gameover)
			KadoKadeoManager.kkm.addScore(n);
	}

	function gameOver() {
		gameover = true;
		#if debug
		untyped js.Browser.window.__over = debugState();
		#end
		KadoKadeoManager.kkm.gameOver(stats);
	}

	// ---------------------------------------------------------------- KadoKadeo step: 5 Flash frames every 4 steps
	public function update(delta:Float) {
		frameAcc += 5;
		while (frameAcc >= 4) {
			frameAcc -= 4;
			flashFrame();
		}
		MC.displayAll(frameAcc / 4);
	}

	// one Flash frame: the timelines advance, then Manager.main (tmod ~0.8: Timer settles on 32 / 40)
	function flashFrame() {
		Timer.tmod = 32 / FLASH_FPS;
		MC.frameStart();
		flashUpdate();
		frameCount++;
		#if debug
		untyped js.Browser.window.__state = debugState();
		#end
	}

	#if debug
	// state compared between a game and its replay (test harness)
	function debugState():Dynamic {
		return {
			frame: frameCount,
			score: KadoKadeoManager.kkm.score.get(),
			st: Std.string(this.state),
			x: pos.x,
			y: pos.y,
			dx: pos.dx,
			dy: pos.dy,
			speed: speed,
			scroll: scroll,
			nextPos: nextPos,
			dispPos: dispPos,
			stump: Const.PROBAS[3],
			bonus: bonus,
			over: gameover,
			d: stats._d,
			hits: hits.join(","),
		};
	}

	// test harness: clips drawn by the runtime on a page ([name, frame, x, y, scale, {nested instance: frame}]), to
	// compare with the SWF (examples/schizofuzz/ncheck.mjs, ref.py)
	public function debugShow(list:Array<Array<Dynamic>>, bgColor:Int) {
		var stage:Dynamic = untyped KadoKadeoManager.kkm.stage;
		var box = new ASprite();
		var g = box.getGraphics();
		g.beginFill(bgColor);
		g.drawRect(0, 0, 600, 640);
		g.endFill();
		for (o in list) {
			var c = new Clip(o[0], 2);
			// nested clips driven by the code: before and after the frame change (clips created on the new frame)
			for (pass in 0...2) {
				if (pass == 1)
					c.gotoAndStop(o[1]);
				if (o.length > 5)
					for (k in Reflect.fields(o[5])) {
						var sub = c.getClip(k);
						if (sub != null)
							sub.gotoAndStop(Reflect.field(o[5], k));
					}
			}
			c._x = o[2];
			c._y = o[3];
			c._xscale = c._yscale = o[4] * 100;
			box.addChild(c);
		}
		box.updateState();
		box.updateGraphics(1);
		stage.addChild(box);
	}
	#end

	public function destroy():Void {
		me = null;
		MC.clearAll();
		Clip.reset();
		Const.reset();
	}
}
