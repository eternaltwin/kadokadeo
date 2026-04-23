package f1champion;

import mt.bumdum.Sprite;
import mt.bumdum.Phys;
import pixi.core.graphics.Graphics;
import pixi.core.text.Text;

class F1Sprite extends ASprite {
	public var dr:ASprite;
	public var dl:ASprite;
	public var ur:ASprite;
	public var ul:ASprite;
}

@:expose('GameF1Champion')
class Game implements kado.GameInterface {
	static var BONUS = KKApi.aconst([200, 500, 1000]);

	public var mc:ASprite;
	public var dmanager:DepthManager;

	var level:Level;
	var f1:F1Sprite;
	var shadow:ASprite;
	var life_container:ASprite;
	var life:ASprite;
	var life_mask:Graphics;
	var speed:Text;
	var trail_mc:ASprite;
	var expl_mc:ASprite;
	var options:Array<{id:Int, mc:ASprite}>;
	var trails:Array<Array<{x:Float, y:Float, c:Int}>>;
	var parts:Array<{
		mc:ASprite,
		sx:Float,
		sy:Float,
		sr:Float,
		ay:Float,
		ss:Float
	}>;

	public var chkdata:{
		n:Int,
		b:Array<Int>
	};

	var pos:Float;
	var delta:Float;
	var lifepts:Float;
	var lock:Bool;
	var score:Float;
	var oil_time:Float;

	public function new(root:ASprite, ?isReplay:Bool = false) {
		this.mc = root;
		dmanager = new DepthManager(root);
		shadow = dmanager.attach("shadow", Cs.PLAN_F1);
		shadow._xscale = Cs.CAR_SCALE;
		shadow._yscale = Cs.CAR_SCALE;
		shadow._alpha = 10;
		f1 = cast dmanager.empty(Cs.PLAN_F1);
		f1.attachMovie("f1", "f1", 1);
		f1._xscale = Cs.CAR_SCALE;
		f1._yscale = Cs.CAR_SCALE;
		f1.dr = cast f1.attachMovie("wheel", 0);
		f1.dr.loop = true;
		f1.dr.play();
		f1.dr._xscale = -100;
		f1.dr._x = 7 * Cs.NEW_GEN_SCALE;
		f1.dr._y = 6 * Cs.NEW_GEN_SCALE;
		f1.dl = cast f1.attachMovie("wheel", 0);
		f1.dl.loop = true;
		f1.dl.play();
		f1.dl._x = -7 * Cs.NEW_GEN_SCALE;
		f1.dl._y = 6 * Cs.NEW_GEN_SCALE;
		f1.ur = cast f1.attachMovie("wheel", 0);
		f1.ur.loop = true;
		f1.ur.play();
		f1.ur._xscale = -100;
		f1.ur._x = 6 * Cs.NEW_GEN_SCALE;
		f1.ur._y = -9 * Cs.NEW_GEN_SCALE;
		f1.ul = cast f1.attachMovie("wheel", 0);
		f1.ul.loop = true;
		f1.ul.play();
		f1.ul._x = -6 * Cs.NEW_GEN_SCALE;
		f1.ul._y = -9 * Cs.NEW_GEN_SCALE;
		trail_mc = dmanager.empty(Cs.PLAN_TRAIL);
		life_container = dmanager.attach("life_empty", Cs.PLAN_INTERFACE);
		life = life_container.attachMovie("life_full", 2);
		var mask = life.createEmptyMovieClip("life_mask", 3);
		life_mask = mask.getGraphics();
		life.mask = life_mask;
		life_container._x = Cs.WIDTH - 128 * Cs.NEW_GEN_SCALE;
		life_container._y = Cs.HEIGHT - 31 * Cs.NEW_GEN_SCALE;
		lifepts = Cs.MAXLIFE;
		oil_time = 0;
		var speedSprite = dmanager.empty(Cs.PLAN_INTERFACE);
		speed = speedSprite.initTextField("field", {
			font: "LCD",
			size: 45,
			color: 0xFFFFFF,
			align: "right",
		});
		speed.x = Cs.WIDTH - 10 * Cs.NEW_GEN_SCALE;
		speed.y = Cs.HEIGHT - 40 * Cs.NEW_GEN_SCALE;
		pos = 150 * Cs.NEW_GEN_SCALE;
		delta = 0;
		score = 0;
		trails = [[], [], [], []];
		chkdata = {
			n: 0,
			b: [0, 0, 0, 0]
		};
		parts = new Array();
		options = new Array();
		level = new Level(this);
		updateInterf();
	}

	function updateInterf() {
		life_mask.clear()
			.beginFill(0xFFFFFF)
			.drawRect(0, 0, life._width * lifepts / Cs.MAXLIFE, life._height)
			.endFill();
		speed.text = Std.int(Math.pow(level.cur_speed / Cs.NEW_GEN_SCALE, 0.75) * 30) + " KM/H";
	}

	function slowDown() {
		if (level.cur_speed > level.speed / 2)
			level.cur_speed *= Math.pow(0.98, Timer.tmod);
	}

	function updateF1() {
		var max = Cs.STEER_DELTA_MAX;
		var logicSpeed = level.speed / Cs.NEW_GEN_SCALE;
		var logicCurSpeed = level.cur_speed / Cs.NEW_GEN_SCALE;
		var time = Timer.tmod * logicSpeed / 5;
		var dd = (oil_time > 0) ? Cs.STEER_INPUT_OIL : Cs.STEER_INPUT_DRY;

		if (!lock) {
			if (KeyboardManager.isDown(KeyboardManager.LEFT)) {
				delta -= dd * time;
				if (delta < -max)
					delta = -max;
				else
					slowDown();
			} else if (KeyboardManager.isDown(KeyboardManager.RIGHT)) {
				delta += dd * time;
				if (delta > max)
					delta = max;
				else
					slowDown();
			} else if (KeyboardManager.isDown(KeyboardManager.UP))
				level.cur_speed += Cs.NEW_GEN_SCALE;
		}
		delta += 0.05 * time * (Cs.MAXLIFE - lifepts) / Cs.MAXLIFE * ((Cs.random(2) == 0) ? -1 : 1);
		delta *= Math.pow((oil_time <= 0) ? Cs.STEER_FRICTION_DRY : Cs.STEER_FRICTION_OIL, time);
		if (delta > max)
			delta = max;
		else if (delta < -max)
			delta = -max;
		pos += delta * time * Cs.NEW_GEN_SCALE;
		if (pos < 5 * Cs.NEW_GEN_SCALE)
			pos = 5 * Cs.NEW_GEN_SCALE;
		else if (pos > 295 * Cs.NEW_GEN_SCALE)
			pos = 295 * Cs.NEW_GEN_SCALE;
		f1._rotation = delta * 15;
		f1._x = pos;
		f1._y = (250 + (logicSpeed - logicCurSpeed) * 2) * Cs.NEW_GEN_SCALE;
		shadow._x = f1._x + Cs.SHADOW_X;
		shadow._y = f1._y + Cs.SHADOW_Y;
		shadow._rotation = f1._rotation;
	}

	inline function wheelWorldPos(wheel:ASprite):{x:Float, y:Float} {
		var r = f1._rotation * Math.PI / 180;
		var cr = Math.cos(r);
		var sr = Math.sin(r);
		var sx = f1._xscale / 100;
		var sy = f1._yscale / 100;
		var lx = wheel._x * sx;
		var ly = wheel._y * sy;
		return {
			x: f1._x + lx * cr - ly * sr,
			y: f1._y + lx * sr + ly * cr
		};
	}

	function updateTrails(dp:Float) {
		var c = (oil_time > 0) ? 30 : ((Math.abs(f1._rotation) > 30) ? 10 : 0);
		if (f1._name != null) {
			var p1 = wheelWorldPos(f1.dr);
			var p2 = wheelWorldPos(f1.dl);
			var p3 = wheelWorldPos(f1.ur);
			var p4 = wheelWorldPos(f1.ul);
			trails[0].unshift({
				x: p1.x,
				y: p1.y,
				c: c
			});
			trails[1].unshift({
				x: p2.x,
				y: p2.y,
				c: c
			});
			trails[2].unshift({
				x: p3.x,
				y: p3.y,
				c: c
			});
			trails[3].unshift({
				x: p4.x,
				y: p4.y,
				c: c
			});
		}
		trail_mc.clear();
		c = null;
		for (tr in trails) {
			var p = tr[0];
			trail_mc.moveTo(p.x, p.y);
			var i = 1;
			while (i < tr.length) {
				p = tr[i];
				p.y += dp;
				if (c != p.c) {
					c = p.c;
					trail_mc.lineStyle(3 * Cs.NEW_GEN_SCALE, 4, p.c);
				}
				trail_mc.lineTo(p.x, p.y);
				if (p.y > 300 * Cs.NEW_GEN_SCALE)
					break;
				i++;
			}
			tr.splice(i, tr.length - i);
		}
	}

	function getOption(id:Int) {
		switch (id) {
			case 0:
				lifepts += 20;
				if (lifepts > Cs.MAXLIFE)
					lifepts = Cs.MAXLIFE;
			case 1 | 2 | 3:
				var mc = new Phys(dmanager.empty(Cs.PLAN_INTERFACE));
				mc.root._x = f1._x;
				mc.root._y = f1._y;
				mc.timer = 32;
				var txt = mc.root.initTextField("field", {
					font: "Junegull-Regular",
					size: 30,
					color: 0xFFFFFF,
					align: "center",
				});
				txt.text = Std.string(KKApi.val(BONUS[id - 1]));
				KadoKadeoManager.kkm.addScore(BONUS[id - 1]);
				chkdata.b[id]++;
			case 4:
				chkdata.b[0]++;
				oil_time += 2 + Cs.random(200) / 100;
		}
	}

	inline function optionHitsCar(optionMc:ASprite):Bool {
		var radius = 12 * Cs.NEW_GEN_SCALE;
		var carScaleX = f1._xscale / 100;
		var carScaleY = f1._yscale / 100;
		var halfW = 18 * Cs.NEW_GEN_SCALE * carScaleX;
		var halfH = 26 * Cs.NEW_GEN_SCALE * carScaleY;

		var dx = optionMc._x - f1._x;
		var dy = optionMc._y - f1._y;

		var a = -f1._rotation * Math.PI / 180;
		var ca = Math.cos(a);
		var sa = Math.sin(a);
		var localX = dx * ca - dy * sa;
		var localY = dx * sa + dy * ca;

		var closestX = Math.max(-halfW, Math.min(localX, halfW));
		var closestY = Math.max(-halfH, Math.min(localY, halfH));
		var distX = localX - closestX;
		var distY = localY - closestY;
		return distX * distX + distY * distY <= radius * radius;
	}

	function updateOptions(dp:Float) {
		var i = 0;
		while (i < options.length) {
			var o = options[i];
			o.mc._y += dp;
			if (optionHitsCar(o.mc)) {
				getOption(o.id);
				o.mc._y = 600 * Cs.NEW_GEN_SCALE;
			}
			if (o.mc._y > 320 * Cs.NEW_GEN_SCALE) {
				o.mc.removeMovieClip();
				options.splice(i--, 1);
			}
			i++;
		}
		if (level.pos < Level.DELTA - 25 * Cs.NEW_GEN_SCALE
			&& Cs.random(Std.int(Cs.OPTIONS_PROBA * (options.length / 5 + 1) / Timer.tmod)) == 0) {
			var ntries = 20;
			var y = -10 * Cs.NEW_GEN_SCALE;
			var x;
			do {
				x = (30 + Cs.random(240)) * Cs.NEW_GEN_SCALE;
				if (!level.middleContains(x - 15 * Cs.NEW_GEN_SCALE, y)
					&& !level.middleContains(x + 15 * Cs.NEW_GEN_SCALE, y)
					&& !level.middleContains(x, y - 15 * Cs.NEW_GEN_SCALE)
					&& !level.middleContains(x, y + 15 * Cs.NEW_GEN_SCALE))
					break;
			} while (--ntries > 0);
			if (ntries == 0)
				return;
			var mc = dmanager.attach("option", Cs.PLAN_OPTION);
			var sum = 0;
			var id;

			for (opt in Cs.OPTIONS)
				sum += opt;

			sum = Cs.random(sum);

			id = 0;
			while (sum >= Cs.OPTIONS[id])
				sum -= Cs.OPTIONS[id++];

			if (id == 0 && lifepts == Cs.MAXLIFE) {
				mc.removeMovieClip();
				return;
			}

			mc._x = x;
			mc._y = y;
			if (id == 4)
				mc.gotoAndStop(Cs.random(3) + 5);
			else
				mc.gotoAndStop(id + 1);
			options.push({id: id, mc: mc});
		}
	}

	function genParticules() {
		var mc = dmanager.attach("part", Cs.PLAN_PART);
		mc._x = f1._x;
		mc._y = f1._y + 10 * Cs.NEW_GEN_SCALE;
		mc._xscale = (25 + Cs.random(40)) * Cs.NEW_GEN_SCALE;
		mc._yscale = mc._xscale;
		mc._rotation = Cs.random(360);
		mc.tint = 0x224400;
		mc._alpha = 30;
		mc.gotoAndStop(3);
		parts.push({
			mc: mc,
			sx: (Cs.random(8) - 4) * Cs.NEW_GEN_SCALE,
			sy: -(3 + Cs.random(30) / 10) * Cs.NEW_GEN_SCALE,
			ay: 0.95,
			ss: 0,
			sr: 10
		});
	}

	function genSmoke() {
		var sx = (Cs.random(8) - 4) / 5 * Cs.NEW_GEN_SCALE;
		for (i in 0...3) {
			var mc = dmanager.attach("part", Cs.PLAN_PART);
			mc.gotoAndStop(1);
			mc._x = f1._x + (Cs.random(10) - 5) * Cs.NEW_GEN_SCALE;
			mc._y = f1._y + (Cs.random(10) - 5) * Cs.NEW_GEN_SCALE;
			mc._xscale = 60 + Cs.random(40);
			mc._yscale = mc._xscale;
			mc._rotation = Cs.random(360);
			mc._alpha = 30;
			parts.push({
				mc: mc,
				sx: sx,
				sy: -5 * Cs.NEW_GEN_SCALE * level.speed / Cs.MINSPEED,
				ay: 1,
				ss: 3,
				sr: 30
			});
		}
	}

	function updateParticules(dp:Float) {
		var i = 0;
		while (i < parts.length) {
			var p = parts[i];
			p.sy *= Math.pow(p.ay, Timer.tmod);
			p.mc._xscale += p.ss * Timer.tmod;
			p.mc._yscale += p.ss * Timer.tmod;
			p.mc._x += p.sx * Timer.tmod;
			p.mc._y += p.sy * Timer.tmod + dp;
			p.mc._rotation += p.sr * Timer.tmod;
			if (p.mc._y > 310 * Cs.NEW_GEN_SCALE) {
				p.mc.removeMovieClip();
				parts.splice(i--, 1);
			}
			i++;
		}
	}

	public function update(delta:Float):Void {
		updateF1();
		var dp = level.main();
		updateTrails(dp);
		updateOptions(dp);
		if (oil_time >= 0)
			oil_time -= Timer.deltaT;
		if (!lock && level.wallContains(f1._x, f1._y)) {
			lifepts -= Timer.tmod * level.cur_speed / 2 / Cs.NEW_GEN_SCALE;
			// var p = new Phys(dmanager.empty(Cs.PLAN_PART));
			// p.root._x = Math.random() * Cs.WIDTH / 2 + Cs.WIDTH / 4;
			// p.root._y = 50;
			// p.root.initTextField("field", {
			// 	font: "Junegull-Regular",
			// 	size: 70,
			// 	color: 0xFF0000,
			// 	align: "center",
			// }).text = "HORS PISTE";
			// p.timer = 1;
			// p.fadeLimit = 0;
			for (_ in 0...3)
				slowDown();
			genParticules();
			if (lifepts < 0) {
				lifepts = 0;
				lock = true;
				oil_time = 0;
				expl_mc = dmanager.attach("explosion", Cs.PLAN_PART);
				expl_mc.play();
				expl_mc._alpha = 70;
				expl_mc._xscale = Cs.CAR_SCALE;
				expl_mc._yscale = Cs.CAR_SCALE;
				expl_mc._x = f1._x;
				expl_mc._y = f1._y;
				expl_mc.removeOnFrame = 18;
				f1.removeMovieClip();
				shadow.removeMovieClip();
				KadoKadeoManager.kkm.gameOver(chkdata);
			}
		}

		if (!lock && lifepts < Cs.MAXLIFE / 2 && Cs.random(Std.int(30 * (lifepts / Cs.MAXLIFE) / Timer.tmod)) == 0)
			genSmoke();

		if (expl_mc != null) {
			expl_mc._y += dp / 3;
		}
		updateParticules(dp);
		updateInterf();
		if (!lock) {
			score += Timer.tmod * level.cur_speed / 3;
			var ratio = 5;
			var s = Std.int(score / ratio);
			score -= s * ratio;
			KadoKadeoManager.kkm.addScore(KKApi.const(s));
		}
		Sprite.updateAll();

		// Debug
		// lifepts = 100;
		// if (KeyboardManager.isDown(KeyboardManager.A)) {
		// 	level.cur_speed = 1;
		// }

		// if (KeyboardManager.isJustDown(KeyboardManager.D)) {
		// 	if (level.walls.mask != null) {
		// 		level.walls.mask = null;
		// 		for (i in 0...5) {
		// 			f1.children[i].visible = false;
		// 		}
		// 		f1.getGraphics().clear().beginFill(0xFF00FF).drawCircle(0, 0, 5).endFill();
		// 		life_container._alpha = 10;
		// 	} else {
		// 		level.walls.mask = level.walls_mask;
		// 		f1.getGraphics().clear();
		// 		for (i in 0...5) {
		// 			f1.children[i].visible = true;
		// 		}
		// 		life_container._alpha = 100;
		// 	}
		// }
	}

	public function destroy():Void {}
}
