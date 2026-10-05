package tiananman;

import pixi.filters.colormatrix.ColorMatrixFilter;
import pixi.filters.extras.GlowFilter;
import haxe.io.UInt16Array;
import pixi.core.Pixi.BlendModes;
import pixi.core.math.Point as PixiPoint;
import common_haxe_avm1.KKApi;
import common_haxe_avm1.MouseManager;
import common_haxe_avm1.display.BBox;
import kado.KadoKadeoManager;
import mt.bumdum.Sprite;
import mt.bumdum.Phys;
import mt.bumdum.Plasma;
import mt.bumdum.Lib;

enum Step {
	Wait;
	Play;
	GameOver;
}

class McGroupSprite extends ASprite {
	public var groupPolygon:Array<PixiPoint>;
}

class BloodSprite extends Phys {
	public var _bBox:BBox;
}

@:expose('GameTiananMan')
class Game implements kado.GameInterface {
	static public var BloodList:Array<BloodSprite> = new Array();
	static public var ExplosionList:Array<ASprite> = new Array();

	public static var DP_BG = 0;
	public static var DP_GROUND = 1;
	public static var DP_BLOOD = 2;
	public static var DP_TRACES = 3;

	public static var DP_FOLLOW = 5;
	public static var DP_PLAYER = 6;

	public static var DP_WARNING = 7;

	public static var DP_ARMY = 8;
	public static var DP_FEVER = 9;
	public static var DP_TARGET = 10;
	public static var DP_POINTS = 11;
	public static var DP_BOMB = 12;
	public static var DP_PARTS = 13;

	public static var DP_INTERF = 14;
	public static var DP_OVER = 15;
	public static var DP_START = 16;

	public var flGameOver:Bool;
	public var mdm:mt.DepthManager;
	public var root:ASprite;
	public var bg:ASprite;
	public var idm:mt.DepthManager;
	public var step:Step;

	static public var me:Game;

	var timer:Float;
	var frame:Int;

	public var difficulty:Float;
	public var isPaused:Bool;

	public var lifeLeader:Int;
	public var lifeFollowers:Int;
	public var fMult:Int;

	var mcLifeLeader:ASprite;
	var mcLifeFollowers:Array<ASprite>;

	public var mcGroup:McGroupSprite;
	public var gdm:mt.DepthManager;
	public var faceDown:Bool;

	public var mcArmy:ASprite;
	public var adm:mt.DepthManager;

	public var leader:Follower;
	public var followRepopTimer:Float;
	public var toGrab:Array<Follower>;
	public var followers:Array<Array<Follower>>;

	var armyRepopTimer:Float;

	public var army:Array<Army>;

	var mcStart:ClickMe;
	var mcOver:ASprite;

	public var bTimer:BulletTimer;

	public var plasma:Plasma;
	public var waitPlasmaUpdate:Float;

	public var fever:Bool;
	public var feverTimer:Float;
	public var feverStock:Int;
	public var stats:{
		fc:Array<Array<Int>>, // followers collected : [[pts, fMult, fever], ...]
		vd:Array<Int>, // vehicles destroyed [v type]
		f:Array<Int>, // fever count [frame]
		fl:Array<Int>, // followers lost [frame]
		lfsc:Int, // last follower score
	};

	var feverFlash:Int;
	var feverLastCol:Int;
	var feverGlow:Float;
	var mcFever:ASprite;

	static public var debugPause:Bool; // debug only

	public function new(root:ASprite, ?isReplay:Bool = false) {
		var replayMouseButtons = new UInt16Array(1);
		replayMouseButtons[0] = MouseManager.BUTTON_LEFT;
		KadoKadeoManager.kkm.replay.init({
			recordedKeys: new UInt16Array(0),
			recordInputs: false,
			recordEvents: true,
			recordMousePosition: true,
			recordedMouseButtons: replayMouseButtons,
		});

		debugPause = false;

		Cs.bloodCt.matrix = [
			0, 0, 0, 0, 0xBA / 255, // R
			0, 0, 0, 0, 0x02 / 255, // G
			0, 0, 0, 0, 0x02 / 255, // B
			0, 0, 0, 1,              0,
		];

		this.root = root;
		root.interactive = true;
		me = this;
		mdm = new mt.DepthManager(root);

		flGameOver = false;

		stats = {
			fc: [],
			vd: [0, 0, 0, 0, 0],
			f: [],
			fl: [],
			lfsc: 0,
		}

		initBg();
		initGame();
		initInterface();

		// debug only
		// initKeyListener() ;
	}

	function initBg() {
		var bg = mdm.attach("mcBg", DP_BG);
		bg._x = 0;
		bg._y = 0;
	}

	function initInterface() {
		var mcInt = mdm.empty(DP_INTERF);
		idm = new mt.DepthManager(mcInt);
		var bgInter = idm.attach("bgInterface", 0);

		var lifeY = Cs.s(16);

		mcLifeLeader = idm.attach("intLeader", 1);
		mcLifeLeader._x = Cs.s(5);
		mcLifeLeader._y = lifeY;
		mcLifeFollowers = new Array();
		for (i in 0...lifeFollowers) {
			var m = idm.attach("intFollow", 1);
			m.onFrame.set(147, () -> m.gotoAndPlay(1));
			m.gotoAndPlay(2 * i + 1);
			m._x = Cs.s(28 + i * 15);
			m._y = lifeY;
			mcLifeFollowers.push(m);
		}

		mcFever = idm.attach("fever", 2);
		mcFever._x = Cs.s(256);
		mcFever._y = Cs.s(4.5);
		mcFever.gotoAndStop(fever ? 100 : 1);
	}

	function initGame() {
		lifeLeader = Cs.LEADER_LIFE;
		lifeFollowers = Cs.FOLLOWERS_LIFE;
		difficulty = -1.0;
		fMult = 0;

		armyRepopTimer = Cs.repopArmyDelay;
		army = new Array();

		followRepopTimer = 0.0;

		toGrab = new Array();

		var p = mdm.empty(DP_TRACES);
		p._x = 0;
		p._y = 0;

		plasma = new Plasma(p, Std.int(Cs.s(300)), Std.int(Cs.s(300)));
		var bf = 1.03125;
		Filt.blur(plasma.root, bf, bf);
		plasma.root.blendMode = BlendModes.OVERLAY;
		var plasmaCt = new ColorMatrixFilter();
		plasmaCt.matrix = [
			1, 0, 0, 0,       0,
			0, 1, 0, 0,       0,
			0, 0, 1, 0,       0,
			0, 0, 0, 1, -1 / 255,
		];
		plasma.ct = plasmaCt;
		plasma.filters = [cast plasmaCt];

		waitPlasmaUpdate = 100;

		var startX = (Cs.mcw[1] - Cs.mcw[0]) / 2;
		var startY = (Cs.mch[1] - Cs.mch[0]) / 2 + Cs.mch[0];

		mcGroup = cast mdm.empty(DP_PLAYER);
		gdm = new mt.DepthManager(mcGroup);
		faceDown = true;

		mcArmy = mdm.empty(DP_ARMY);
		adm = new mt.DepthManager(mcArmy);
		makeShadows();

		fever = false;
		feverStock = 0;

		leader = new Follower(startX, startY);
		// KKApi.registerButton(leader.mc._clickMe._bBox) ;
		// leader.mc._clickMe._visible = false;

		mcStart = new ClickMe(mdm.attach("mcStart", DP_FOLLOW));
		mcStart.root.blendMode = BlendModes.ADD;
		mcStart.root._x = startX;
		mcStart.root._y = startY;
		// KKApi.registerButton(mcStart) ;

		mcOver = mdm.empty(DP_OVER);
		mcOver.getGraphics()
			.beginFill(0xFFFFFF, 0)
			.moveTo(Cs.mcw[0], Cs.mch[0])
			.lineTo(Cs.mcw[1], Cs.mch[0])
			.lineTo(Cs.mcw[1], Cs.mch[1])
			.lineTo(Cs.mcw[0], Cs.mch[1])
			.lineTo(Cs.mcw[0], Cs.mch[0])
			.endFill();

		// followers = [[null, null, null], [null, leader, null], [null, null, null]] ;
		var ef = new Array<Follower>();
		for (i in 0...3)
			ef.push(null);
		followers = new Array<Array<Follower>>();
		followers.push(ef);
		var lf = new Array<Follower>();
		lf.push(null);
		lf.push(leader);
		lf.push(null);
		followers.push(lf);
		ef = new Array<Follower>();
		for (i in 0...3)
			ef.push(null);
		followers.push(ef);

		updateMcGroupPolygon();

		isPaused = true;

		step = Wait;
		frame = 0;
	}

	public function setPause() {
		untyped root.cursor = "default";
		if (!flGameOver) {
			mdm.swap(mcStart.root, DP_START);
			mcStart.root._x = mcGroup._x;
			mcStart.root._y = mcGroup._y;
			step = Wait;
			isPaused = true;
		}
	}

	public function start() {
		untyped root.cursor = "none";

		leader.setEffect(0, 2.3);

		if (bTimer != null) {
			bTimer.delta = {x: Num.q(leader.x - root._xmouse), y: Num.q(leader.y - root._ymouse)};
			bTimer.update();
		}
		step = Play;

		if (difficulty < 0)
			difficulty = 0.0;
	}

	function applyReplayEvents() {}

	public function update(delta:Float) {
		applyReplayEvents();
		frame++;

		if (isPaused && mcStart.isClicked()) {
			start();
			mcStart.root._x = Cs.s(-1000);
			mcStart.root._y = Cs.s(-1000);
			// mcOver.onRollOut = setPause;
		}

		/*if (Key.isDown(Key.CONTROL)) //DEBUG
			trace(BloodList.length + "    #     " + mt.Timer.fps() + " # " + mt.Timer.tmod) ; */

		if (bTimer == null)
			bTimer = new BulletTimer();

		var haveFeverOver = false;
		for (tf in followers) {
			for (f in tf) {
				if (f == null)
					continue;

				if (f.feverOver != null)
					haveFeverOver = true;
				f.update();
			}
		}

		updateFever();

		for (f in toGrab)
			f.update();

		if (difficulty >= 0)
			difficulty = difficulty + 1.4 * mt.Timer.tmod;

		switch (step) {
			case Wait:
				if (flGameOver) {
					KadoKadeoManager.kkm.gameOver(stats);
					step = GameOver;
					return;
				}

			case Play:
				Sprite.updateAll();

				bTimer.update();
				if (step != Play || bTimer.outOfGround())
					return;

				// #################### DEBUG
				/*if(Key.isDown(Key.SHIFT))
						debugPause = !debugPause ;
					if (debugPause)
						return ; */
				// ####################

				if (flGameOver) {
					KadoKadeoManager.kkm.gameOver(stats);
					step = GameOver;
					return;
				}

				if (!bTimer.isMoving())
					return;

				updateMoves();
				updateArmyRepop();
				updateFollowRepop();

			case GameOver:
				updateArmyMove(mt.Timer.tmod);

				checkDeath();
				updateArmyRepop();
		}
	}

	public function growGroup() {
		for (f in followers) {
			f.unshift(null);
			f.push(null);
		}

		var a = new Array<Follower>();
		var b = new Array<Follower>();
		for (i in 0...followers[0].length) {
			a.push(null);
			b.push(null);
		}
		followers.unshift(a);
		followers.push(b);
	}

	public function updateMcGroupPolygon():Void {
		var points:Array<PixiPoint> = [];

		for (tf in followers) {
			for (f in tf) {
				if (f == null || f.mc == null || f.mc._bBox == null)
					continue;

				var bbox = f.mc._bBox;
				var left = bbox.bboxX;
				var top = bbox.bboxY;
				var right = bbox.bboxX + bbox.bboxWidth;
				var bottom = bbox.bboxY + bbox.bboxHeight;

				addGroupPolygonPoint(points, f, left, top);
				addGroupPolygonPoint(points, f, right, top);
				addGroupPolygonPoint(points, f, right, bottom);
				addGroupPolygonPoint(points, f, left, bottom);
			}
		}

		mcGroup.groupPolygon = convexHull(points);
	}

	function addGroupPolygonPoint(points:Array<PixiPoint>, f:Follower, x:Float, y:Float):Void {
		var bbox = f.mc._bBox;
		points.push(new PixiPoint(f.mc._x + bbox._x + x, f.mc._y + bbox._y + y));
	}

	function getGroupGlobalPolygon():Array<PixiPoint> {
		if (mcGroup.groupPolygon == null)
			updateMcGroupPolygon();

		var points:Array<PixiPoint> = [];
		for (p in mcGroup.groupPolygon) {
			points.push(mcGroup.toGlobal(p));
		}
		return points;
	}

	function convexHull(points:Array<PixiPoint>):Array<PixiPoint> {
		var unique:Array<PixiPoint> = [];
		for (p in points) {
			var exists = false;
			for (u in unique) {
				if (u.x == p.x && u.y == p.y) {
					exists = true;
					break;
				}
			}
			if (!exists)
				unique.push(new PixiPoint(p.x, p.y));
		}

		if (unique.length <= 2)
			return unique;

		unique.sort(function(a, b) {
			if (a.x < b.x)
				return -1;
			if (a.x > b.x)
				return 1;
			if (a.y < b.y)
				return -1;
			if (a.y > b.y)
				return 1;
			return 0;
		});

		var lower:Array<PixiPoint> = [];
		for (p in unique) {
			while (lower.length >= 2 && cross(lower[lower.length - 2], lower[lower.length - 1], p) <= 0) {
				lower.pop();
			}
			lower.push(p);
		}

		var upper:Array<PixiPoint> = [];
		var i = unique.length - 1;
		while (i >= 0) {
			var p = unique[i];
			while (upper.length >= 2 && cross(upper[upper.length - 2], upper[upper.length - 1], p) <= 0) {
				upper.pop();
			}
			upper.push(p);
			i--;
		}

		lower.pop();
		upper.pop();
		return lower.concat(upper);
	}

	inline function cross(o:PixiPoint, a:PixiPoint, b:PixiPoint):Float {
		return (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x);
	}

	function updateLeader(p:Int, nb:Int) {
		if (p == 0 && bTimer.isRotating() || (fever && p == nb - 1)) {
			var r = Cs.rotateMc(leader.mc, bTimer.x, bTimer.y, bTimer.lastX, bTimer.lastY);
			var doUnder = false;
			if (r > 0) {
				if (faceDown) {
					doUnder = true;
					faceDown = false;
				}
			} else {
				if (!faceDown) {
					gdm.ysort(0);
					faceDown = true;
				}
			}

			for (tf in followers) {
				for (f in tf) {
					if (f == null)
						continue;
					f.mc._rotation = r;

					if (doUnder)
						gdm.under(f.mc);

					// if (fever)
					f.checkFever();
				}
			}
		}

		leader.moveTo(bTimer.lastX + (bTimer.x - bTimer.lastX) / nb * (p + 1), bTimer.lastY + (bTimer.y - bTimer.lastY) / nb * (p + 1));
	}

	function checkDeath(?last = false) {
		var groupPolygon = getGroupGlobalPolygon();
		for (a in army) {
			if (a == null || a.mc == null) {
				continue;
			}
			var tankPolygon = a.mc._bBox.getGlobalCorners();

			// drawDebugBbox(tankPolygon, 0xFF0000);
			// drawDebugBbox(groupPolygon, 0x00FFFF);
			if (!BBox.polygonsIntersect(tankPolygon, groupPolygon))
				continue;
			for (tf in followers) {
				for (i in 0...tf.length) {
					var f = tf[i];
					if (f == null || f.shield != null || a == null || a.mc == null)
						continue;
					if (fever) {
						if (a.mc._bBox.hitTestBbox(f.mc._bBox)) {
							a.explose();
							stats.vd[a.level]++;
							break;
						}
					} else { // kill
						if (a != f.feverOver && a.mc._bBox.hitTestBbox(f.mc._bBox)) {
							a.setProutch();
							killFollower(f, a);
							if (f != leader) {
								tf[i] = null;
								updateMcGroupPolygon();
							}
						}
					}
				}
			}
		}
		return lifeLeader <= 0 || lifeFollowers <= 0;
	}

	public function killFollower(f:Follower, ?a:Army) {
		stats.fl.push(frame);
		var frameNb = Seed.randomVfx(4) + 1;
		var scroutch = mdm.attach("bloodPart" + frameNb, DP_BLOOD);
		scroutch.play();

		scroutch._xscale = 150;
		scroutch._yscale = 150;
		var side = Seed.randomVfx(2) * 2 - 1;
		if (a != null) {
			switch (a.typeDir) {
				case 0:
					scroutch._rotation = -90 + side * Seed.randomVfx(10);
				case 1:
					scroutch._rotation = -10 + side * Seed.randomVfx(10);
				case 2:
					scroutch._rotation = 90 + side * Seed.randomVfx(10);
				case 3:
					scroutch._rotation = 180 + side * Seed.randomVfx(10);
			}
		} else
			scroutch._rotation = 180 + side * Seed.randomVfx(10);
		var pos = f.getRootPos();
		scroutch._x = pos.x;
		scroutch._y = pos.y;
		var p:BloodSprite = cast new Phys(scroutch);
		p.fadeType = 6;
		p.fadeLimit = Cs.TRACE_FADE;
		p.timer = Cs.TRACE_TIMER * 2;
		p._bBox = scroutch.attachBBox(new BBox(Cs.s(-10), Cs.s(-10), Cs.s(20), Cs.s(20)));

		Game.BloodList.push(p);

		downFever(Cs.FEVER_LOSE_PER_KILL - Seed.random(2));

		if (f == leader) {
			leader.kill();
			setGameOver();
			lifeLeader = 0;
			mcLifeLeader._alpha = 25;
		} else {
			lifeFollowers--;
			fMult--;

			if (lifeFollowers <= 0)
				setGameOver();

			f.kill();
			if (mcLifeFollowers.length > 0) {
				mcLifeFollowers[mcLifeFollowers.length - 1].gotoAndStop(148);
				mcLifeFollowers.pop();
			}
		}
	}

	function checkGrabs() {
		for (g in toGrab) {
			var found = false;
			for (tf in followers) {
				for (f in tf) {
					if (f == null)
						continue;

					var c = if (fMult < 5) f.mc._clickMe._bBox; else f.mc._bBox;

					if (g.mc._bBox.hitTestBbox(c)) {
						g.grabbed();
						found = true;
						break;
					}
				}

				if (found)
					break;
			}
		}
	}

	public function drawDebugBbox(points:Array<PixiPoint>, color:Int) {
		if (points == null || points.length < 3)
			return;

		var dbg = root.createEmptyMovieClip();
		var graphics = dbg.getGraphics().beginFill(color, 0.8);
		var p = dbg.toLocal(points[0]);
		graphics.moveTo(p.x, p.y);
		for (i in 1...points.length) {
			p = dbg.toLocal(points[i]);
			graphics.lineTo(p.x, p.y);
		}
		p = dbg.toLocal(points[0]);
		graphics.lineTo(p.x, p.y).endFill();
		var phys = new Phys(dbg);
		phys.x = 0;
		phys.y = 0;
		phys.timer = 10;
	};

	function updateBloodAnim(mod:Float) {
		var fps = Cs.FPS;
		for (b in BloodList) {
			if (b == null || b.root == null)
				continue;

			var c = b.root._currentframe;
			var tot = b.root._totalframes;

			if (c == null || c >= tot)
				continue;

			var nf = Std.int(fps * mod);

			if (b.root.transform != null) {
				if (nf + c < tot)
					b.root.gotoAndStop(nf + c);
				else {
					b.root.gotoAndStop(tot);
				}
			}
		}
	}

	function updateExplosionAnim(mod:Float) {
		var fps = Cs.FPS / 30;
		var list = Game.ExplosionList.copy();
		for (e in list) {
			var c = e._currentframe;
			var nf = Std.int(fps * mod);

			var tot = e._totalframes;

			if (nf + c < tot)
				e.gotoAndStop(nf + c);
			else {
				Game.ExplosionList.remove(e);
				e.removeMovieClip();
			}
		}
	}

	function updateArmyRepop() {
		if (army.length > Cs.ARMY_MAX) {
			return;
		}

		var armyMax = difficulty * 0.0032 - 0.15;

		armyRepopTimer = Math.max(0.0, armyRepopTimer - 1.0 * mt.Timer.tmod);
		if (armyRepopTimer > 0.0)
			return;

		var rand = if (armyMax > 0.3 && Seed.random(25) == 0) 1 else 0;

		var l = army.length;
		for (a in army) {
			if (a.mc.travelDone(140))
				l -= if (Seed.random(3) > 0) 1 else 0;
		}

		if (l < armyMax + rand) {
			new Army(Std.int(armyMax - 1));
			armyRepopTimer = Cs.repopArmyDelay + (Seed.random(2) * 2 - 1) * Cs.repopArmyDelay / (Seed.random(2) + 1); // [0, Cs.repopDelay * 2]
		}
	}

	public function updateFollowRepop(?force = false) {
		if (toGrab.length > Cs.GRAB_MAX)
			return;

		if (toGrab.length > 0 && Seed.random(Std.int(Math.max(200, 5000 - difficulty))) > 0)
			return;

		if (!force) {
			followRepopTimer = Math.max(0.0, followRepopTimer - 1.0 * mt.Timer.tmod);
			if (followRepopTimer > 0.0)
				return;
		}

		var f = new Follower();
		followRepopTimer = Cs.repopFollowDelay;
	}

	function updateArmyMove(mod:Float) {
		for (a in army)
			a.resetMoveFlag();

		for (a in army.copy())
			a.update(mod);

		updateBloodAnim(mod);
		updateExplosionAnim(mod);
		updatePlasma(mod);
	}

	function updateMoves() {
		var d = bTimer.getDist();
		var nb = Std.int(Math.max(1, d / Cs.s(14)));
		var mod = mt.Timer.tmod + (d / KadoKadeoManager.I(1)) * 0.035;

		var dead = false;
		for (i in 0...nb) {
			if (lifeLeader > 0)
				updateLeader(i, nb);

			for (a in army)
				a.resetMoveFlag();

			for (a in army.copy())
				a.update(mod / nb * (i + 1));

			dead = dead || checkDeath(i == nb - 1);

			if (!dead)
				checkGrabs();
		}

		updateBloodAnim(mod);
		updateExplosionAnim(mod);
		updatePlasma(mod);
	}

	function updatePlasma(mod:Float) {
		if (plasma == null)
			return;

		waitPlasmaUpdate = Math.max(0, waitPlasmaUpdate - 30.0 * mt.Timer.tmod);

		if (waitPlasmaUpdate == 0) {
			plasma.update();
			waitPlasmaUpdate = 100.0;
		}
	}

	public function setGameOver() {
		flGameOver = true;
	}

	public function addScore(sc:Int) {
		KadoKadeoManager.kkm.addScore(sc);
	}

	public function resetFever() {
		if (!fever)
			return;
		fever = false;
		mcGroup.filters = [];
		mcFever.filters = [];
		Col.setPercentColor(mcGroup, 0, 0xFFFFFF);

		feverStock = 0;
		mcFever.gotoAndStop(1);

		for (tf in followers) {
			for (f in tf) {
				if (f == null)
					continue;
				f.shield = Cs.GRAB_SHIELD;
			}
		}
	}

	public function downFever(?by:Int = 100) {
		if (fever)
			return;

		feverStock = Std.int(Math.max(0, feverStock - by));
		mcFever.gotoAndStop(feverStock + 1);
	}

	public function addToFever(x:Int) {
		if (fever)
			return;

		var fMax = KKApi.val(Cs.FOLLOW_POINTS);
		var fLimit = Std.int(fMax / 8 * 1);
		if (x <= fLimit)
			return;
		var fp = 0.0;
		fp = if (x > fMax / 16 * 15) // 750
			3.0 else if (x > fMax / 8 * 7) // 700
			2.6 else if (x > fMax / 8 * 6) // 600
			1.75 else if (x > fMax / 8 * 5) // 500
			1.4 else if (x > fMax / 8 * 4) // 400
			1.15 else if (x > fMax / 8 * 3) // 300
			0.8 else if (x > fMax / 8 * 2) // 200
			0.65 else if (x > fMax / 8 * 1) // 100 //only active with enough people
			0.35 else 0.0;

		var old = fp;
		fp = Std.int(fp * (1 + fMult * 0.01715));

		// trace(fp + " # " + x + " # " + fMult) ;

		#if debug
		fp = 10;
		#end

		feverStock = Std.int(Math.min(feverStock + fp, 100));
		// trace("stock " + feverStock) ;
		mcFever.gotoAndStop(feverStock + 1);
		if (feverStock >= 100)
			startFever();
	}

	public function startFever() {
		fever = true;
		mcFever.gotoAndStop(100);
		feverTimer = 100.0;
		feverFlash = 0;
		feverGlow = 0.0;
		stats.f.push(frame);
	}

	public function updateFever() {
		if (!fever)
			return;
		var flashy = true;
		var warningLimit = 30;

		var col = Col.objToCol(Col.getRainbow(Seed.randVfx()));

		feverTimer = Math.max(0.0, feverTimer - 0.365 * mt.Timer.tmod);
		if (feverTimer < warningLimit) {
			var frame = Std.int(warningLimit / 10 * feverTimer) + 1;
			mcFever.gotoAndStop(frame);
			feverFlash = (feverFlash + 1) % 6;
			flashy = feverFlash > 3;
			col = feverLastCol;
		}

		// mcGroup.filters = [] ;
		feverGlow += 0.13;
		var ga = Math.abs(Math.sin(feverGlow));

		if (untyped mcFever._glowFilter == null) {
			untyped mcFever._glowFilter = Type.createInstance(GlowFilter, [
				{
					distance: Cs.s(10),
					outerStrength: 3 * ga,
					color: 0xFF0000,
					quality: 0.05
				}
			]);
			mcFever.filters = [untyped mcFever._glowFilter];
		}

		untyped mcFever._glowFilter.outerStrength = 3 * ga;

		if (untyped mcGroup._glowFilter == null) {
			untyped mcGroup._glowFilter = Type.createInstance(GlowFilter, [
				{
					distance: Cs.s(10),
					outerStrength: 3 * ga,
					color: col,
					quality: 0.05
				}
			]);
			mcGroup.filters = [untyped mcGroup._glowFilter];
		}
		untyped mcGroup._glowFilter.outerStrength = 3 * ga;
		untyped mcGroup._glowFilter.color = col;
		// Filt.glow(mcGroup, 8, 1, 0xFFFFFF) ;

		if (flashy) {
			Col.setPercentColor(mcGroup, 60, col);
		} else
			Col.setPercentColor(mcGroup, 0, col);
		feverLastCol = col;

		if (feverTimer == 0)
			resetFever();
	}

	// ######## DEBUG ONLY
	// #################

	/*
		function initKeyListener() {
			var kl = {
				onKeyDown:callback(onKeyPress),
				onKeyUp:callback(onKeyRelease)
			}
			flash.Key.addListener(kl) ;
		}

		public function onKeyRelease() {
			var n = flash.Key.getCode() ;
			switch(n) {
				case flash.Key.SPACE :
					feverStock = 100 ;
					mcFever.gotoAndStop(feverStock + 1) ;
					if (feverStock >= 100)
						startFever() ;
				case 97 : //1
					new Army(0, 0) ;

				case 98 : //2
					new Army(0, 1) ;
				case 99  : //3
					new Army(0, 2) ;
				case 100 : //4
					new Army(0, 3) ;
				case 101 : //5
					new Army(0, 4) ;
				setPause() ;
			}
		}


		public function onKeyPress() {
			var n = Key.getCode() ;

			if (Key.isDown(Key.SHIFT)) {
				trace(n) ;
			}
	}*/
	public function makeShadows() {
		// FIXME: filter to be uncommented
		// mcGroup.filters = [
		// 	new flash.filters.GlowFilter(0x000033, 2, 2, 2, 3),
		// 	new flash.filters.DropShadowFilter(5, 75, 0x000033, 5, 5, 5, 0.6)
		// ];
		// mcArmy.filters = [
		// 	new flash.filters.GlowFilter(0x000033, 2, 2, 2, 3),
		// 	new flash.filters.DropShadowFilter(5, 75, 0x000033, 5, 5, 5, 0.6)
		// ];
	}

	public function destroy():Void {
		if (plasma != null) {
			plasma.kill();
			plasma = null;
		}
		if (army != null) {
			for (a in army.copy()) {
				if (a != null)
					a.kill();
			}
			army = [];
		}
		BloodList = [];
		ExplosionList = [];
		Army.PLACES = [[{l: null, t: [Cs.mcw[0], Cs.mcw[1]]}], [{l: null, t: [Cs.mch[0], Cs.mch[1]]}]];
		Army.NEXT_ID = 0;

		if (mcGroup != null) {
			mcGroup.filters = null;
			mcGroup.groupPolygon = null;
			untyped mcGroup._glowFilter = null;
		}
		if (mcFever != null) {
			mcFever.filters = null;
			untyped mcFever._glowFilter = null;
		}

		leader = null;
		followers = null;
		toGrab = null;
		bTimer = null;
		mdm = null;
		idm = null;
		gdm = null;
		adm = null;
		mcGroup = null;
		mcArmy = null;
		mcStart = null;
		mcOver = null;
		mcFever = null;
		mcLifeLeader = null;
		mcLifeFollowers = null;
		if (me == this)
			me = null;
		root = null;
	}
}
