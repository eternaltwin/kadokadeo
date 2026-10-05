package tiananman;

import common_haxe_avm1.KKApi;
import common_haxe_avm1.display.BBox;
import mt.bumdum.Sprite;
import mt.bumdum.Phys;
import mt.bumdum.Lib;
import pixi.core.text.Text;

class FollowerMcSprite extends ASprite {
	public var _p:ASprite;
	public var _clickMe:ClickMe;
	public var _bBox:BBox;
}

class McPointsSprite extends ASprite {
	public var _field:Text;
}

enum FollowStep {
	Wait;
	Follow;
}

class Follower {
	static var MIN_DELTA_POS = Cs.s(20.0);
	static var FEVER_SCALE = 160;

	public var step:FollowStep;
	public var mc:FollowerMcSprite;
	public var x:Float;
	public var y:Float;

	public var points:Int;
	public var pointFrames:Int;
	public var mcPoints:McPointsSprite;

	public var shield:Float;

	var effectTimer:Float;
	var effect:Int;
	var effectSpeed:Float;

	var waitDownPoints:Bool;

	public var feverOver:Army;

	public var deltaLeader:{x:Float, y:Float};

	public function new(?startX:Float, ?startY:Float, ?noInit = false) {
		if (noInit)
			return;

		if (startX == null) { // follower
			var p = 20;

			while (x == null
				|| Cs.getDist(x, y, Game.me.leader.x, Game.me.leader.y) < Cs.s(20.0) + Std.int(Game.me.followers.length / 2) * Cs.DELTA_FOLLOW) {
				x = (Cs.mcw[1] - Cs.mcw[0] - MIN_DELTA_POS * 2) / p * Seed.random(p) + MIN_DELTA_POS + Cs.mcw[0];
				y = (Cs.mch[1] - Cs.mch[0] - MIN_DELTA_POS * 2) / p * Seed.random(p) + MIN_DELTA_POS + Cs.mch[0];
			}
			step = Wait;

			mc = cast Game.me.mdm.empty(Game.DP_FOLLOW);
			mc._p = mc.attachMovie("follower", "_p", 1);
			mc._p.gotoAndStop(Seed.randomVfx(mc._p._totalframes) + 1);
			mc._bBox = mc.attachBBox(new BBox(Cs.s(-2), Cs.s(-5), Cs.s(10), Cs.s(10)));
			mc._clickMe = new ClickMe(mc.attachMovie("mcStart", "_clickMe", 0));

			mc._rotation = (20 + Seed.random(180 - 40)) * -1;

			mc._p._alpha = 50;
			Game.me.toGrab.push(this);

			points = KKApi.val(Cs.FOLLOW_POINTS);
			pointFrames = 0;
			mcPoints = cast Game.me.mdm.empty(Game.DP_POINTS);
			mcPoints._field = mcPoints.initTextField("_field", {
				font: "Arial",
				size: 22,
				color: 0xFFFF66,
				align: "center",
				strokeThickness: Std.int(Cs.s(2)),
				stroke: "#CF4000",
			});
			mcPoints._field.text = Std.string(points);
			mcPoints._x = x;
			mcPoints._y = y - Cs.s(13);
			waitDownPoints = true;

			mc._x = x;
			mc._y = y;

			effectTimer = 0.0;
			effect = 1;
			effectSpeed = 1.0;
			mc._xscale = 0;
			mc._yscale = mc._xscale;
			mcPoints._xscale = 0;
			mcPoints._yscale = mcPoints._xscale;
		} else { // force leader
			mc = cast Game.me.gdm.empty(0);
			mc._p = mc.attachMovie("leader", "_p", 1);
			mc._bBox = mc.attachBBox(new BBox(Cs.s(-3), Cs.s(-3), Cs.s(3), Cs.s(3)));
			mc._clickMe = new ClickMe(mc.attachMovie("mcStart", "_clickMe", 0));
			mc._clickMe.root._visible = false;
			step = Follow;

			deltaLeader = {x: 0.0, y: 0.0};
			Game.me.mcGroup._x = startX;
			Game.me.mcGroup._y = startY;
			x = startX;
			y = startY;

			mc._rotation = -90;

			mc._x = 0;
			mc._y = 0;
		}
	}

	public function getRootPos():{x:Float, y:Float} {
		return {x: mc._x + Game.me.mcGroup._x, y: mc._y + Game.me.mcGroup._y};
	}

	public function setFever(a:Army) {
		feverOver = a;
		mc._xscale = FEVER_SCALE;
		mc._yscale = FEVER_SCALE;
	}

	public function checkFever() {
		if (feverOver == null)
			return;

		if (feverOver.mc == null || !feverOver.mc._bBox.hitTestBbox(mc._bBox)) {
			feverOver = null;
			mc._xscale = 100;
			mc._yscale = 100;
		} else
			feverOver.block();
	}

	public function update() {
		if (shield != null) {
			shield = Math.max(0.0, shield - 1.0 * mt.Timer.tmod);
			if (shield == 0)
				shield = null;
		}

		if (step == Wait && !waitDownPoints && points > KKApi.val(Cs.MIN_POINTS)) {
			points = Std.int(Math.max(KKApi.val(Cs.MIN_POINTS), Std.int(points - mt.Timer.tmod * 15)));
			mcPoints._field.text = Std.string(points);
			pointFrames += 1;
		}

		if (effect != null) {
			switch (effect) {
				case 0: // cold
					effectTimer = Math.min(effectTimer + 0.03 * effectSpeed * mt.Timer.tmod, 1);
					Col.setPercentColor(mc, 100 - effectTimer * 100, 0xFFFFFF);
					if (effectTimer == 1) {
						effectTimer = null;
						effect = null;
					}
				case 1: // elastic init
					effectTimer = Math.min(effectTimer + 0.015 * effectSpeed * mt.Timer.tmod, 1);
					var delta = 1 - Cs.elastic(1.5, 1 - effectTimer);

					mc._xscale = delta * 100;
					mc._yscale = mc._xscale;
					mcPoints._xscale = mc._xscale;
					mcPoints._yscale = mc._yscale;

					if (waitDownPoints && mc._xscale > 60)
						waitDownPoints = false;

					if (effectTimer == 1) {
						effectTimer = null;
						effect = null;
					}
			}
		}
	}

	public function isFollowing():Bool {
		return step == Follow;
	}

	public function moveTo(tx:Float, ty:Float) {
		x = tx;
		y = ty;

		if (this == Game.me.leader) {
			Game.me.mcGroup._x = x;
			Game.me.mcGroup._y = y;
		} else {
			mc._x = x;
			mc._y = y;
		}
	}

	public function move() {
		x = Game.me.leader.x + deltaLeader.x;
		y = Game.me.leader.y + deltaLeader.y;

		mc._x = x;
		mc._y = y;
	}

	public function grabbed() {
		if (step != Wait)
			return;

		step = Follow;

		Game.me.stats.fc.push([pointFrames, Game.me.fMult, Game.me.fever ? 1 : 0]);
		var k = KKApi.cmult(KKApi.const(points), KKApi.const(Std.int(1 + Game.me.fMult * 0.2)));
		if (Game.me.fever)
			k = KKApi.const(Std.int(KKApi.val(k) * 1.12));
		Game.me.addScore(k);
		if (Game.me.lifeFollowers == 1) {
			Game.me.stats.lfsc += k;
		}

		Game.me.addToFever(points);

		points = null;
		mcPoints.removeMovieClip();

		mc._clickMe.root._visible = false;
		mc._p._alpha = 100;

		var p = Game.me.leader;
		x = p.x;
		y = p.y;
		mc._x = x;
		mc._y = y;

		Game.me.toGrab.remove(this);
		var f = new Follower(null, null, true);
		f.shield = Cs.GRAB_SHIELD;

		f.mc = cast Game.me.gdm.empty(0);
		f.mc._p = f.mc.attachMovie("follower", "_p", 1);
		f.mc._p.gotoAndStop(mc._p._currentframe);
		f.mc._rotation = p.mc._rotation;
		f.step = step;

		f.mc._bBox = f.mc.attachBBox(new BBox(Cs.s(-2), Cs.s(-5), Cs.s(10), Cs.s(10)));
		f.mc._clickMe = new ClickMe(f.mc.attachMovie("mcStart", "_clickMe", 0));
		f.mc._clickMe.root._visible = false;

		f.addToGroup();

		Game.me.followRepopTimer -= Cs.repopFollowDelay * (Seed.rand() / 3 + 0.75);
		kill();
	}

	public function kill() {
		if (mc != null)
			mc.removeMovieClip();
		if (mcPoints != null)
			mcPoints.removeMovieClip();
	}

	function addToGroup() {
		var choices = new Array();
		var place = 0;
		var l = Game.me.followers.length;
		var mid = Std.int((l - 1) / 2);

		var test = function(i, j, m, forceCh) {
			var ch = null;
			place++;
			ch = Std.int(Math.abs(mid - m)) + 1;

			if (forceCh != null)
				ch = forceCh;

			if (choices[ch] == null)
				choices[ch] = new Array();

			choices[ch].push({i: i, j: j});
		}

		for (i in 1...l - 1) {
			for (j in 1...l - 1) {
				if (Game.me.followers[i][j] != null)
					continue;
				test(i, j, j, 0);
			}
		}

		for (t in [0, l - 1]) {
			for (i in 0...l) {
				if (Game.me.followers[t][i] != null)
					continue;
				test(t, i, i, null);
			}
		}
		for (t in 1...l - 1) {
			for (i in [0, l - 1]) {
				if (Game.me.followers[t][i] != null)
					continue;
				test(t, i, t, null);
			}
		}

		// choose place
		var c = 0;
		while ((choices[c] == null || choices[c].length == 0) && c < choices.length)
			c++;
		var ch = choices[c][Seed.random(choices[c].length)];

		Game.me.fMult++;

		Game.me.followers[ch.i][ch.j] = this;
		deltaLeader = {
			x: (ch.i - mid) * Cs.DELTA_FOLLOW,
			y: (ch.j - mid) * Cs.DELTA_FOLLOW,
		};

		mc._x = deltaLeader.x;
		mc._y = deltaLeader.y;

		setEffect(0);

		if (place <= 1)
			Game.me.growGroup();
		Game.me.updateMcGroupPolygon();
	}

	public function setEffect(e:Int, ?sp = 1.0) {
		if (effect != null)
			return;
		effect = e;
		effectTimer = 0;
		effectSpeed = sp;
	}
}
