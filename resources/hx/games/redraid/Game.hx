package redraid;

import common_haxe_avm1.KeyboardManager;
import common_haxe_avm1.MouseManager;
import haxe.io.UInt16Array;
import kado.TouchControlsConfig;
import pixi.core.display.Container;
import pixi.core.graphics.Graphics;
import pixi.core.sprites.Sprite as PixiSprite;
import pixi.core.textures.RenderTexture;
import pixi.core.textures.Texture;
import pixi.filters.colormatrix.ColorMatrixFilter;
import redraid.Units;

// Red Raid (KadoKado, Motion-Twin): ported from the original sources (Manager, Game, Cs, Sprite, Phys, Part, Gibs,
// Grenade, Arrow, Ally and its soldiers, Alien and its monsters of the "Red Raid" folder) and the graphics of its SWFs.
// A squad of marines holds the ground against waves of aliens: click a soldier (or draw a box) to select, click the
// ground to move them; they shoot by themselves. The game runs in the Flash pixels of the original (300 x 300), drawn x2.
@:expose('GameRedRaid')
class Game implements kado.GameInterface {
	// on a touch screen: a finger selects (tap, or a box) and moves like the mouse; the buttons are the keys
	public static var TOUCH_CONTROLS:kado.TouchControlsConfig = {
		mode: TouchControlsMode.KEYBOARD,
		buttons: [
			{
				id: "inverse",
				label: "⇄",
				leftPx: 10,
				bottomPx: 10,
				size: 56,
				keyCode: KeyboardManager.SPACE,
			},
			{
				id: "life",
				label: "♥",
				rightPx: 10,
				bottomPx: 10,
				size: 56,
				keyCode: KeyboardManager.ENTER,
			}
		],
	};

	public static inline var K = 2;

	public static inline var DP_BG = 1;
	public static inline var DP_GROUND = 2;
	public static inline var DP_SHADOW = 3;
	public static inline var DP_SELECTOR = 4;
	public static inline var DP_BONUS = 5;
	public static inline var DP_UNITS = 6;
	public static inline var DP_PART = 7;
	public static inline var DP_FLY = 8;
	public static inline var DP_DRAW = 9;
	public static inline var DP_INTERFACE = 10;

	static var RENFORT = [300, 500, 900, 1500];

	public static var me:Game;

	var flCadre:Bool;
	var flShowLife:Bool;
	var flSpaceRelease:Bool;

	var step:Int;
	var scTimer:Null<Float>;
	var waveTimer:Float;

	public var dif:Float;
	public var danger:Float;

	var renfort:Float;

	public var dm:Plans;

	var scp:{x:Float, y:Float};

	public var sList:Array<Sprite>;
	public var aList:Array<Ally>;
	public var bList:Array<Alien>;
	public var bounceList:Array<Phys>;
	public var bonusList:Array<{sp:Sprite, timer:Float, type:Int}>;

	var bg:Clip;
	var draw:Graphics;
	var map:ASprite;

	var renfortList:Array<Clip>;

	public var stats:{b:Array<Int>, k:Array<Int>, l:Array<Int>, d:Null<Int>};

	var scene:ASprite;
	var isReplay:Bool;

	// bg.onPress / onRelease: the mouse button pressed on the ground
	var pressed:Bool;

	// frames played (state of the game at its end in the test harness)
	var frameCount:Int;

	public function new(root:ASprite, ?isReplay:Bool = false) {
		KadoKadeoManager.kkm.replay.init({
			recordedKeys: UInt16Array.fromArray([KeyboardManager.SPACE, KeyboardManager.ENTER]),
			recordInputs: true,
			recordEvents: false,
			recordMousePosition: true,
			recordedMouseButtons: UInt16Array.fromArray([MouseManager.BUTTON_LEFT]),
		});
		me = this;
		this.isReplay = isReplay;
		pressed = false;
		frameCount = 0;
		Clip.flushRemoved();
		if (!isReplay) {
			var canvas:Dynamic = KadoKadeoManager.kkm.canvas;
			canvas.addEventListener("pointerdown", onPointerDown);
		}

		Cs.init();
		Cs.game = this;
		scene = root.createEmptyMovieClip("scene", 0);
		scene._xscale = scene._yscale = 100 * K;
		scene.updateState();
		map = scene.createEmptyMovieClip("map", 1);
		dm = new Plans(map);

		bg = dm.add(new Clip("mcBg"), DP_BG);
		var d = dm.empty(DP_DRAW);
		draw = new Graphics();
		d.addChild(draw);

		flCadre = false;
		flShowLife = false;
		flSpaceRelease = false;

		sList = [];
		aList = [];
		bList = [];
		bounceList = [];
		renfortList = [];
		bonusList = [];

		dif = 2;
		waveTimer = 800;
		danger = 0;
		renfort = 0;

		stats = {
			b: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
			l: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
			k: [0, 0, 0, 0],
			d: null
		};

		// ALLY
		var max = 4;
		var dist = 30;
		for (i in 0...max) {
			var sp = new Marine();
			var a = (i / max) * 6.28;
			sp.x = Cs.mcw * 0.5 + Cs.cos(a) * dist;
			sp.y = Cs.mch * 0.5 + Cs.sin(a) * dist;
			sp.hp = sp.hpMax;
		}

		initStep(0);
		warmShaders();
	}

	function onPointerDown(e:Dynamic) {
		// like the Flash player, the game keeps the mouse while its button is held (a box drawn out of the game)
		try {
			var canvas:Dynamic = KadoKadeoManager.kkm.canvas;
			canvas.setPointerCapture(e.pointerId);
		} catch (_:Dynamic) {}
	}

	function initStep(n:Int) {
		step = n;
	}

	// bg._xmouse / bg._ymouse (the map does not scroll: Flash pixels of the game)
	public inline function mouseX():Float {
		return Math.max(0, MouseManager.getX()) / K;
	}

	public inline function mouseY():Float {
		return Math.max(0, MouseManager.getY()) / K;
	}

	// the listeners of the original: bg.onPress / bg.onRelease (only during the game: initStep(0)). Flash calls them
	// for a press on the ground (its 300 x 300 picture, not the bar of the site below it) and a release on it after
	// that press; released elsewhere, nothing (no onReleaseOutside)
	function readInputs() {
		for (c in MouseManager.getFrameButtonChanges()) {
			if (c.button != MouseManager.BUTTON_LEFT || step != 0)
				continue;
			var over = mouseX() <= Cs.mcw && mouseY() <= Cs.mch;
			if (c.isDown) {
				if (over) {
					pressed = true;
					startClick();
				}
			} else if (pressed) {
				pressed = false;
				if (over)
					releaseClick();
			}
		}
	}

	// one frame of the Flash player
	public function update(delta:Float) {
		frameCount++;
		Clip.flushRemoved();
		readInputs();
		main();
	}

	function main() {
		// (the original runs max(tmod, 1) loops of tmod <= 1: one loop at the fixed frame rate)
		draw.clear();
		switch (step) {
			case 0:
				// CADRE
				if (flCadre) {
					drawCadre();
					if (mouseX() < 0 || mouseX() > Cs.mcw || mouseY() < 0 || mouseY() > Cs.mch) {
						releaseClick();
					}
				} else if (scTimer != null) {
					scTimer += Timer.tmod;
					var dx = scp.x - mouseX();
					var dy = scp.y - mouseY();
					var dist = Math.sqrt(dx * dx + dy * dy);
					if (scTimer > 2 && dist > 30) {
						flCadre = true;
					}
				}

				// SHOW LIFE
				if (KeyboardManager.isDown(KeyboardManager.ENTER)) {
					if (!flShowLife) {
						for (sp in aList)
							sp.showLife();
						flShowLife = true;
					}
				} else {
					if (flShowLife) {
						for (sp in aList)
							sp.hideLife();
						flShowLife = false;
					}
				}

				// RENFORT
				if (Cs.GAME_MODE == 0) {
					renfort += Timer.tmod;
					if (renfort >= RENFORT[renfortList.length]) {
						updateRenfortTable();
					}
				}

				// BONUS
				checkBonus();

				// CHECK GAME OVER
				if (aList.length == 0) {
					stats.d = Std.int(dif);
					var p = {};
					Reflect.setField(p, "$b", stats.b);
					Reflect.setField(p, "$l", stats.l);
					Reflect.setField(p, "$k", stats.k);
					Reflect.setField(p, "$d", stats.d);
					#if debug
					// test harness: state of the game at its end (compared between a game and its replay)
					var ax = 0.0;
					for (sp in bList)
						ax += sp.x * 3 + sp.y;
					untyped js.Browser.window.__over = {
						frame: frameCount,
						score: KadoKadeoManager.kkm.score.get(),
						dif: dif,
						aliens: bList.length,
						ax: ax,
						bonus: bonusList.length,
						stats: haxe.Json.stringify(p)
					};
					#end
					KadoKadeoManager.kkm.gameOver(p);
					step = 1;
					pressed = false;
					renfort = 0;
					updateRenfortTable();
				}
			case 1:
		}
		// DIF
		dif += Cs.DIF_RATE * Timer.tmod;
		updateWave();

		// SCROLL
		if (KeyboardManager.isDown(KeyboardManager.SPACE)) {
			if (flSpaceRelease) {
				switch (Cs.SPACE_MODE) {
					case 0:
						selectAll();
					case 1:
						inverseAll();
				}
			}
			flSpaceRelease = false;
		} else {
			flSpaceRelease = true;
		}

		// BOUNCE
		bounce();
		// SPRITES
		var list = sList.copy();
		for (sp in list)
			sp.update();
	}

	function updateWave() {
		if (waveTimer < 0) {
			var pos = Cs.getOutPos(20 + dif);

			while (danger < dif) {
				var sp = newAlien();

				if (sp != null) {
					sp.x = pos.x + (Seed.rand() * 2 - 1) * 20;
					sp.y = pos.y + (Seed.rand() * 2 - 1) * 20;
					sp.angle = sp.getAng({x: Cs.mcw * 0.5, y: Cs.mch * 0.5});
					sp.hp = sp.hpMax;
					danger += sp.value;
				}
			}
			waveTimer = 350 + Seed.rand() * 150;
		} else {
			var multi = 1;
			if (bList.length == 0)
				multi += 10;
			waveTimer -= multi * Timer.tmod;
		}
	}

	function checkBonus() {
		var i = 0;
		while (i < bonusList.length) {
			var o = bonusList[i];
			o.timer -= Timer.tmod;
			if (o.timer < 10) {
				o.sp.root._xscale = o.timer * 10;
				o.sp.root._yscale = o.sp.root._xscale;
			}
			if (o.timer < 0) {
				stats.l[o.type]++;
				o.sp.kill();
				bonusList.splice(i--, 1);
			} else {
				for (al in aList) {
					if (al.getDist(o.sp) < 10 + al.ray) {
						switch (o.type) {
							case 0:
								KadoKadeoManager.kkm.addScore(Cs.C500);
							case 1:
								KadoKadeoManager.kkm.addScore(Cs.C2000);
							case 2:
								KadoKadeoManager.kkm.addScore(Cs.C5000);
							case 3:
								renfort += 1000;
							case 4:
								renfort += 5000;
							case 10 | 11 | 12 | 13:
								spawnRenfort(o.type - 10, o.sp);
						}
						stats.b[o.type]++;
						o.sp.kill();
						bonusList.splice(i--, 1);
						break;
					}
				}
			}
			i++;
		}
	}

	function bounce() {
		for (i in 0...bounceList.length) {
			var sp = bounceList[i];
			for (n in (i + 1)...bounceList.length) {
				var sp2 = bounceList[n];
				var dif = sp.getDist(sp2) - (sp2.ray + sp.ray);
				if (dif < 0) {
					var a = sp.getAng(sp2);
					var ca = Cs.cos(a);
					var sa = Cs.sin(a);

					var c = sp.mass / (sp.mass + sp2.mass);
					if (sp.mass + sp2.mass == 0)
						c = 0.5;

					sp.x += ca * dif * c;
					sp.y += sa * dif * c;
					sp2.x -= ca * dif * (1 - c);
					sp2.y -= sa * dif * (1 - c);
				}
			}
		}
	}

	function updateRenfortTable() {
		var m = 4;
		while (renfortList.length > 0)
			renfortList.pop().removeMovieClip();
		for (i in 0...RENFORT.length) {
			if (RENFORT[i] > renfort)
				return;
			var mc = dm.add(new Clip("mcRenfort"), DP_INTERFACE);
			mc.gotoAndStop(i + 1);
			mc._x = m + i * (20 + m);
			mc._y = m;
			mc.updateState();
			renfortList.push(mc);
		}
	}

	function spawnRenfort(n:Int, c:{x:Float, y:Float}) {
		var sp:Ally = null;
		if (c == null)
			c = getListCenter(aList);
		switch (n) {
			case 0:
				sp = new Marine();
			case 1:
				sp = new Grenadier();
			case 2:
				sp = new Medic();
			case 3:
				sp = new Jeep();
		}
		sp.x = c.x;
		sp.y = c.y;
		sp.hp = sp.hpMax;
		sp.light = 100;

		if (Ally.sel.length > 0) {
			sp.addToSel();
		}

		renfort -= RENFORT[n];
		updateRenfortTable();

		// EFFET
		var mc = dm.add(new Clip("partOnde"), DP_SHADOW);
		mc._x = sp.x;
		mc._y = sp.y;
		mc._xscale = sp.ray * 2.5;
		mc._yscale = sp.ray * 2.5;
		mc.updateState();

		var max = 8;
		var cc = 0.7;
		for (i in 0...12) {
			var a = i / max * 6.28 + (Seed.randVfx() * 2 - 1) * 0.2;
			var ca = Math.cos(a);
			var sa = Math.sin(a);
			var speed = 2 + Seed.randVfx() * 1.5;
			var p = new Part(dm.add(new Clip("partPaillette"), DP_PART));
			p.x = sp.x + ca * sp.ray * cc;
			p.y = sp.y + sa * sp.ray * cc;
			p.vx = ca * speed;
			p.vy = sa * speed;
			p.vr = 30 * (Seed.randVfx() * 2 - 1);
			p.frict = 0.92;
			p.timer = 10 + Seed.randVfx() * 10;
			p.fadeType = 0;
			p.setScale(80 + Seed.randVfx() * 40);
			p.root._rotation = Seed.randVfx() * 360;
		}
	}

	function getListCenter(list:Array<Ally>):{x:Float, y:Float} {
		var xMin = Math.POSITIVE_INFINITY;
		var xMax = 0.0;
		var yMin = Math.POSITIVE_INFINITY;
		var yMax = 0.0;
		for (al in list) {
			xMin = Math.min(xMin, al.x);
			xMax = Math.max(xMax, al.x);
			yMin = Math.min(yMin, al.y);
			yMax = Math.max(yMax, al.y);
		}
		return {
			x: xMin + (xMax - xMin) * 0.5,
			y: yMin + (yMax - yMin) * 0.5
		};
	}

	function newAlien():Alien {
		if (Seed.random(2) == 0) {
			return new Runner();
		}
		if (Seed.random(6) == 0 && dif > 5) {
			return new Tanker();
		}
		if (Seed.random(48) == 0 && dif > 24) {
			return new Octopus();
		}
		if (Seed.random(32) == 0 && dif > 38) {
			return new Executor();
		}
		return null;
	}

	#if debug
	// test harness: an alien of a type (0 runner, 1 tanker, 2 octopus, 5 executor)
	public function debugAlien(type:Int):Alien {
		return switch (type) {
			case 1: new Tanker();
			case 2: new Octopus();
			case 5: new Executor();
			default: new Runner();
		}
	}
	#end

	// CONTROL SOURIS
	function startClick() {
		scTimer = 0;
		scp = {
			x: mouseX(),
			y: mouseY()
		};
	}

	function releaseClick() {
		scTimer = null;
		if (flCadre) {
			selectCadre();
			flCadre = false;
			return;
		}

		// CADRE
		var m = 4;
		for (i in 0...renfortList.length) {
			var xMin = m + i * (20 + m);
			var yMin = m;
			var xMax = m + i * (20 + m) + 20;
			var yMax = m + 20;
			if (mouseX() > xMin && mouseX() < xMax && mouseY() > yMin && mouseY() < yMax) {
				spawnRenfort(i, null);
				return;
			}
		}

		switch (Cs.SELECT_MODE) {
			case 0:
				if (!selectAlly() && Ally.sel.length > 0) {
					gotoMouse();
					if (!KeyboardManager.isDown(KeyboardManager.SPACE))
						Ally.flushSelect();
				}
			default:
				if (!selectAlly()) {
					gotoMouse();
				}
		}
	}

	function selectAll() {
		Ally.flushSelect();
		for (al in aList) {
			if (al.flSelectable) {
				al.addToSel();
			}
		}
	}

	function inverseAll() {
		var oldSel = Ally.sel.copy();
		Ally.flushSelect();

		for (al in aList) {
			var flAdd = true;
			var n = 0;
			while (n < oldSel.length) {
				if (al == oldSel[n]) {
					flAdd = false;
					oldSel.splice(n--, 1);
					break;
				}
				n++;
			}
			if (flAdd)
				al.addToSel();
		}
	}

	function selectAlly():Bool {
		for (sp in aList) {
			if (sp.getDist({x: mouseX(), y: mouseY()}) < sp.ray * Cs.SELECT_TRESHOLD) {
				sp.selectOne();
				return true;
			}
		}
		return false;
	}

	function gotoMouse() {
		var c = getListCenter(Ally.sel);
		var centerCoef = 0.8;
		for (al in Ally.sel) {
			var wp = {
				x: Cs.mm(al.ray, mouseX() - (c.x - al.x) * centerCoef, Cs.mcw - al.ray),
				y: Cs.mm(al.ray, mouseY() - (c.y - al.y) * centerCoef, Cs.mch - al.ray),
				ray: null
			};
			al.setWaypoint(wp);
		}
	}

	function drawCadre() {
		var mx = mouseX();
		var my = mouseY();
		draw.lineStyle(6, 0x00FF00, 0.15);
		draw.moveTo(mx, my);
		draw.lineTo(mx, scp.y);
		draw.lineTo(scp.x, scp.y);
		draw.lineTo(scp.x, my);
		draw.lineTo(mx, my);
		draw.lineStyle(1, 0x99FF99, 1);
		draw.moveTo(mx, my);
		draw.lineTo(mx, scp.y);
		draw.lineTo(scp.x, scp.y);
		draw.lineTo(scp.x, my);
		draw.lineTo(mx, my);
	}

	function selectCadre() {
		Ally.flushSelect();
		for (al in aList) {
			if (al.flSelectable) {
				var xMin = Math.min(scp.x, mouseX());
				var xMax = Math.max(scp.x, mouseX());
				var yMin = Math.min(scp.y, mouseY());
				var yMax = Math.max(scp.y, mouseY());

				var m = al.ray * Cs.SELECT_TRESHOLD;
				if (al.x + m > xMin && al.x - m < xMax && al.y + m > yMin && al.y - m < yMax) {
					al.addToSel();
				}
			}
		}
	}

	// the colour transforms (light of a new soldier) are colour matrix filters: their shader compiled at the start
	function warmShaders() {
		var renderer:Dynamic = KadoKadeoManager.kkm.renderer;
		var holder = new Container();
		var s = new PixiSprite(Texture.WHITE);
		s.filters = [new ColorMatrixFilter()];
		holder.addChild(s);
		var rt:RenderTexture = (cast RenderTexture : Dynamic).create({width: 32, height: 32});
		renderer.render(holder, {renderTexture: rt, clear: true});
		holder.destroy({children: true});
		rt.destroy(true);
	}

	public function destroy():Void {
		if (!isReplay) {
			var canvas:Dynamic = KadoKadeoManager.kkm.canvas;
			canvas.removeEventListener("pointerdown", onPointerDown);
		}
		Clip.flushRemoved();
	}
}

// ---------------------------------------------------------------- Sprite, Phys, Part, Gibs, Grenade
class Sprite {
	public var x:Float;
	public var y:Float;
	public var root:ASprite;

	// (the first position is not interpolated from the place it was attached at)
	var placed:Bool;

	public function new(mc:ASprite) {
		root = mc;
		Cs.game.sList.push(this);
		x = 0;
		y = 0;
		placed = false;
		root._x = -1000;
		root._y = -1000;
	}

	public function update() {
		root._x = x;
		root._y = y;
		if (!placed) {
			placed = true;
			root.updateState();
		}
	}

	public function kill() {
		root.removeMovieClip();
		Cs.game.sList.remove(this);
	}

	public function updatePos() {
		root._x = x;
		root._y = y;
	}

	public function getDist(o:{x:Float, y:Float}):Float {
		var dx = o.x - x;
		var dy = o.y - y;
		return Math.sqrt(dx * dx + dy * dy);
	}

	public function getAng(o:{x:Float, y:Float}):Float {
		var dx = o.x - x;
		var dy = o.y - y;
		return Cs.atan2(dy, dx);
	}

	public function toward(o:{x:Float, y:Float}, c:Float, lim:Float) {
		var dx = o.x - x;
		var dy = o.y - y;
		x += Cs.mm(-lim, dx * c, lim);
		y += Cs.mm(-lim, dy * c, lim);
	}

	public function isOut(m:Float):Bool {
		return (x < -m || x > Cs.mcw + m || y < -m || y > Cs.mch + m);
	}
}

class Phys extends Sprite {
	public var ray:Float;
	public var weight:Null<Float>;
	public var frict:Null<Float>;
	public var vx:Float;
	public var vy:Float;
	public var mass:Float;

	public function new(mc:ASprite) {
		super(mc);
		ray = 0;
		frict = 0.95;
		vx = 0;
		vy = 0;
		mass = 1;
	}

	override public function update() {
		super.update();

		if (weight != null) {
			vy += weight * Timer.tmod;
		}

		if (frict != null) {
			var f = Math.pow(frict, Timer.tmod);
			vx *= f;
			vy *= f;
		}

		x += vx * Timer.tmod;
		y += vy * Timer.tmod;
	}

	public function speedToward(o:{x:Float, y:Float}, c:Float, lim:Float) {
		var dx = o.x - x;
		var dy = o.y - y;
		vx += Cs.mm(-lim, dx * c, lim);
		vy += Cs.mm(-lim, dy * c, lim);
	}
}

class Part extends Phys {
	public var timer:Null<Float>;
	public var fadeType:Null<Int>;
	public var fadeLimit:Float;
	public var scale:Float;
	public var vr:Null<Float>;
	public var rFrict:Float;

	public function new(mc:ASprite) {
		super(mc);
		fadeLimit = 10;
		scale = 100;
		rFrict = 1;
	}

	public function setScale(sc:Float) {
		scale = sc;
		root._xscale = sc;
		root._yscale = sc;
	}

	override public function update() {
		super.update();
		if (vr != null) {
			vr *= rFrict;
			root._rotation += vr * Timer.tmod;
		}
		if (timer != null) {
			timer -= Timer.tmod;
			if (timer < fadeLimit) {
				var c = timer / fadeLimit;
				switch (fadeType) {
					case 0:
						root._xscale = scale * c;
						root._yscale = root._xscale;
					default:
						root._alpha = c * 100;
				}
				if (timer < 0) {
					kill();
				}
			}
		}
	}
}

class Gibs extends Part {
	var flDropBlood:Bool;

	public var z:Float;
	public var vz:Float;
	public var wz:Float;

	var shadow:Clip;

	public function new(mc:ASprite) {
		flDropBlood = false;
		if (mc == null) {
			flDropBlood = true;
			mc = Cs.game.dm.add(new Clip("partAlien"), Game.DP_PART);
		}
		super(mc);
		shadow = Cs.game.dm.add(new Clip("mcGrenShade"), Game.DP_SHADOW);
		shadow._alpha = 50;
		shadow._x = -1000;
		z = 0;
		vz = 0;
		wz = 1;
	}

	override public function setScale(sc:Float) {
		super.setScale(sc);
		shadow._xscale = sc * 0.8;
		shadow._yscale = sc * 0.8;
	}

	override public function update() {
		var first = !placed;
		super.update();
		shadow._x = x;
		shadow._y = y;
		shadow._alpha = root._alpha * 0.5;

		vz -= wz * Timer.tmod;
		vz *= frict;
		z += vz * Timer.tmod;

		if (z < 0) {
			z = 0;
			vz *= -0.8;
		}

		root._y -= z;
		if (first) {
			root.updateState();
			shadow.updateState();
		}

		var c = 0.5;
		if (flDropBlood && Seed.randVfx() / Timer.tmod < 0.2) {
			var p = new Part(Cs.game.dm.add(new Clip("partBlood"), Game.DP_PART));
			p.x = root._x + (Seed.randVfx() * 2 - 1) * 5;
			p.y = root._y + (Seed.randVfx() * 2 - 1) * 5;
			p.vx = vx * c;
			p.vy = vy * c;
			p.setScale(30 + Seed.randVfx() * 70);
			p.timer = 10 + Seed.randVfx() * 10;
			(cast p.root : Clip).gotoAndStop(Seed.randomVfx(p.root._totalframes) + 1);
			p.fadeType = 0;
		}
	}

	override public function kill() {
		shadow.removeMovieClip();
		super.kill();
	}
}

class Grenade extends Phys {
	static inline var SPEED = 6;
	static inline var RAY = 40;
	static inline var DAMAGE = 8;

	var parcouru:Float;
	var max:Float;
	var tx:Float;
	var ty:Float;
	var sx:Float;
	var sy:Float;

	var shadow:Clip;

	public function new() {
		super(Cs.game.dm.add(new Clip("mcGrenade"), Game.DP_FLY));
		shadow = Cs.game.dm.add(new Clip("mcGrenShade"), Game.DP_SHADOW);
		shadow._x = -1000;
	}

	public function setPos(px:Float, py:Float) {
		sx = px;
		sy = py;
		x = sx;
		y = sy;
	}

	public function setTrg(px:Float, py:Float) {
		max = getDist({x: px, y: py});
		parcouru = 0;
		tx = px;
		ty = py;
	}

	override public function update() {
		parcouru = Math.min((parcouru + SPEED * Timer.tmod), max);

		var c = parcouru / max;

		x = sx * (1 - c) + tx * c;
		y = sy * (1 - c) + ty * c;
		shadow._x = x;
		shadow._y = y;
		if (!placed)
			shadow.updateState();
		y -= Cs.sin(c * 3.14) * (max * 0.4);

		if (parcouru == max) {
			var list = Cs.game.bList.copy();
			for (sp in list) {
				var dist = getDist(sp);
				if (dist < RAY + sp.ray) {
					sp.hit(DAMAGE, getAng(sp));
				}
			}
			var mc = Cs.game.dm.add(new Clip("partOnde"), Game.DP_PART);
			mc._x = x;
			mc._y = y;
			mc._xscale = RAY * 2;
			mc._yscale = mc._xscale;
			mc.updateState();

			mc = Cs.game.dm.add(new Clip("partExplosion"), Game.DP_PART);
			mc._x = x;
			mc._y = y;
			mc._xscale = RAY * 1.7;
			mc._yscale = mc._xscale;
			mc.updateState();

			kill();
			return;
		}

		super.update();
	}

	override public function kill() {
		shadow.removeMovieClip();
		super.kill();
	}
}
