package toutcaen;

import common_haxe_avm1.MouseManager;
import common_haxe_avm1.kac.ProtectedInt;
import common_haxe_avm1.KeyboardManager;
import common_haxe_avm1.KKApi;
import haxe.io.UInt16Array;
import kado.KadoKadeoManager;
import mt.DepthManager;
import mt.Timer;
import mt.bumdum.Sprite;
import mt.bumdum.Phys;
import mt.bumdum.Lib;

enum Step {
	_Play;
	_GameOver;
}

class Fish extends Phys {
	public var type:Int;
}

class PelSprite extends Phys {
	public var head:ASprite;
	public var sens:Int;
}

class SlotSprite extends ASprite {
	public var arrow:ASprite;
	public var field:Text;
}

class McBarSprite extends ASprite {
	public var fieldLevel:Text;
	public var slot:SlotSprite;
	public var b:ASprite;
}

@:expose('GameToutCaen')
class Game implements kado.GameInterface {
	public static var FL_DISPLAY_SCORE = true;
	public static var FL_GOLDEN_FISH = true;

	// CONSTANTES
	static var DP_BG = 2;
	static var DP_PELICAN = 3;
	static var DP_FISH = 4;
	static var DP_PARTS = 5;
	static var DP_BUBBLES = 7;
	static var DP_FRONT = 10;

	static var SKY = KadoKadeoManager.I(50);
	static var SEA = KadoKadeoManager.I(230);

	static var PSPEED = KadoKadeoManager.S(3);
	static var FALL = KadoKadeoManager.S(0.4);
	static var FRAY = KadoKadeoManager.I(8);
	static var BEC = KadoKadeoManager.I(28);
	static var BRAY = KadoKadeoManager.I(14);

	// static var a:Int;
	// VARIABLES
	var lvl:ProtectedInt;

	var flGoldenFish:Bool;
	var flPress:Bool;
	var flAbove:Bool;
	var frame:Float;
	var plouf:Float;
	var freeze:Float;
	var drip:Float;
	var timer:Float;
	var fishDisplayTimer:Float;

	var pool:Int;
	var step:Step;

	var fList:Array<Fish>;
	var gList:Array<Phys>;
	var bList:Array<Phys>;

	// MOVIECLIPS
	var pel:PelSprite;
	var sea:ASprite;
	var head:ASprite;
	var rond:ASprite;
	var mcBar:McBarSprite;

	public var dm:DepthManager;
	public var root:ASprite;
	public var bg:ASprite;
	public var me:Game;

	public function new(root:ASprite, ?isReplay:Bool = false) {
		var replayKeys = new UInt16Array(3);
		replayKeys[0] = KeyboardManager.SPACE;
		replayKeys[1] = KeyboardManager.ARROW_DOWN;
		replayKeys[2] = KeyboardManager.S;
		var replayMouseButtons = new UInt16Array(1);
		replayMouseButtons[0] = MouseManager.BUTTON_LEFT;
		KadoKadeoManager.kkm.replay.init({
			recordedKeys: replayKeys,
			recordInputs: true,
			recordEvents: false,
			recordMousePosition: false,
			recordedMouseButtons: replayMouseButtons,
		});

		this.root = root;
		me = this;
		dm = new DepthManager(root);
		bg = dm.attach("mcBg", DP_BG);
		init();
	}

	function init() {
		flAbove = true;
		freeze = 0;
		plouf = 0;
		frame = 0;
		lvl = new ProtectedInt(0);
		pool = 0;

		gList = [];
		bList = [];
		fList = [];

		initInter();
		attachElements();
		nextLevel();

		step = _Play;
	}

	function attachElements() {
		// SEA
		sea = dm.attach("mcPelicanSea", DP_FRONT);
		// sea._y = Cs.mch;
		sea._y = SEA;
		// sea.blendMode = "overlay";

		// PELICAN
		pel = cast new Phys(dm.attach("mcPelican", DP_PELICAN));
		pel.root.play();
		pel.root.loop = true;
		pel.head = pel.root.attachMovie("head", "head");
		pel.head._x = KadoKadeoManager.I(18);
		pel.head._y = KadoKadeoManager.I(-3);
		pel.head._xscale = 44;
		pel.head._yscale = 44;
		pel.x = KadoKadeoManager.I(8);
		pel.y = SKY;
		pel.sens = 1;
		pel.vx = pel.sens * PSPEED;
		pel.setScale(120);
		// Filt.glow(pel.root,2,1,0);

		head = pel.head;
		head.stop();
	}

	// UPDATE
	public function update(delta:Float) {
		flPress = MouseManager.isButtonDown(MouseManager.BUTTON_LEFT)
			|| KeyboardManager.isDown(KeyboardManager.SPACE)
			|| KeyboardManager.isDown(KeyboardManager.ARROW_DOWN)
			|| KeyboardManager.isDown(KeyboardManager.S);

		// for(i in 0...200000){var a = i*5+6;}
		movePelican();

		moveFish();
		moveGoutte();
		moveBubble();
		updateTimer();
		Sprite.updateAll();
	}

	// PELICAN
	function movePelican() {
		// CHECK SIDE
		var m = 0;
		if (pel.x < m || pel.x > Cs.mcw - m) {
			pel.sens *= -1;
			pel.x = Num.mm(m, pel.x, Cs.mcw - m);
			pel.root._xscale = pel.sens * 100;
			pel.vx = pel.sens * PSPEED;
			// if( pel.y > SKY+100 )freeze=50;	// FRZ COGNE
		}

		// PLOUF
		if (pel.y > SEA - KadoKadeoManager.I(10)) {
			if (flAbove) {
				splash();
				flAbove = false;
			}
			if (Seed.randVfx() < 0.8) {
				var p = new Phys(dm.attach("partPelicanBubble", DP_BUBBLES));
				p.x = pel.x + (Seed.randVfx() * 2 - 1) * KadoKadeoManager.S(10);
				p.y = pel.y + (Seed.randVfx() * 2 - 1) * KadoKadeoManager.S(10);
				p.weight = -KadoKadeoManager.S(0.1 + Seed.randVfx() * 0.3);
				p.scale = 30 + Seed.randVfx() * 70;
				p.vx = pel.vx * 0.8;
				p.vy = pel.vy * 0.8;
				p.frict = 0.92;
				p.setScale(50 - p.weight * 150);
				// p.root._alpha = 50;
				bList.push(p);
			}

			if (!flPress || pel.y > SEA + KadoKadeoManager.I(14)) {
				freeze = 60; // FRZ BACK
			}

			// FORCE
			pel.vy -= KadoKadeoManager.S(0.1) * Timer.tmod;

			// RETOUR

			if (pel.vy > KadoKadeoManager.S(-5)) {
				var a = Math.atan2(pel.vy, pel.vx);
				var p = {
					x: pel.x + Math.cos(a) * BEC,
					y: pel.y + Math.sin(a) * BEC
				}

				/*
					if(rond==null){
						rond = dm.attach("mcRoundTest",DP_FRONT);
						rond._xscale = rond._yscale = BRAY*2;
					}
					rond._x = p.x;
					rond._y = p.y;
				 */

				var list = fList.copy();

				for (fish in list) {
					var dx = Math.max(Math.abs(fish.x - p.x) - KadoKadeoManager.S(10), 0);
					var dy = fish.y - p.y;
					var dist = Math.sqrt(dx * dx + dy * dy);
					if (dist < BRAY) {
						fList.remove(fish);
						fish.kill();
						pool++;
						if (fish.type == 1)
							flGoldenFish = true;
						var frame = pool + 1;
						if (flGoldenFish)
							frame += 20;
						head.gotoAndStop(frame);

						break;
					}
					// ESCAPE

					if (fish.type == 1 && dist < KadoKadeoManager.S(100)) {
						var dx = fish.x - p.x;
						var adx = Math.abs(dx);
						var sens = adx / dx;
						fish.x += (KadoKadeoManager.S(100) - dist) * Math.abs(fish.vx) * 0.03 / KadoKadeoManager.I(1) * sens;
					}
				}
			}
		} else {
			if (!flAbove) {
				splash(0.5);
				drip = 0;
				if (pool > 0) {
					displayFish(pool);
				}
			}

			flAbove = true;
		}

		if (freeze > 0)
			freeze -= Timer.tmod;

		// CONTROL
		if (flPress && freeze <= 0 && step == _Play) {
			var lim = KadoKadeoManager.S(6);
			pel.vy = Num.mm(-lim, (pel.vy + FALL * Timer.tmod), lim);
		} else {
			var dy = SKY - pel.y;
			var lim = KadoKadeoManager.S(0.3);
			pel.vy += Num.mm(-lim, dy * 0.01, lim) * Timer.tmod;
			pel.vy *= Math.pow(0.95, Timer.tmod);
		}

		// EAT

		if (pel.y < SKY && pool > 0 && step == _Play) {
			// displayFish(pool);
			mcBar.slot.gotoAndPlay(2);
			fishDisplayTimer = 20;

			var sc:Float = (2 * pool - 1) * KKApi.val(Cs.SCORE);
			sc *= 0.5 + (timer / 100) * 0.5;
			var sci = Math.ceil(sc / 50) * 50;

			if (flGoldenFish) {
				flGoldenFish = false;
				sci *= 2;
			}

			KadoKadeoManager.kkm.addScore(KKApi.const(sci));

			if (FL_DISPLAY_SCORE) {
				var mc = dm.empty(DP_FRONT);
				var p = new Phys(mc);
				p.timer = 48;
				p.fadeType = 4;
				p.fadeLimit = 16;
				p.x = KadoKadeoManager.I(50);
				p.y = KadoKadeoManager.I(20);
				var score = mc.initTextField("field", {
					font: "Kozuka Gothic Pro H",
					size: 24,
					color: 0x0066CC,
					stroke: "#FFFFFF",
					strokeThickness: KadoKadeoManager.I(2),
				});
				score.text = "+" + sci;
			}

			freeze = 0;
			pool = 0;
			head.gotoAndStop(1);
			if (fList.length == 0)
				nextLevel();
		}

		// GFX
		pel.root._rotation = (pel.vy / pel.vx) * 40;
		frame = (frame + Math.max(0, -pel.vy * 0.5 + 2)) % 25;
		pel.root.gotoAndStop(Std.string(Std.int(frame) + 1));

		// DRIP
		if (drip != null) {
			drip += 0.6 * Timer.tmod;
			if (Seed.randomVfx(Std.int(drip)) < 3) {
				var p = newGoutte();
				p.x += (Seed.randVfx() * 2 - 1) * KadoKadeoManager.S(5);
				p.y += (Seed.randVfx() * 2 - 1) * KadoKadeoManager.S(5);
				if (drip > 20)
					drip = null;
			}
		}
	}

	/*
		Papoyo le toucan vagabond s'est perdu lors d'une migration improvis� vers la Su�de.
		Il est maintenant perdu au dessus du port de Caen et il a tr�s faim !
		Aidez le a plonger pour trouver les bancs de d�licieux poissons des docks.
	 */
	// FISH
	function genFish() {
		var flGold = FL_GOLDEN_FISH && lvl > 1;
		var max = 2 + lvl.get();
		for (i in 0...max) {
			var type = 0;
			if (flGold && Seed.random(3 + lvl) == 0) {
				type = 1;
				flGold = false;
			}
			var sp:Fish = cast new Phys(dm.attach("mcFish" + (type + 1), DP_FISH));
			var sens = Seed.random(2) * 2 - 1;
			sp.x = Cs.mcw * 0.5 - (Cs.mcw * 0.5 + FRAY + Seed.rand() * KadoKadeoManager.S((lvl.get() + 2) * 15)) * sens;
			sp.y = SEA + KadoKadeoManager.I(15) + Seed.rand() * KadoKadeoManager.S(Math.min(26 + lvl, 55));
			// sp.x = FRAY + Math.random()*Cs.mcw-2*FRAY;
			// sp.y = SEA + 27 + (Math.random()*2-1)*12;
			sp.vx = KadoKadeoManager.S(0.3 + lvl.get() * 0.05 + Seed.rand());

			// sp.root._xscale = 100*sens;
			sp.vx *= sens;
			sp.type = type;
			fList.push(sp);
		}
	}

	function moveFish() {
		for (fish in fList) {
			fish.x += fish.vx * Timer.tmod;

			var m = Math.abs(fish.vx) * 5 + FRAY;
			if (fish.x < m)
				fish.root.prevFrame();
			else if (fish.x > Cs.mcw - m)
				fish.root.nextFrame();
			else if (fish.vx > 0)
				fish.root.prevFrame();
			else if (fish.vx < 0)
				fish.root.nextFrame();

			if ((fish.x < FRAY || fish.x > Cs.mcw - FRAY) && (fish.x - Cs.mcw * 0.5) * fish.vx > 0) {
				fish.x = Num.mm(FRAY, fish.x, Cs.mcw - FRAY);
				fish.vx *= -1;
				// fish.root._xscale = 100*(fish.vx/Math.abs(fish.vx));
			}
		}
	}

	// LEVEL
	function nextLevel() {
		timer = 100;
		lvl += 1;
		genFish();
		mcBar.fieldLevel.text = "NIVEAU " + lvl.get();
	}

	// INTERFACE
	function initInter() {
		mcBar = cast dm.attach("mcBar", DP_FRONT);
		mcBar.fieldLevel = mcBar.initTextField("fieldLevel", {
			font: "Kozuka Gothic Pro H",
			size: 30,
			color: 0x0066CC,
			stroke: "#FFFFFF",
			strokeThickness: KadoKadeoManager.I(2),
			x: KadoKadeoManager.I(220),
			y: KadoKadeoManager.I(0)
		});
		mcBar.slot = cast mcBar.createEmptyMovieClip("slot");
		var circle = mcBar.slot.attachMovie("slotCircle", "smc");
		mcBar.slot.arrow = mcBar.slot.attachMovie("arrow");
		mcBar.slot.field = mcBar.slot.initTextField("field", {
			font: "Kozuka Gothic Pro H",
			size: 40,
			color: 0xFFFFFF
		});
		circle._x = KadoKadeoManager.I(25);
		circle._y = KadoKadeoManager.I(20);
		mcBar.slot.arrow._x = KadoKadeoManager.I(25);
		mcBar.slot.arrow._y = KadoKadeoManager.I(20);
		mcBar.slot.field.x = KadoKadeoManager.I(20);
		mcBar.slot.field.y = KadoKadeoManager.I(10);
		mcBar.slot._totalframes = 3;
		mcBar.slot.onFrame.set(1, function() {
			mcBar.slot.field.visible = false;
			mcBar.slot.arrow._visible = true;
			mcBar.slot.arrow.gotoAndStop(1);
		});
		mcBar.slot.onFrame.set(2, function() {
			mcBar.slot.field.visible = false;
			mcBar.slot.arrow._visible = true;
			mcBar.slot.arrow.gotoAndStop(2);
		});
		mcBar.slot.onFrame.set(3, function() {
			mcBar.slot.field.visible = true;
			mcBar.slot.arrow._visible = false;
		});
		mcBar.b = mcBar.attachMovie("bar", "b");
		mcBar.b._x = KadoKadeoManager.I(44);
		mcBar.b._y = KadoKadeoManager.I(-1);
	}

	function updateTimer() {
		// TIMER
		var dec = 0.02 + lvl.get() * 0.015;

		timer = Math.max(timer - dec * Timer.tmod, 0);
		mcBar.b._xscale += (timer - mcBar.b._xscale) * 0.2 * Timer.tmod;

		if (timer == 0 && fList.length > 0) {
			step = _GameOver;
			KadoKadeoManager.kkm.gameOver({});
		}

		//
		/*
			if(freeze>0 && mcBar.slot._currentframe !=3 ){
				mcBar.slot.gotoAndStop(3);
			}else mcBar.slot.gotoAndStop(flPress?2:1);
		 */

		// SLOT

		if (fishDisplayTimer == null) {
			var tr = 0;
			if (flPress && freeze <= 0)
				tr = 180;

			var dr = Num.hMod(tr - mcBar.slot.arrow._rotation, 180);
			mcBar.slot.arrow._rotation += dr * 0.2;
			// mcBar.slot.arrow._xscale = pel.sens * 100;

			if (freeze > 0)
				mcBar.slot.gotoAndStop(2);
			else
				mcBar.slot.gotoAndStop(1);
		} else {
			fishDisplayTimer -= Timer.tmod;
			if (fishDisplayTimer < 0) {
				fishDisplayTimer = null;
				mcBar.slot.gotoAndStop(2);
			}
		}
	}

	function displayFish(n) {
		// trace(n);
		fishDisplayTimer = 100;
		mcBar.slot.gotoAndStop(3);
		mcBar.slot._xscale = 100;
		mcBar.slot.arrow._rotation = 0;

		mcBar.slot.field.text = Std.string(n);
	}

	// FX
	function splash(?c:Float) {
		if (c == null)
			c = 1;
		// GOUTTE
		var max = Math.floor(pel.vy * 2);
		for (i in 0...max) {
			var p = newGoutte();
			p.y = SEA;
			var a = -Seed.randVfx() * 3.14;
			p.vx = Math.cos(a) * KadoKadeoManager.S(2);
			p.vy = Math.sin(a) * KadoKadeoManager.S(5);
		}

		// PLOUF
		for (i in 0...2) {
			var mc = dm.attach("plouf", DP_PARTS);
			mc.play();
			mc.removeOnFrame = 40;
			mc._x = pel.x;
			mc._y = SEA;
			mc._xscale = mc._yscale = (40 + (Math.abs(pel.vy / KadoKadeoManager.I(1)) * 15)) * c;
		}
	}

	function newGoutte() {
		var p = new Phys(dm.attach("partPelicanWater", DP_PARTS));
		p.x = pel.x;
		p.y = pel.y;
		p.weight = KadoKadeoManager.S(0.1 + Seed.randVfx() * 0.15);
		p.scale = 70 + Seed.randVfx() * 60;
		p.root.onFrame.set(12, function() {
			p.kill();
		});
		p.root.play();
		gList.push(p);
		return p;
	}

	function moveGoutte() {
		for (p in gList) {
			if (p.y > SEA) {
				p.y = SEA;
				p.vx = 0;
				p.vy = 0;
				p.weight = 0;
				p.root.play();
				p.root._xscale = (Seed.randomVfx(2) * 2 - 1) * 100;
				// WARNING REMOVE ERROR
			}
		}
	}

	function moveBubble() {
		for (p in bList) {
			if (p.y < SEA || p.y > Cs.mch) {
				p.kill();
			}
		}
	}

	public function destroy():Void {}
}
