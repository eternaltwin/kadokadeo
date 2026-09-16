package alchimie2;

import common_haxe_avm1.KKApi;
import pixi.core.Pixi.BlendModes;
import mt.bumdum.Lib;
import alchimie2.anim.Transition;
import alchimie2.GameData.ArtefactId;
import common_haxe_avm1.pixi.DropShadowFilter;
import pixi.filters.extras.GlowFilter;

class McEffectSprite extends ASprite {
	public var _help:Text;
	public var _nb:Text;
	public var _nbPanel:ASprite;
	public var _wheel_1:ASprite;
	public var _wheel_2:ASprite;
	public var _wheel_3:ASprite;
	public var _wheel_4:ASprite;
}

class Stage {
	static public var MCEFFECT_HIDE_Y = KadoKadeoManager.I(-91);
	static public var WIDTH = 6;
	static public var HEIGHT = 9;
	static public var LIMIT = 6;
	static public var X = KadoKadeoManager.I(10); // old : 4
	static public var Y = KadoKadeoManager.I(22);
	static public var BY = KadoKadeoManager.I(5);
	static public var LIMIT_Y = Cs.HEIGHT - (Stage.BY + (LIMIT) * Cs.ELEMENT_SIZE);

	public var mc:ASprite;
	public var dm:mt.DepthManager;

	public var next:Group;
	public var nexts:List<Group>;

	public var effect:{
		leftPlays:Int,
		duration:Float,
		start:Float
	};

	public var mcEffect:McEffectSprite;
	public var rWheels:Array<{
		wmc:ASprite,
		step:Int,
		values:Array<Float>,
		wait:Float
	}>;
	public var dmEffect:mt.DepthManager;
	public var animMasks:Array<ASprite>;

	var comboCount:Int;

	public var shakeTimer:Float;

	public var grid:Array<Array<StageObject>>;
	public var falls:Array<StageObject>;
	public var groups:Array<Array<StageObject>>;
	public var killParasits:Array<StageObject>;
	public var transforms:Array<Element>;
	public var toDestroy:Array<StageObject>;
	public var reserved:Array<StageObject>;

	public function new() {
		mc = Game.me.mdm.attach("playArea", Cs.DP_STAGE);
		mc.smc = mc.attachMovie("playAreaSmc", "smc");
		mc._x = KadoKadeoManager.I(0);
		mc._y = KadoKadeoManager.I(0);
		dm = new mt.DepthManager(mc.smc);

		initBgImg();

		mcEffect = cast dm.empty(Cs.DP_EFFECT);
		mcEffect._wheel_1 = mcEffect.attachMovie("meka_wheels");
		mcEffect._wheel_1._xscale = 120;
		mcEffect._wheel_1._yscale = 120;
		mcEffect._wheel_1._x = KadoKadeoManager.I(40);
		mcEffect._wheel_1._y = KadoKadeoManager.I(75);
		mcEffect._wheel_1.gotoAndStop(Seed.randomVfx(1) + 1);
		mcEffect._wheel_2 = mcEffect.attachMovie("meka_wheels");
		mcEffect._wheel_2._xscale = 50;
		mcEffect._wheel_2._yscale = 50;
		mcEffect._wheel_2._x = KadoKadeoManager.I(108);
		mcEffect._wheel_2._y = KadoKadeoManager.I(75);
		mcEffect._wheel_2.gotoAndStop(Seed.randomVfx(2) + 1);
		mcEffect._wheel_3 = mcEffect.attachMovie("meka_wheels");
		mcEffect._wheel_3._xscale = 75;
		mcEffect._wheel_3._yscale = 75;
		mcEffect._wheel_3._x = KadoKadeoManager.I(162);
		mcEffect._wheel_3._y = KadoKadeoManager.I(60);
		mcEffect._wheel_3.gotoAndStop(Seed.randomVfx(2) + 1);
		mcEffect._wheel_4 = mcEffect.attachMovie("meka_wheels");
		mcEffect._wheel_4._xscale = 50;
		mcEffect._wheel_4._yscale = 50;
		mcEffect._wheel_4._x = KadoKadeoManager.I(190);
		mcEffect._wheel_4._y = KadoKadeoManager.I(115);
		mcEffect._wheel_4.gotoAndStop(Seed.randomVfx(2) + 1);
		mcEffect._y = MCEFFECT_HIDE_Y;
		mcEffect.attachMovie("help", "help");

		mcEffect._nbPanel = mcEffect.createEmptyMovieClip();
		mcEffect._nbPanel.attachMovie("nbPanel");
		mcEffect._nb = mcEffect._nbPanel.initTextField("field", {
			font: "Arial",
			color: 0x8ca9cc,
			align: "left",
			size: KadoKadeoManager.I(30),
			x: 0,
			y: 0,
		});
		mcEffect._nb.filters = [
			new DropShadowFilter({
				blur: 0,
				rotation: 90,
				distance: KadoKadeoManager.I(3),
				color: 0xA3C3ED
			}),
			new DropShadowFilter({
				blur: 0,
				rotation: 90,
				distance: KadoKadeoManager.I(1),
				color: 0x455565
			}),
			Type.createInstance(GlowFilter, [
				{
					distance: KadoKadeoManager.I(1),
					outerStrength: 3,
					color: 0x8CA9CC,
					quality: 0.25
				}
			])
		];

		mcEffect._help = mcEffect.initTextField("help", {
			font: "LondonTwo",
			color: 0x6f88a2,
			align: "left",
			size: KadoKadeoManager.I(30),
			x: KadoKadeoManager.I(65),
			y: KadoKadeoManager.I(10),
		});
		dmEffect = new mt.DepthManager(mcEffect);

		rWheels = [
			{
				wmc: mcEffect._wheel_1,
				step: 0,
				wait: 10.0,
				values: [16.0, -3.0, 4.0]
			},
			{
				wmc: mcEffect._wheel_2,
				step: 0,
				wait: 10.0,
				values: [7.0, -2.0, 2.0]
			},
			{
				wmc: mcEffect._wheel_3,
				step: 0,
				wait: 10.0,
				values: [8.0, -3, 3.0]
			},
			{
				wmc: mcEffect._wheel_4,
				step: 0,
				wait: 10.0,
				values: [6.0, -2, 2.0]
			}
		];

		shakeTimer = 0.0;

		comboCount = -1;

		grid = [];
		nexts = new List();
		falls = [];
		groups = [];
		toDestroy = [];
		for (i in 0...WIDTH) {
			grid[i] = [];
		}

		animMasks = new Array();
		for (i in 0...2) {
			var animMask = Game.me.mdm.empty(Cs.DP_MASK);
			animMask._x = 0;
			animMask._y = 0;
			var g = animMask.getGraphics();
			g.beginFill(1, 0);
			g.moveTo(X, 0);
			g.lineTo(X + Stage.WIDTH * Cs.ELEMENT_SIZE, 0);
			g.lineTo(X + Stage.WIDTH * Cs.ELEMENT_SIZE, Cs.HEIGHT - BY);
			g.lineTo(X, Cs.HEIGHT - BY);
			g.lineTo(X, 0);
			g.endFill();

			animMasks.push(animMask);
		}

		// forceGrid() ;
		// forceComboGrid([10, 9, 8, 7, 6, 5, 4]);
	}

	function initBgImg() {
		// initBg() ;
		Filt.blur(Game.me.bg, KadoKadeoManager.S(1.3), KadoKadeoManager.S(1.3));

		setFader();
		setLimit();
	}

	function setLimit() {
		var l = dm.attach("limite", Cs.DP_LIMITE);
		l._x = 0;
		l._y = LIMIT_Y;
	}

	function setFader() {
		var f = dm.attach("fader", Cs.DP_FADER);
		f.blendMode = BlendModes.OVERLAY;
	}

	public function init(gridStart) {
		if (gridStart != null)
			initGrid(gridStart);
		else
			Game.me.mode.initStage(this);

		initNext();
	}

	public function initNext() {
		if (nexts.length > 0) {
			for (g in nexts)
				g.kill();
		}

		nexts.push(new Group());
		getNext();
	}

	function initGrid(g:Array<{_id:ArtefactId, _x:Int, _y:Int}>) {
		if (g == null)
			return;

		forceEmpty();

		for (e in g) {
			var chain_Index = Game.me.mode.isInChain(e._id);
			var o = if (chain_Index != null) new Element(chain_Index, dm, Stage.HEIGHT - e._y); else StageObject.get(e._id, dm, Stage.HEIGHT - e._y);

			var cx = next.col + o.x;
			var cy = HEIGHT - (Cs.GROUP_LINE + o.y);
			var yy = Cs.HEIGHT - (Stage.BY + (cy + 1 - (if (next.isVertical()) 0.5 else 0)) * Cs.ELEMENT_SIZE);

			o.place(e._x, e._y, X + e._x * Cs.ELEMENT_SIZE, Cs.HEIGHT - (Stage.BY + (e._y + 1) * Cs.ELEMENT_SIZE));

			add(o);
		}
	}

	public function startFall() {
		var news = new Array();
		if (next != null)
			news = split();

		var cut = false;
		for (o in news) {
			cut = cut || o.onFall();
		}

		if (cut)
			return;

		comboCount++;

		targetFalls();
		Game.me.setStep(Fall);
	}

	function split() {
		var res = new Array();
		var i = 0;
		for (o in next.objects) {
			var no = reserved.shift();
			// var b = o.omc.mc.smc.getBounds(mc);

			var cx = next.col + o.x;
			var cy = HEIGHT - (Cs.GROUP_LINE + o.y);
			var yy = Cs.HEIGHT - (Stage.BY + (cy + 1 - (if (next.isVertical()) 0.5 else 0)) * Cs.ELEMENT_SIZE);

			no.place(cx, cy, X + cx * Cs.ELEMENT_SIZE, yy);

			add(no);
			res.push(no);
			i++;
		}
		next.kill();
		next = null;

		return res;
	}

	public function add(o:StageObject) {
		grid[o.x][o.y] = o;
	}

	public function startPlay() {
		// Game.me.mode.addToScore(Std.int(Math.max((comboCount - 1) * Cs.COMBO_BONUS, 0))) ;
		comboCount = -1;

		if (checkEnd()) {
			Game.me.setGameOver();
			return false;
		}

		// Game.me.setStep(Fall) ;
		getNext();
		return true;
	}

	public function startTransformation() {
		transforms = [];

		for (g in groups) {
			if (!bigEnough(g)) {
				continue;
			}

			var tt = Game.me.mode.transformInfos(cast g);
			for (t in tt) {
				for (o in t.g) {
					var e:Element = cast o;
					e.onTransform();
					e.initTransform(t.t);
					transforms.push(e);
				}
			}
		}

		var t = KadoKadeoManager.kkm.replay.getCurrentFrame();
		for (n in killParasits) {
			if (n.isParasit) {
				n.onTransform();
				(cast n).initKill();
			} else if (n.isPickable) {
				n.onTransform();
				n.initPickUp(t);
			}
		}

		Game.me.setSpiritState(comboCount);

		Game.me.setStep(Transform);
	}

	public function transform() {
		if (transforms.length == 0 && killParasits.length == 0)
			return false;

		for (e in transforms) {
			if (!e.updateTransform())
				transforms.remove(e);
		}

		updatePick();

		return true;
	}

	public function updatePick() {
		for (n in killParasits) {
			if ((n.isParasit && !(cast n).updateKill()) || (n.isPickable && !n.updatePickUp()))
				killParasits.remove(n);
		}
	}

	public function destroy() {
		if (toDestroy.length == 0)
			return false;

		// trace("############") ;

		for (e in toDestroy) {
			//	trace(Std.string(e.getArtId())) ;
			e.updateDestroy();
		}
		return true;
	}

	public function remove(o:StageObject, ?noKill:Bool = false) {
		grid[o.x][o.y] = null;
		falls.remove(o);
		if (noKill || Game.me.hasInUse(o))
			return;
		o.kill();
	}

	public function targetFalls() {
		var done = [];
		for (x in 0...WIDTH)
			done[x] = false;

		for (y in 0...HEIGHT) {
			for (x in 0...WIDTH) {
				if (done[x])
					continue;

				if (grid[x][y] != null)
					continue;

				var s = 1;
				while (y + s < HEIGHT && grid[x][y + s] == null)
					s++;

				if (y + s == HEIGHT) {
					done[x] = true;
					// trace("nothing for " + x + ", " + y) ;
					continue;
				}

				var o = null;
				for (dy in (y + 1)...HEIGHT) {
					if (grid[x][dy] == null)
						continue;
					o = grid[x][dy];
					grid[x][dy] = null;
					grid[x][dy - s] = o;
					if (o != null)
						o.setFall(x, dy - s);
				}

				if (o != null)
					o.prepareBounce(s);
			}
		}

		// force x depth
		forceXDepth();
	}

	public function forceXDepth() {
		for (y in 0...HEIGHT) {
			dm.compact(y);
			var x = WIDTH - 1;
			while (x >= 0) {
				var o = grid[x][y];
				if (o != null)
					dm.over(o.omc.mc);
				x--;
			}
		}
	}

	public function removeFall(o:StageObject) {
		var oldLength = falls.length;
		falls.remove(o);
		if (oldLength > 0 && falls.length == 0)
			Game.me.mode.onGround();
	}

	public function isFalling():Bool {
		return falls.length != 0;
	}

	public function fall() {
		for (o in falls) {
			o.fall();
		}
	}

	// check new transforms
	public function check() {
		resetGroups();
		var done = [];
		for (x in 0...WIDTH)
			done[x] = false;

		var transmut = false;

		for (x in 0...WIDTH) {
			for (y in 0...HEIGHT) {
				if (done[x])
					continue;
				var e = grid[x][y];
				if (e == null) {
					// trace("IS NULL " + x +" " + y) ;
					done[x] = true;
					continue;
				}
				if (!e.isElement() || e.group != null) {
					// trace("group " + x +" " + y + (if (e.group != null) "#"else "") + (if (!e.isElement()) "%"else "")) ;
					continue;
				}

				parseGroup(cast e, getNewGroup());
				// trace(e.x + ", " + e.y +  " ==> " + e.group.length) ;

				if (bigEnough(e.group)) {
					// trace("big : " + e.x + ", " + e.y + "###" + e.group.length) ;
					getCollaterals(e.group);
					transmut = true;
				}
			}
		}

		return transmut;
	}

	function getCollaterals(g:Array<StageObject>) {
		for (o in g) {
			for (d in 0...4) {
				var neighbour = getNeighbour(o, d);

				if (neighbour == null || (!neighbour.isCollateral(o.getArtId())) || (cast neighbour).toKill)
					continue;

				neighbour.toKill = true;
				killParasits.push(neighbour);
			}
		}
	}

	public function getNeighbour(o:StageObject, d:Int) {
		if (o == null)
			return null;
		switch (d) {
			case 0: // left
				return grid[o.x - 1] != null ? grid[o.x - 1][o.y] : null;
			case 1: // down
				return grid[o.x][o.y - 1];
			case 2: // right
				return grid[o.x + 1] != null ? grid[o.x + 1][o.y] : null;
			case 3: // up
				return grid[o.x][o.y + 1];
			case _:
				trace("invalid direction");
				return null;
		}
	}

	function parseGroup(o:Element, g:Array<StageObject>) {
		o.setGroup(g);

		for (d in 0...4) {
			var neighbour = getNeighbour(o, d);

			if (neighbour == null || !neighbour.isElement() || neighbour.group != null || neighbour.id != o.id)
				continue;

			parseGroup(cast neighbour, g);
		}
	}

	public static function bigEnough(g:Array<StageObject>) {
		if (g == null)
			throw "group is null";
		return !Game.me.mode.isEndChain(cast g[0]) && g.length >= Cs.TRANSMUT_LIMIT;
	}

	// get nextGroup to play
	public function getNext() {
		next = nexts.pop();

		effectCheckFall();

		nexts.add(new Group(true));

		var f = function() {
			var o = this.nexts.first();
			o.toNextBox();
			Game.me.setStep(Play);
		};
		Game.me.setStep(Wait);
		reserve(next);

		var ff = function() {
			next.toStage(f);
		};

		next.move(next.mc._x, next.mc._y + KadoKadeoManager.I(100), false, ff, Linear, 0.12);
	}

	// copy elements of group on dm and hide them. ==> preload for fall on stage
	public function reserve(g:Group) {
		if (reserved == null)
			reserved = new Array();

		for (o in g.objects) {
			var no = o.copy(dm, 1);
			no.place(-10, -10, KadoKadeoManager.I(-100), KadoKadeoManager.I(-100));
			reserved.push(cast no);
		}
	}

	public function getAvailableElements():Array<ArtefactId> {
		var done = [];
		for (x in 0...WIDTH)
			done[x] = false;

		var res = new Array();

		for (x in 0...WIDTH) {
			for (y in 0...HEIGHT) {
				if (done[x])
					continue;
				var e = grid[x][y];
				if (e == null) {
					done[x] = true;
					continue;
				}
				if (!e.isElement())
					continue;

				var e:Element = cast e;
				if (Lambda.exists(res, function(x) {
					return x == e.id;
				}))
					continue;

				res.push(e.id);
			}
		}
		return res;
	}

	public function hasArtefact(o:ArtefactId):Bool {
		var done = [];
		for (x in 0...WIDTH)
			done[x] = false;

		for (x in 0...WIDTH) {
			for (y in 0...HEIGHT) {
				if (done[x])
					continue;
				var e = grid[x][y];
				if (e == null) {
					done[x] = true;
					continue;
				}

				if (Type.enumConstructor(e.getArtId()) == Type.enumConstructor(o))
					return true;
			}
		}
		return false;
	}

	public function getAllElements(?eid:Int):Array<Element> {
		var done = [];
		for (x in 0...WIDTH)
			done[x] = false;

		var res = new Array();

		for (x in 0...WIDTH) {
			for (y in 0...HEIGHT) {
				if (done[x])
					continue;
				var e = grid[x][y];
				if (e == null) {
					done[x] = true;
					continue;
				}
				if (!e.isElement())
					continue;

				var e:Element = cast e;
				if (eid == null || e.getId() == eid)
					res.push(e);
			}
		}
		return res;
	}

	public function getAll():Array<StageObject> {
		var done = [];
		for (x in 0...WIDTH)
			done[x] = false;

		var res = new Array();

		for (x in 0...WIDTH) {
			for (y in 0...HEIGHT) {
				if (done[x])
					continue;
				var e = grid[x][y];
				if (e == null) {
					done[x] = true;
					continue;
				}

				res.push(e);
			}
		}
		return res;
	}

	public function getPoints() {
		var done = [];
		for (x in 0...WIDTH)
			done[x] = false;

		var score = KKApi.const(0);

		for (x in 0...WIDTH) {
			for (y in 0...HEIGHT) {
				if (done[x])
					continue;
				var e = grid[x][y];
				if (e == null) {
					done[x] = true;
					continue;
				}
				if (!e.isElement())
					continue;

				score = KKApi.cadd(score, Cs.POINTS[(cast e).index]);
			}
		}
		return score;
	}

	public function rotate() {
		if (next == null)
			return;
		next.startRotate();
	}

	public function release() {
		if (next == null || !Game.me.canPlay() || !next.canFall())
			return;
		Game.me.setStep(Wait);
		startFall();
	}

	function getNewGroup():Array<StageObject> {
		var g = new Array();
		groups.push(g);
		return g;
	}

	public function resetGroups() {
		for (x in 0...WIDTH) {
			for (y in 0...HEIGHT) {
				var o = grid[x][y];
				if (o == null || !o.isElement())
					continue;
				o.ungroup();
			}
		}
		groups = [];
		killParasits = [];
		transforms = [];
	}

	public function checkEnd() {
		for (x in 0...WIDTH) {
			if (grid[x][LIMIT] != null)
				return true;
		}

		if (Game.me.mode.checkEnd())
			return true;

		return false;
	}

	// TempEffects

	public function effectCheckFall() {
		if (effect == null || effect.leftPlays == null)
			return;

		effect.leftPlays--;

		if (effect.leftPlays < 0)
			killEffect();
		else {
			mcEffect._nb.text = Std.string(effect.leftPlays + 1);
			/*if (!mcEffect._visible)
				mcEffect._visible = true ; */
		}
	}

	public function updateEffect() {
		if (shakeTimer > 0)
			shake();

		updateWheels();

		if (effect == null || effect.duration == null)
			return;
		var t = effect.duration - (KadoKadeoManager.kkm.replay.getCurrentFrame() - effect.start) / 1000;

		if (t <= 0) {
			killEffect();
			return;
		}

		var r = Math.floor(t);
		var d = Std.string(t - r);
		d = d.substr(2, 2);
		if (d.length == 1)
			d += "0";

		mcEffect._nb.text = (if (r < 10) "0" else "") + r + ":" + d;
		if (!mcEffect._visible)
			mcEffect._visible = true;
	}

	function updateWheels() {
		for (i in 0...rWheels.length) {
			var w = rWheels[i];
			var v = 1.0 * mt.Timer.tmod;
			switch (w.step) {
				case 0: // rotate
					w.wmc._rotation = (w.wmc._rotation + v) % 360;
					w.wait = Math.max(w.wait - v, 0.0);
					if (w.wait == 0.0) {
						w.step = 1;
						w.wait = Math.abs(w.values[w.step]);
					}
				case 1: // un rotate
					w.wmc._rotation = (w.wmc._rotation - v) % 360;
					w.wait = Math.max(w.wait - v, 0.0);
					if (w.wait == 0.0) {
						w.step = 2;
						w.wait = w.values[w.step];
					}

				case 2:
					w.wait = Math.max(w.wait - 0.1 * mt.Timer.tmod, 0.0);
					if (w.wait == 0.0) {
						w.step = 0;
						w.wait = w.values[w.step];
					}
			}
		}
	}

	public function setShake(s:Float, ?limit:Int = 5) {
		shakeTimer = Math.min(limit, shakeTimer + s);
	}

	function shake() {
		shakeTimer -= 0.3;
		var b = mc;
		var pos = {x: 0, y: 0};
		var v = 5;
		b._x = pos.x + KadoKadeoManager.S(Seed.randomVfx(Math.round(shakeTimer * v)) / v * (Seed.randomVfx(2) * 2 - 1));
		b._y = pos.y + KadoKadeoManager.S(Seed.randomVfx(Math.round(shakeTimer * v)) / v * (Seed.randomVfx(2) * 2 - 1));

		if (Game.me.bg != null) {
			Game.me.bg._x = KadoKadeoManager.S(Seed.randomVfx(Math.round(shakeTimer * v)) / v * (Seed.randomVfx(2) * 2 - 1));
			Game.me.bg._y = KadoKadeoManager.S(Seed.randomVfx(Math.round(shakeTimer * v)) / v * (Seed.randomVfx(2) * 2 - 1));
		}
	}

	public function chooseFreeColumn():Int {
		var cols = getFreeColumns();
		if (cols.length == 0)
			return null;
		return cols[Seed.random(cols.length)];
	}

	public function getFreeColumns():Array<Int> {
		var res = [];
		for (i in 0...WIDTH) {
			if (Game.me.stage.grid[i][Stage.LIMIT - 1] != null)
				continue;
			res.push(i);
		}
		return res;
	}

	public function killEffect(?f:Void->Void, ?fast:Bool = false) {
		effect = null;

		// var animEffect = new anim.Anim(s.mcEffect, Translation, Elastic(-1, 0.27), {x : s.mcEffect._x, y : 0, speed : 0.025}) ;

		var a = new alchimie2.anim.Anim(mcEffect, Translation, Elastic(1, 0.3), {x: mcEffect._x, y: MCEFFECT_HIDE_Y, speed: 0.025 + (if (fast) 0.01 else 0.0)});
		a.onEnd = function() {
			mcEffect.gotoAndStop(1);
			mcEffect._help.text = "";
			mcEffect._nb.text = "";
			if (f != null)
				f();
		};
		a.start();

		/*mcEffect._visible = false ;
			if (mcEffect.smc != null)
				mcEffect.smc.removeMovieClip() ; */
	}

	// ### DEV UTILS

	function forceGrid() {
		for (x in 0...WIDTH) {
			var n = 6;
			switch (x) {
				case 2:
					n = 5;
				case 3:
					n = 0;
			}
			for (y in 0...n) {
				if (grid[x][y] != null)
					continue;

				var o = new Element(Seed.random(10), dm, HEIGHT - y);
				// var o = new artefact.EnforcedBlock(Std.random(4) + 1, true, dm, HEIGHT - y) ;
				o.place(x, y, Stage.X + x * Cs.ELEMENT_SIZE, Cs.HEIGHT - (Stage.BY + (y + 1) * Cs.ELEMENT_SIZE));
				add(o);
			}
		}
	}

	public function forceComboGrid(?eids:Array<Int>) {
		if (eids == null)
			eids = [6, 5, 4, 3, 2, 1, 0];

		for (y in 0...eids.length) {
			var x = 3;
			while (x > 1) {
				if (grid[x][y] == null) {
					var o = new Element(eids[y], dm, HEIGHT - y);
					o.place(x, y, Stage.X + x * Cs.ELEMENT_SIZE, Cs.HEIGHT - (Stage.BY + (y + 1) * Cs.ELEMENT_SIZE));
					add(o);
				}

				x--;
			}
		}

		//	Game.me.forceGroup(Elt(eids[eids.length - 1])) ;
	}

	public function forceEmpty() {
		/*if (Game.me.step != Play)
			return ; */

		for (x in 0...WIDTH) {
			for (y in 0...HEIGHT) {
				var o = grid[x][y];

				if (o == null)
					continue;
				remove(o);
			}
		}
	}
}
