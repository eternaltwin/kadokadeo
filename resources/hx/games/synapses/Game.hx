package synapses;

import mt.bumdum.Phys;
import haxe.io.UInt16Array;
import pixi.core.math.Matrix;
import pixi.core.graphics.Graphics;
import pixi.core.Pixi.BlendModes;
import common_haxe_avm1.KeyboardManager;
import common_haxe_avm1.MouseManager;
import pixi.core.text.Text;
import mt.bumdum.Lib;
import mt.bumdum.Sprite;

class Influx extends ASprite {
	public var el:Element;
	public var sx:Float;
	public var sy:Float;
	public var c:Float;
	public var sc:Float;
}

@:expose('GameSynapses')
class Game implements kado.GameInterface {
	public static var FL_TEST = false;
	public static var FL_TURBO = false;
	public static var FL_INFINITE = false;

	public static var DP_INTER = 6;
	public static var DP_FX = 5;
	public static var DP_HUNTER = 4;
	public static var DP_ELEMENTS = 3;
	public static var DP_UNDER_FX = 2;
	public static var DP_BRANCH = 1;
	public static var DP_BG = 0;

	public static var BG_COLOR = 0x5C0101;

	var isClickRegistered:Bool = false;

	public var lvl:Int;
	public var coef:Float;
	public var frict:Float;

	public var timer:Float;
	public var counter:Int;
	public var influxMax:Int;
	public var influxSpeed:Float;

	public var winner:Hunter;

	public var action:Void->Void;
	public var hunters:Array<Hunter>;
	public var grid:Array<Array<Array<Element>>>;
	public var elements:Array<Element>;
	public var tunnel:Array<Layer>;
	public var flux:Array<Influx>;

	public static var me:Game;

	public var dm:mt.DepthManager;
	public var root:ASprite;
	public var bg:ASprite;

	public var bdx:Float;
	public var bdy:Float;
	public var playerTargetX:Int;
	public var playerTargetY:Int;

	public var sx:Float;
	public var sy:Float;

	public var ex:Float;
	public var ey:Float;

	// DEBUG
	public var bmpGrid:RenderTexture;

	public function new(mc:ASprite, ?isReplay:Bool = false) {
		var replayMouseButtons = new UInt16Array(1);
		replayMouseButtons[0] = MouseManager.BUTTON_LEFT;
		KadoKadeoManager.kkm.replay.init({
			recordedKeys: new UInt16Array(0),
			recordInputs: false,
			recordEvents: false,
			recordMousePosition: true,
			recordedMouseButtons: replayMouseButtons,
		});

		// haxe.Log.setColor(0xFFFFFF);
		Cs.init();
		root = mc;
		me = this;
		dm = new mt.DepthManager(root);
		playerTargetX = Std.int(Cs.mcw * 0.5);
		playerTargetY = Std.int(Cs.mch * 0.5);

		hunters = [];
		elements = [];
		tunnel = [];
		flux = [];

		initBg();
		initGrid();

		lvl = 0;
		var h = new Hunter(0);

		initPlay();
	}

	function initBg() {
		bg = dm.attach("mcBg", DP_BG);
		bdx = 0;
		bdy = 0;

		//
		for (i in 0...5) {
			var lay = new Layer();
			lay.initTunnel(0, 0);
		}
		for (i in 0...tunnel.length) {
			tunnel[i].updateTunnel(i + 1);
		}
	}

	function initGrid() {
		grid = [];
		for (x in 0...Cs.XMAX) {
			grid[x] = [];
			for (y in 0...Cs.YMAX) {
				grid[x][y] = [];
			}
		}
	}

	//
	public function update(delta:Float) {
		// haxe.Log.clear();
		// trace("hunters:"+hunters.length);
		// trace("elements:"+elements.length);
		// trace("sp:"+Sprite.spriteList.length);

		frict = Math.pow(0.97, mt.Timer.tmod);
		updateMouseInput();

		// viewGrid(grid);
		Sprite.updateAll();
		if (action != null) {
			action();
		}
	}

	// PLAY
	public function initPlay() {
		if (FL_TURBO)
			lvl = 0;

		influxMax = 0;
		influxSpeed = 1 * Cs.NEW_GEN_SCALE;

		action = updatePlay;

		var h = hunters[0];
		h.initPlay();

		// HUNTERS
		var max = lvl;
		if (max >= 4)
			max = 4;
		for (i in 0...max) {
			var h = new Hunter(i + 1);
			h.speed = Math.min((1 + lvl) * Cs.NEW_GEN_SCALE, 15 * Cs.NEW_GEN_SCALE);
		}

		// ELEMENTS
		var max = Cs.CEL_MAX;
		for (i in 0...max) {
			var el = new Element();
			el.initMove(Seed.rand() * 6.28, 1 * Cs.NEW_GEN_SCALE);
		}

		//
		counter = null;
		timer = 150;
		if (lvl == 0)
			timer = 5000;
		if (lvl == 1)
			timer = 500;
		//
		isClickRegistered = false;
		bg.useHandCursor = true;
	}

	function updateMouseInput():Void {
		if (!bg.useHandCursor) {
			return;
		}

		var target = getMouseTarget();
		setPlayerTarget(target.x, target.y);

		if (MouseManager.isButtonJustReleased(MouseManager.BUTTON_LEFT)) {
			if (isClickRegistered) {
				resolvePress();
			}
			isClickRegistered = false;
		}

		if (MouseManager.isButtonJustPressed(MouseManager.BUTTON_LEFT)) {
			isClickRegistered = true;
		}
	}

	inline function getMouseTarget():{x:Int, y:Int} {
		return getClampedTarget(MouseManager.getX(), MouseManager.getY());
	}

	public inline function getPlayerTarget():{x:Float, y:Float} {
		return {x: playerTargetX, y: playerTargetY};
	}

	function setPlayerTarget(x:Float, y:Float) {
		var target = getClampedTarget(x, y);
		playerTargetX = target.x;
		playerTargetY = target.y;
	}

	inline function getClampedTarget(x:Float, y:Float):{x:Int, y:Int} {
		var ix = Std.int(Math.round(x));
		var iy = Std.int(Math.round(y));
		return {
			x: Std.int(Math.max(0, Math.min(ix, Cs.mcw))),
			y: Std.int(Math.max(0, Math.min(iy, Cs.mch))),
		};
	}

	function resolvePress(?x:Null<Int>, ?y:Null<Int>) {
		if (!bg.useHandCursor) {
			return;
		}

		if (x != null && y != null) {
			setPlayerTarget(x, y);
		}

		initResolve();
	}

	public function updatePlay() {
		timer -= mt.Timer.tmod;

		if (timer < 0) {
			if (counter == null)
				counter = 4;
			counter--;
			timer = 30;
			var mc = new Phys(dm.empty(DP_INTER));
			mc.timer = 30;
			mc.root._x = Cs.mcw / 2;
			mc.root._y = Cs.mch / 2;
			mc.alpha = 50;
			mc.root.blendMode = BlendModes.ADD;
			var txt = mc.root.initTextField("field", {
				color: 0xFFFFFF,
				align: "center",
				font: "Impact",
				size: 172,
			});
			txt.text = Std.string(counter);
			txt.y = -txt.height / 2;

			if (counter == 0)
				initResolve();
		}

		// if( FL_TEST && flash.Key.isDown(flash.Key.SPACE) )initResolve();
	}

	// LAYER
	public function newLayer() {
		return new Layer();
	}

	// RESOLVE
	public function initResolve() {
		coef = null;
		isClickRegistered = false;
		bg.useHandCursor = false;
		action = updateResolve;
		for (h in hunters)
			h.initResolve();
	}

	public function updateResolve() {
		updateFlux();

		if (coef == null) {
			if (checkEnd())
				coef = 0;
		} else {
			influxSpeed *= 1.02;
			if (flux.length == 0) {
				coef = Math.min(coef + 0.1 * mt.Timer.tmod, 1);
				if (coef == 1)
					initClean();
			}
		}

		// if( checkEnd() )initClean();
	}

	public function checkEnd() {
		for (el in elements)
			if (el.state == Moving)
				return false;
		return true;
	}

	// CLEAN
	public function initClean() {
		coef = 0;
		action = updateClean;

		// WINNER
		winner = null;
		for (h in hunters) {
			if (winner == null || h.first.size > winner.first.size) {
				winner = h;
			}
		}
		for (h in hunters) {
			if (h != winner) {
				h.flExplode = true;
			} else {
				h.cacheShape();
			}
		}
		for (el in elements) {
			if (el.col != winner.col)
				el.vanish();
		}

		// FLUX
		while (flux.length > 0)
			flux.pop().removeMovieClip();
		// ZOOM
		if (winner.col == 0 || FL_INFINITE) {
			winner.layer.initTunnel(-bdx, -bdy);

			var margin = 50 * Cs.NEW_GEN_SCALE;
			sx = bdx;
			sy = bdy;

			ex = (Seed.randVfx() * 2 - 1) * margin;
			ey = (Seed.randVfx() * 2 - 1) * margin;
		}
	}

	public function updateClean() {
		if (hunters.length == 1) {
			if (winner.col == 0 || FL_INFINITE) {
				coef = Math.min(coef + 0.05 * mt.Timer.tmod, 1);
				winner.root._visible = false;
				bdx = ex * coef + sx * (1 - coef);
				bdy = ey * coef + sy * (1 - coef);

				// trace(bdr);

				for (i in 0...tunnel.length) {
					var lay = tunnel[i];
					lay.updateTunnel(i + coef);
				}

				if (coef == 1) {
					lvl++;
					initPlay();
					winner.scoreField.visible = false;
				}
			} else {
				KadoKadeoManager.kkm.gameOver(null);
				action = null;
			}
		}
	}

	// FX
	public function fxScore(x, y, n) {
		var p = new mt.bumdum.Phys(Game.me.dm.empty(DP_FX));
		p.x = x;
		p.y = y;
		var field:Text = p.root.initTextField("field", {
			color: 0xFF0000,
			align: "center",
			font: "Impact",
			size: 36,
			stroke: "#FFFFFF",
			strokeThickness: 5,
		});
		field.text = Std.string(n);
		p.weight = -(0.1 + Seed.randVfx() * 0.1) * Cs.NEW_GEN_SCALE;
		// p.vy = 2;
		p.timer = 20;
		p.fadeLimit = 5;
		p.fadeType = 0;
		p.sleep = Seed.randVfx() * 2;
		p.root.stop();
		p.updatePos();
	}

	public function updateFlux() {
		// if(coef == null && Seed.random(1)==0 && mt.Timer.tmod < 1.5 && flux.length<influxMax )newInflux();

		var index = 0;
		while (index < flux.length) {
			var mc = flux[index];
			mc.c = Math.min(mc.c + mc.sc * influxSpeed * mt.Timer.tmod, 1);

			mc._x = mc.sx * (1 - mc.c) + mc.el.x * mc.c;
			mc._y = mc.sy * (1 - mc.c) + mc.el.y * mc.c;

			if (mc.c == 1) {
				var el = mc.el.parent;
				if (el != null) {
					setInfluxElement(mc, el);
				} else {
					hunters[mc.el.col].incScore(1);
					mc.removeMovieClip();
					var last = flux.length - 1;
					if (index != last)
						flux[index] = flux[last];
					flux.pop();
					continue;
				}
			}
			index++;
		}
	}

	public function newInflux(?el) {
		var mc:Influx = cast dm.attach("mcInflux", Game.DP_ELEMENTS);
		mc.loop = true;
		mc.play();

		if (el == null) {
			var list = [];
			for (e in elements)
				if (e.size == 0 && e.parent != null)
					list.push(e);
			if (list.length == 0)
				return;
			el = list[Seed.random(list.length)];
		}

		mc.el = el;
		setInfluxElement(mc, el.parent);
		flux.push(mc);

		mc.blendMode = pixi.core.Pixi.BlendModes.ADD;

		// Filt.blur(mc, 2 * Cs.NEW_GEN_SCALE, 2 * Cs.NEW_GEN_SCALE);
		// mc._alpha = 25;
	}

	public function setInfluxElement(mc:Influx, el:Element) {
		mc.sx = mc.el.x;
		mc.sy = mc.el.y;
		mc._x = mc.sx;
		mc._y = mc.sy;

		mc.el = el;

		mc.c = 0;
		var dx = mc.el.x - mc.sx;
		var dy = mc.el.y - mc.sy;
		var dist = Math.sqrt(dx * dx + dy * dy);
		mc.sc = 4 / dist;
	}

	// DEBUG
	function viewGrid(grid:Array<Array<Array<Element>>>) {
		if (!KeyboardManager.isDown(KeyboardManager.G) && bmpGrid != null) {
			bmpGrid.destroy();
			bmpGrid = null;
			return;
		}

		if (bmpGrid == null) {
			bmpGrid = RenderTexture.create(Cs.XMAX, Cs.YMAX);
			var mc = dm.empty(DP_BG);
			mc.attachBitmap(bmpGrid, 0);
			mc.blendMode = BlendModes.ADD;

			mc._xscale = (Cs.mcw / Cs.XMAX) * 100;
			mc._yscale = (Cs.mch / Cs.YMAX) * 100;
		}

		for (x in 0...Cs.XMAX) {
			for (y in 0...Cs.YMAX) {
				var n = grid[x][y].length * 20;
				if (n > 255)
					n = 255;
				var g = new Graphics();
				g.beginFill(Col.objToCol({r: n, g: n, b: n})).drawRect(0, 0, 1, 1);
				var m = new Matrix();
				m.translate(x, y);
				bmpGrid.draw(g, m);
			}
		}
	}

	public function destroy():Void {
		//
	}
}
/*
	Après un réveil difficile causé par une soirée trop arrosée, *Rémi le punk* doit tenter de remettre son cerveau en place pour partir au travail.
	Aidez le en reconnectant toutes les *synapses* décollées pendant la nuit.
 */
// FX	FAIRE DU COURANT
// GFX 	GENERATION DECOR
// HISTAMINE
