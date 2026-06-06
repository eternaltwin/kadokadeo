package crepuscud;

import mt.bumdum.Sprite;
import mt.bumdum.Phys;
import mt.bumdum.Part;
import mt.bumdum.Lib;
import mt.bumdum.Plasma;
import pixi.core.math.Matrix;
import pixi.core.Pixi.BlendModes;
import pixi.core.math.shapes.Rectangle;
import pixi.filters.colormatrix.ColorMatrixFilter;
import pixi.core.text.Text;
import common_haxe_avm1.KKApi;
import common_haxe_avm1.PixelHelper;
import common_haxe_avm1.MouseManager;
import haxe.io.UInt16Array;

enum Step {
	Play;
	GameOver;
}

class McField extends ASprite {
	public var field:Text;
}

class HeroSprite extends ASprite {
	public var gun:ASprite;
}

typedef GROUP = {id:Int};

@:expose('GameCrepuscud')
class Game implements kado.GameInterface {
	public static var GH = 20;
	public static var RGH = 14;
	public static var GY = 0;
	public static var RGY = 0;
	public static var DX = 22;

	public static var DP_BG = 0;
	public static var DP_PLASMA = 1;
	public static var DP_ONDE = 2;
	public static var DP_MISSILE = 3;
	public static var DP_PARTS = 6;
	public static var DP_GROUND = 7;
	public static var DP_INTER = 8;
	public static var DP_SCORE = 9;

	public var flGameOver:Bool;

	public var expl:Int;
	public var fade:Float;

	public var dif:Float;
	public var angle:Float;
	public var totalSpeed:Float;
	public var replenish:Float;

	public var cmun:Int;
	public var munitions:Array<ASprite>;
	public var muniCount:Float;
	public var brushQueueMissile:ASprite;

	public var hero:HeroSprite;
	// public var mcTarget:ASprite;
	public var missiles:Array<Missile>;
	public var patriots:Array<Patriot>;
	public var holes:Array<Float>;

	public var mcExplode:ASprite;

	public var bmpGround:RenderTexture;

	public var step:Step;
	public var plasma:Plasma;
	public var dm:mt.DepthManager;
	public var edm:mt.DepthManager;
	public var root:ASprite;
	public var bg:ASprite;

	public static var me:Game;

	public function new(root:ASprite, ?isReplay:Bool = false) {
		var replayMouseButtons = new UInt16Array(1);
		replayMouseButtons[0] = MouseManager.BUTTON_LEFT;
		KadoKadeoManager.kkm.replay.init({
			recordedKeys: new UInt16Array(0),
			recordInputs: false,
			recordEvents: false,
			recordMousePosition: true,
			recordedMouseButtons: replayMouseButtons,
		});

		this.root = root;
		me = this;
		dm = new mt.DepthManager(root);

		initBg();

		GY = Cs.mch - GH;
		RGY = Cs.mch - RGH;

		flGameOver = false;
		dif = 1;
		totalSpeed = 0;
		replenish = 0;
		expl = 0;

		missiles = [];
		patriots = [];
		munitions = [];
		muniCount = 0;
		cmun = 0;
		incMunition(12);

		initPlasma();
		initDecor();

		initPlay();
	}

	function initBg() {
		bg = dm.empty(DP_BG);
		var bmp = RenderTexture.create(Cs.mcw, Cs.mch);
		bg.attachBitmap(bmp, 0);

		// FOND
		var mc = dm.attach("mcBg", 0);
		bmp.draw(mc, new Matrix());
		mc.removeMovieClip();

		// STARS
		var mc = dm.attach("mcStar", 0);
		for (i in 0...100) {
			var m = new Matrix();
			var py = Math.pow(Seed.randVfx(), 3) * 100 - 5;
			var sc = 0.2 + Seed.randVfx() * 0.8;
			m.scale(sc, sc);
			m.translate(Seed.randVfx() * Cs.mcw, py);

			mc.blendMode = BlendModes.ADD;
			bmp.draw(mc, m);
			mc.blendMode = BlendModes.NORMAL;
		}

		bg.onPress = launchMissile; // TODO à changer, voir le .skills
		bg.useHandCursor = false;
	}

	function initDecor() {
		// BRUSHES
		brushQueueMissile = dm.attach("queueMissile", DP_GROUND);
		brushQueueMissile._visible = false;

		// GROUND
		// bmpGround = new flash.display.BitmapData(Cs.mcw, GH, true, 0x00000000);
		// true = opacité, false = pas d'opacité, 0x00000000 = couleur de remplissage (ici transparente)
		// ici inutile

		bmpGround = RenderTexture.create(Cs.mcw, GH);
		var mc = dm.empty(DP_GROUND);
		var gdm = new mt.DepthManager(mc);
		mc._y = GY;
		mc.attachBitmap(bmpGround, 0);
		Filt.glow(mc, 4, 2, 0xCC6600, true);
		Filt.glow(mc, 2, 2, 0xCC6600); // TODO filt.glow à bannir et à mettre sur l'image directement

		bmpGround.fillRect(new Rectangle(0, GH - RGH, Cs.mcw, RGH), 0x000000);

		// ELEMENTS
		var mc = dm.attach("mcGroundElement", 0);
		var ma = 40;
		for (i in 0...24) {
			var sc = 0.5 + Seed.rand() * 0.5;
			var m = new Matrix();
			m.scale(sc, sc);
			m.translate(ma + Seed.random(Cs.mcw - ma), GH - RGH);
			mc.gotoAndStop(Seed.random(mc._totalframes) + 1);
			bmpGround.draw(mc, m);
		}
		mc.removeMovieClip();

		// HERO
		/*
			hero = cast dm.attach("mcCanon",DP_GROUND);
			hero._y = RGY;
			hero._x = DX;
		 */
		hero = cast gdm.attach("mcCanon", 10);
		hero._y = GH - RGH;
		hero._x = DX;

		// EXPLODE
		mcExplode = dm.empty(DP_ONDE);
		edm = new mt.DepthManager(mcExplode);
		mcExplode._alpha = 25;

		// TARGET
	}

	/*
		function initTarget(){
			mcTarget = dm.attach("mcTarget",DP_PLASMA);
			mcTarget._x = root._xmouse;
			mcTarget._y = root._ymouse;
			mcTarget.stop();
		}
	 */
	// UPDATE
	public function update(delta:Float) {
		mt.Timer.tmod /= 2; // GAME WAS BUILT WITH 2 CALLS TO mt.Timer.update

		// for( i in 0...100000 ){var a = 5/8;}

		switch (step) {
			case Play:
				updatePlay();
			case GameOver:
				updateGameOver();
			case _:
		}

		plasma.drawMc(mcExplode);
		fade += mt.Timer.tmod;
		if (fade > 1) {
			var n = Math.floor(fade);
			var plasmaCt = new ColorMatrixFilter();
			plasmaCt.matrix = [
				1, 0, 0, 0,           0,
				0, 1, 0, 0,           0,
				0, 0, 1, 0,           0,
				0, 0, 0, 1, -n * 2 / 255,
			];
			plasma.ct = plasmaCt;
			fade -= n;
		}

		plasma.update();

		Sprite.updateAll();

		if (cmun != munitions.length)
			KKApi.flagCheater();
	}

	// PLAY
	function initPlay() {
		step = Play;
	}

	function updatePlay() {
		moveHero();

		dif += 0.005 * mt.Timer.tmod;

		replenish += mt.Timer.tmod;
		if (replenish > Cs.REPLENISH_CYCLE) {
			replenish -= Cs.REPLENISH_CYCLE;
			incMunition(1);
		}

		//
		if (!flGameOver && totalSpeed < dif * 1.5 + Missile.BOOST * 8) {
			new Missile();
		}

		// GAMEOVER
		if (flGameOver) {
			var p = new Fly(dm.attach("mcFly", DP_GROUND));
			p.x = holes[Seed.random(holes.length)] + (Seed.randVfx() * 2 - 1) * 2;
			p.y = Cs.mch + 5;
		}
	}

	function moveHero() {
		var dx = root._xmouse - DX;
		var dy = root._ymouse - RGY;
		angle = Num.mm(-1.57, Math.atan2(dy, dx), -0.05);
		hero.gun._rotation = angle / 0.0174;
	}

	// GAMEOVER
	function initGameOver() {
		if (flGameOver)
			return;

		holes = [];
		while (patriots.length > 0)
			patriots[0].kill();
		flGameOver = true;
		KadoKadeoManager.kkm.gameOver({});
	}

	function updateGameOver() {}

	//
	function launchMissile() {
		if (flGameOver)
			return;
		if (muniCount == 0) {
			return;
		}

		incMunition(-1);
		var p = new Patriot();

		/*
			if(mcTarget!=null){
				p.mcTarget = mcTarget;
				mcTarget._alpha = 50;
				mcTarget.play();
				mcTarget = null;
			}
		 */

		// if( expl++ < 3 )initTarget();
	}

	// PLASMA
	function initPlasma() {
		plasma = new Plasma(dm.empty(DP_PLASMA), Cs.mcw, Cs.mch, 0.5);
		// var fl = new flash.filters.BlurFilter();
		// fl.blurX = 2;
		// fl.blurY = 2;
		// plasma.filters.push(fl);
		var plasmaCt = new ColorMatrixFilter();
		plasmaCt.matrix = [
			1, 0, 0, 0,       0,
			0, 1, 0, 0,       0,
			0, 0, 1, 0,       0,
			0, 0, 0, 1, -2 / 255,
		];
		plasma.ct = plasmaCt;
		plasma.root.blendMode = BlendModes.ADD;
		fade = 0;
		plasma.root.blendMode = BlendModes.NORMAL;
	}

	// TOOLS
	public function addScore(x, y, sc, cid) {
		KadoKadeoManager.kkm.addScore(sc);

		var score = KKApi.val(sc);

		var p = new Phys(dm.attach("mcScore", DP_SCORE));
		p.x = x;
		p.y = y;
		// p.vy = (score/100)*0.5;
		// p.weight = -0.15;
		// p.timer = 20+(score/100)*2;
		// p.root._alpha = p.alpha = 50;
		p.timer = 12;
		p.fadeLimit = 5;

		p.fadeType = 4;

		var mc:McField = cast p.root;
		mc.field.text = Std.string(score);
		if (cid != null) {
			var co = Col.colToObj(Missile.COLOR[cid]);
			var inc = -100;
			co.r = Std.int(Math.max(0, co.r + inc));
			co.g = Std.int(Math.max(0, co.g + inc));
			co.b = Std.int(Math.max(0, co.b + inc));

			mc.field.style.fill = Col.objToCol(co);
		}
	}

	public function incMunition(inc) {
		cmun = Std.int(Num.mm(0, cmun + inc, Cs.MISSILE_MAX));
		var goal = Num.mm(0, munitions.length + inc, Cs.MISSILE_MAX);
		muniCount = goal;
		while (goal < munitions.length)
			munitions.pop().removeMovieClip();
		while (goal > munitions.length) {
			var mc = Game.me.dm.attach("mcMunition", DP_INTER);
			mc._x = 4;
			mc._y = 283 - munitions.length * 5;
			munitions.push(mc);
		}
	}

	public function makeHole(x:Float, y:Float, sc:Float) {
		var mc = dm.attach("mcOnde", 0);
		var m = new Matrix();
		m.scale(sc, sc);
		m.translate(Std.int(x), Std.int(y - GY));
		mc.blendMode = untyped BlendModes.ERASE;
		PixelHelper.draw(bmpGround, mc, m);
		mc.blendMode = BlendModes.NORMAL;
		mc.removeMovieClip();
		if (y + sc * 50 > Cs.mch + 1) {
			initGameOver();
			holes.push(x);
		}
	}

	public function getGroundHeight(x) {
		var pixels = PixelHelper.extract(bmpGround);
		for (y in 0...GH) {
			if (pixels.getPixelAlpha(x, y) != 0)
				return GY + y;
		}
		return Cs.mch;
	}

	public function destroy():Void {}
}
