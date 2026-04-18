package starfang;

import haxe.io.UInt16Array;
import common_haxe_avm1.KeyboardManager;
import mt.bumdum.Part;
import mt.bumdum.Sprite;
import mt.bumdum.Lib.Num;
import mt.DepthManager;
import mt.Timer;
import kado.KadoKadeoManager;

class DashlightSprite extends ASprite {
	public var multi:Float;
}

@:expose('GameStarfang')
class Game implements kado.GameInterface {
	public static var FL_CHEAT = false;

	public static var DP_INTERFACE = 12;
	public static var DP_SHOT = 10;
	public static var DP_PARTS = 9;
	public static var DP_BADS = 8;
	public static var DP_HERO = 7;
	public static var DP_DRAW = 5;
	public static var DP_UNDERPARTS = 3;
	public static var DP_BG = 3;

	public var stats:{
		k:Array<Int>,
		b:Array<Int>,
	};

	var flCheatReady:Bool;

	var lvl:Int;
	var step:Int;

	public var flOption:Bool;

	var monsterlvl:Float;
	var phaseTimer:Float;
	var scrollDash:Float;
	var scrollSpeed:Float;

	public var shotList:Array<Shot>;
	public var badsList:Array<Bads>;
	public var bonusList:Array<Bonus>;

	var dashLightList:Array<DashlightSprite>;

	public var dm:DepthManager;

	public var hero:Hero;

	public var root:ASprite;

	var bg:ASprite;
	var draw:ASprite;

	public var inter:Inter;

	public function new(root:ASprite, ?isReplay:Bool = false) {
		var replayKeys = new UInt16Array(13);
		replayKeys[0] = KeyboardManager.RIGHT;
		replayKeys[1] = KeyboardManager.DOWN;
		replayKeys[2] = KeyboardManager.LEFT;
		replayKeys[3] = KeyboardManager.UP;
		replayKeys[4] = KeyboardManager.SPACE;
		replayKeys[5] = KeyboardManager.CONTROL;
		replayKeys[6] = KeyboardManager.D;
		replayKeys[7] = KeyboardManager.S;
		replayKeys[8] = KeyboardManager.Q;
		replayKeys[9] = KeyboardManager.Z;
		replayKeys[10] = KeyboardManager.A;
		replayKeys[11] = KeyboardManager.W;
		replayKeys[12] = KeyboardManager.ENTER;
		KadoKadeoManager.kkm.replay.init({
			recordedKeys: replayKeys,
			recordInputs: true,
			recordEvents: false,
		});

		Cs.game = this;
		dm = new DepthManager(root);
		this.root = root;

		shotList = new Array();
		badsList = new Array();
		bonusList = new Array();

		bg = dm.attach("mcBg", DP_BG);

		hero = new Hero(dm.empty(DP_HERO));
		hero.x = Cs.mcw * 0.5;
		hero.y = Cs.mch * 0.5;

		inter = new Inter(dm.empty(DP_INTERFACE));
		inter.h = hero;

		draw = dm.empty(DP_DRAW);
		stats = {
			k: [0, 0, 0, 0, 0],
			b: [],
		};

		lvl = 1;

		initStep(1);

		if (FL_CHEAT) {
			flCheatReady = true;
		}
	}

	// function onKeyPress(){
	// 	if(flCheatReady){
	// 		var n = KeyboardManager.lastDown;
	// 		if(n>=96 && n<107 ){
	// 			hero.updateSecondary(n-96);
	// 		}
	// 		if(n>=49 && n<54 ){
	// 			hero.updateWeapon(n-49);
	// 		}
	// 		if(n>=54 && n<59 ){
	// 			hero.updateSecondary(n-54);
	// 		}
	// 	}
	// 	flCheatReady = false;
	// }
	// function onKeyRelease(){
	// 	flCheatReady = true;
	// }

	function initStep(n) {
		step = n;
		switch (n) {
			case 1:
				var mc = new Part(dm.empty(DP_INTERFACE));
				var txt = mc.root.initTextField("txt", {
					font: "Orbitron",
					size: 90,
					color: 0xFFFFFF,
					align: "left",
				});
				mc.root._x = 0;
				mc.root._y = 0;
				txt.text = "SECTEUR " + lvl;
				mc.timer = 64;
				mc.fadeLimit = 20;
				mc.fadeType = 3;

				flOption = true;
				genMonsters();
			case 2:
				lvl++;
				if (hero != null) {
					hero.wings[0].trg = 0;
					hero.wings[1].trg = 0;
				}
			case 3:
				scrollDash = 0;
				scrollSpeed = 0;
				dashLightList = new Array();
			case _:
		}
	}

	public function update(delta:Float) {
		draw.clear();

		// SPRITE
		Sprite.updateAll();

		switch (step) {
			case 1: // PLAY;
				if (hero != null) {
					hero.control();
				}
				if (badsList.length == 0 && bonusList.length == 0)
					initStep(2);
			case 2:
				if (shotList.length == 0)
					initStep(3);
			// Log.print(speed)
			// Log.setColor(0x000000)
			case 3:
				var lim = 0.1;
				if (hero != null) {
					hero.angle -= Num.mm(-lim, hero.angle * 0.2, lim);
					hero.root._rotation = hero.angle / 0.0174;
					var ca = Math.max(0, Math.cos(hero.angle));
					hero.mainFlameTrg = Math.max(0, ca * 100);
					var center = {x: Cs.mcw * 0.5, y: Cs.mch * 0.5};
					hero.toward(center, 0.1, 3 * Cs.NEW_GEN_SCALE);
					var f = Math.pow(0.9, Timer.tmod);
					hero.vx *= f;
					hero.vy *= f;
					scrollDash += Timer.tmod;
					scrollSpeed = ca * Math.max(20 * Cs.NEW_GEN_SCALE - hero.getDist(center), 0) + scrollDash;
					Cs.game.hero.launchSparks(0, Std.int(Math.min(scrollSpeed * 0.1, 5)), scrollSpeed * 0.1);
				}
				if (scrollDash >= 100)
					initStep(4);
				scrollBg();
				updateDashLight();
			case 4:
				if (hero != null) {
					var center = {x: Cs.mcw * 0.5, y: Cs.mch * 0.5};
					hero.toward(center, 0.1, 3 * Cs.NEW_GEN_SCALE);
					Cs.game.hero.launchSparks(0, Std.int(Math.min(scrollSpeed * 0.1, 5)), scrollSpeed * 0.1);
				}
				scrollSpeed *= Math.pow(0.95, Timer.tmod);
				scrollBg();
				updateDashLight();
				if (dashLightList.length == 0) {
					initStep(1);
				}
			case _:
		}
	}

	public function destroy() {}

	function genMonsters() {
		var dif:Float = lvl * 14 - 8;
		while (dif > 0) {
			if (Cs.random(2) == 0) {
				var type = Std.int(Math.min(Cs.random(Std.int(lvl * 0.5)), 4));
				var m = new Asteroid(dm.attach("mcAsteroid" + (type + 1), DP_BADS));
				var max = Math.min(Math.pow(lvl - type, 0.5), 3);
				var size = 2 + Cs.random(Std.int(max));
				m.setInfo(type, size);
				m.initStartPosition();
				dif -= m.dif;
			}
		}
	}

	//

	function scrollBg() {
		bg._x -= scrollSpeed;
		if (bg._x < -900 * Cs.NEW_GEN_SCALE) {
			bg._x += 900 * Cs.NEW_GEN_SCALE;
			bg._prevState.x = bg._x + scrollSpeed;
		}
	}

	function spawnDashLight() {
		if (Cs.random(2) == 0)
			return;
		var mc:DashlightSprite = cast dm.attach("mcDashLight", DP_PARTS);
		mc._x = Cs.mcw + Cs.rand() * 100 * Cs.NEW_GEN_SCALE;
		mc._y = Cs.rand() * Cs.mch;
		mc._yscale = 50 + Cs.rand() * 50;
		mc._xscale = mc._yscale;

		mc.multi = 1 + Math.random() * 3;
		dashLightList.push(mc);
	}

	function updateDashLight() {
		for (i in 0...Std.int(scrollSpeed * 0.1)) {
			spawnDashLight();
		}
		var i = 0;
		while (i < dashLightList.length) {
			var mc = dashLightList[i];
			mc._x -= scrollSpeed * (mc._yscale / 100);
			mc._xscale = mc._yscale + Math.max(scrollSpeed - 30, 0) * 10 * mc.multi;
			mc._alpha -= 4 * (mc._yscale / 100) * Timer.tmod;
			if (mc._x < -mc._width || mc._alpha < 3) {
				mc.removeMovieClip();
				dashLightList.splice(i, 1);
				continue;
			}
			i++;
		}
	}
}
