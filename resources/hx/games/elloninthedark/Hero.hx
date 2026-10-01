package elloninthedark;

import mt.DepthManager;
import common_haxe_avm1.KeyboardManager;

typedef RaySprite = {mc:ASprite, vr:Float, t:Float, ys:Float};
typedef Tentacule = {phase:Float, trg:{x:Float, y:Float}, timer:Float};

class Hero extends Phys {
	public static var DP_UNDER = 3;
	public static var DP_UNDER2 = 4;
	public static var DP_BODY = 5;
	public static var DP_SHIELD = 2;
	public static var FIRE_ANGLE = -0.1;

	public static var SHOT_COLOR = [0xFFDD66, 0xDD44FF, 0x44DDFF];
	public static var GROUND_DECAL = KadoKadeoManager.I(7);

	// frames of the original "mcHero" clip
	static inline var BODY_AIR = 1;
	static inline var BODY_GROUND = 2;
	static inline var BODY_GUM = 3;

	//
	public var flBuild:Bool;
	public var flSpeedUp:Bool;
	public var flShield:Bool;

	public var speed:Float;

	public var step:Int;

	public var shotType:Int;
	public var shotPower:Int;

	public var sideType:Null<Int>;
	public var sidePower:Int;
	public var sideCooldown:Float;

	public var fa:Float;
	public var cooldown:Float;

	public var runFrame:Float;
	public var lastAngle:Float;
	public var vr:Float;
	public var build:Float;
	public var rage:Null<Float>;
	public var shieldTimer:Float;

	public var dm:DepthManager;

	var aura:ASprite;
	var sList:Array<ASprite>;
	var rList:Array<RaySprite>;

	public var tList:Array<Tentacule>;

	// body: rebuilt for each frame of the original clip (air: broom flight / ground: legs + aiming torso / gum)
	var body:ASprite;
	var bodyFrame:Int;
	var bodyAnim:ASprite;
	var bodyClip:SlotClip;
	var torse:SlotClip;
	var bid:Int;

	var shield:ASprite;
	var shieldCore:ASprite;

	public function new(mc:ASprite) {
		super(mc);

		dm = new DepthManager(root);
		body = dm.empty(DP_BODY);
		bid = 1;

		sList = new Array();
		tList = new Array();
		rList = new Array();

		flBuild = false;
		flSpeedUp = false;
		flShield = false;

		speed = KadoKadeoManager.S(6);
		ray = KadoKadeoManager.I(11);

		shotType = 0;
		shotPower = 0;
		sideType = null;
		sidePower = 0;
		sideCooldown = 0;

		frict = 0.6;

		cooldown = 0;
		build = 0;
		x = 0;
		y = 0;

		initAir();
	}

	inline function isDown(k:Int) {
		return KeyboardManager.isDown(k);
	}

	override public function update() {
		super.update();

		cooldown -= Timer.tmod;
		sideCooldown -= Timer.tmod;

		switch (step) {
			case 0:
				control();
				recal();
				if (tList.length > 0)
					updateTentacule();
				if (rage != null && rage > 0)
					updateRage();

				var dr = Cs.u(vy) * 2 - body._rotation;
				body._rotation += dr * 0.1 * Timer.tmod;
				if (y == Cs.GL - (ray + GROUND_DECAL)) {
					initGround();
				}
			case 1:
				control();
				runFrame = (runFrame + (1 + Cs.u(vx) * 0.1) * (Cs.SCROLL_SPEED / KadoKadeoManager.S(5)) * Timer.tmod) % 20;
				var fr = Std.int(runFrame) + 1;
				if (bodyFrame == BODY_GROUND) {
					setRunFrame(fr);
					if (isDown(KeyboardManager.SPACE) || isDown(KeyboardManager.CONTROL)) {
						torse.gotoAndStop(Std.int(30 - (fa / 3.14) * 20) + 1);
					} else {
						torse.gotoAndStop(fr);
					}
				}

				x = Num.mm(ray, x, Cs.mcw - ray);

			case 9:
				if (x < -KadoKadeoManager.I(100)) {
					Cs.game.stats.d = Cs.game.dif;
					KadoKadeoManager.kkm.gameOver(Cs.game.stats);
					step = 10;
				}
				if (y + ray > Cs.GL) {
					y = Cs.GL - ray;
					vy *= -0.7;
					vx -= Cs.SCROLL_SPEED;
					vr *= 1.5;
					for (i in 0...3)
						genGroundSmoke();
				}
				body._rotation += vr * Timer.tmod;
		}

		if (flShield)
			updateShield();
	}

	// Flash strokes have round caps and joins (PIXI: butt / miter by default)
	static function lineStyle(g:pixi.core.graphics.Graphics, width:Float, color:Int, alpha:Float) {
		(cast g : Dynamic).lineTextureStyle({
			width: width,
			color: color,
			alpha: alpha,
			cap: "round",
			join: "round"
		});
	}

	function updateRage() {
		var list = Cs.game.badsList;
		var ec = KadoKadeoManager.S(8);
		var g = Cs.game.drawing;

		for (n in 0...3) {
			var b = list[Seed.random(list.length)];
			if (b == null)
				continue;
			var dx = b.x - x;
			var dy = b.y - y;
			var dist = Math.sqrt(dx * dx + dy * dy);
			var max = 2 + Std.int(dist / KadoKadeoManager.S(10));

			var a = new Array();
			for (i in 0...max) {
				var c = i / (max - 1);
				var pos = [x + dx * c + (Seed.randVfx() * 2 - 1) * ec, y + dy * c + (Seed.randVfx() * 2 - 1) * ec];
				a.push(pos);
			}
			lineStyle(g, KadoKadeoManager.S(8), 0x00FFFF, 0.2);
			g.moveTo(x, y);
			for (pos in a)
				g.lineTo(pos[0], pos[1]);
			lineStyle(g, KadoKadeoManager.S(1), 0xFFFFFF, 1);
			g.moveTo(x, y);
			for (pos in a)
				g.lineTo(pos[0], pos[1]);

			b.damage(0.2 * Timer.tmod);
		}

		rage -= 2 * Timer.tmod;
		if (rage < 0)
			rage = null;
	}

	function updateShield() {
		shieldTimer -= Timer.tmod;
		if (shieldTimer < 75) {
			shield._visible = !shield._visible;
			if (shieldTimer < 0) {
				flShield = false;
				shield.removeMovieClip();
				shield = null;
				return;
			}
		}
		shieldCore._xscale = 100 + (Seed.randVfx() * 2 - 1) * 3;
		shieldCore._yscale = shieldCore._xscale;
	}

	function initAir() {
		setBodyFrame(BODY_AIR);
		fa = FIRE_ANGLE;
		step = 0;
	}

	function initGround() {
		body._rotation = 0;
		setBodyFrame(BODY_GROUND);
		step = 1;
		runFrame = 0;
		lastAngle = 0;
		cancelBuild();
	}

	function setBodyFrame(f:Int) {
		bodyFrame = f;
		if (bodyAnim != null)
			bodyAnim.removeMovieClip();
		if (bodyClip != null)
			bodyClip.removeMovieClip();
		if (torse != null)
			torse.removeMovieClip();
		bodyAnim = null;
		bodyClip = null;
		torse = null;
		// the broom (normal / speed up with its golden aura), the scarf and the ribbon keep playing
		var broom = ["heroBalai" => "heroBalai" + bid];
		switch (f) {
			case BODY_GROUND:
				bodyAnim = body.attachMovie("heroLegs", "sub", 2);
				bodyAnim.stop();
				torse = new SlotClip(Data.HERO_TORSO, broom).attachTo(body, 3);
				setRunFrame(1);
			case _:
				bodyClip = new SlotClip(Data.HERO_BODY, broom).attachTo(body, 1);
				bodyClip.gotoAndStop(f == BODY_GUM ? 2 : 1);
		}
	}

	function setRunFrame(fr:Int) {
		bodyAnim.gotoAndStop(fr);
		var p = Data.TORSO_POS[fr - 1];
		torse._x = KadoKadeoManager.S(p[0]);
		torse._y = KadoKadeoManager.S(p[1]);
	}

	function control() {
		var sp = speed;
		if (flSpeedUp)
			sp *= 1.5;
		if (isDown(KeyboardManager.UP)) {
			if (step == 1)
				initAir();
			vy = -sp * Timer.tmod;
		}
		if (isDown(KeyboardManager.DOWN) && step == 0) {
			vy = sp * Timer.tmod;
		}
		if (isDown(KeyboardManager.LEFT)) {
			vx = -sp * Timer.tmod;
		}
		if (isDown(KeyboardManager.RIGHT)) {
			vx = sp * Timer.tmod;
		}

		if (isDown(KeyboardManager.SPACE) || isDown(KeyboardManager.CONTROL)) {
			shoot();
		} else {
			if (step == 0 && flBuild)
				buildUp();
		}
	}

	function buildUp() {
		build = Math.min(build + Timer.tmod, 100);
		if (build > 0) {
			if (Seed.randVfx() * 100 < build) {
				var mc = dm.attach("partRay", DP_UNDER);
				mc._rotation = Seed.randVfx() * 360;
				var vr = (Seed.randVfx() * 2 - 1) * 3;
				var ys = 50 + Seed.randVfx() * 100;
				mc._xscale = (60 + (Seed.randVfx() * 2 - 1) * 40) * (build / 100);
				mc._yscale = ys;
				var t = 12 + Seed.randVfx() * 20;
				mc.gotoAndStop(shotType + 1);
				rList.push({
					mc: mc,
					vr: vr,
					t: t,
					ys: ys
				});
			}

			var i = 0;
			while (i < rList.length) {
				var r = rList[i];
				r.mc._rotation += r.vr * Timer.tmod;
				r.t -= Timer.tmod;
				if (r.t < 10) {
					r.mc._yscale = r.ys * r.t / 10;
					if (r.t < 0) {
						r.mc.removeMovieClip();
						rList.splice(i--, 1);
					}
				}
				i++;
			}

			// STAR
			if (Seed.randomVfx(2) == 0) {
				var star = dm.attach("partBuild", DP_UNDER);
				star._rotation = Seed.randVfx() * 360;
				// the original scaled it with aura._xscale but the aura clip is never created
				star.onFrame.set(17, () -> {
					star.removeMovieClip();
					sList.pop();
				});
				star.play();
				sList.push(star);
				Col.setPercentColor(star, 100, SHOT_COLOR[shotType]);
			}
		}
	}

	function recal() {
		if (x < ray || x > Cs.mcw - ray) {
			x = Num.mm(ray, x, Cs.mcw - ray);
			vx = 0;
		}
		if (y < ray || y > (Cs.GL - (ray + GROUND_DECAL))) {
			y = Num.mm(ray, y, Cs.GL - (ray + GROUND_DECAL));
			vy = 0;
		}
	}

	function shoot() {
		// MAINSHOT
		if (cooldown < 0) {
			if (step == 1) {
				var m = getNearestMonster(0, 0);

				if (m != null) {
					var d = getDist(m);
					var c = d / KadoKadeoManager.S(16);
					var tx = (m.x + m.vx * c) - x;
					var ty = (m.y + m.vy * c) - y;
					fa = Math.atan2(ty, tx);
					if (fa > 0 && fa < 1.57) {
						fa = 0;
					}
					if (fa > 1.57) {
						fa = -3.14;
					}
				} else {
					fa = 0;
				}
			}

			switch (shotType) {
				case 0:
					if (build < 10) {
						{
							var shot = newShot(KadoKadeoManager.S(16), 0);
							shot.damage = Cs.DAMAGE_FIREBALL;
						}
						var max = Seed.random(shotPower * 3);
						for (i in 0...max) {
							var speed = KadoKadeoManager.S(6 + Seed.rand() * 8);
							var shot = newShot(speed, (Seed.rand() * 2 - 1) * 0.25);
							var scale = 60;
							shot.root._xscale = scale;
							shot.root._yscale = scale;
							shot.damage = Cs.DAMAGE_FIREBALL * 0.5;
						}
					} else {
						var power = build * 0.5;
						var shot = newShot(KadoKadeoManager.S(16), 0);
						shot.damage = 1 + power * 0.5;
						var scale = 150 + power * 5;
						shot.root._xscale = scale;
						shot.root._yscale = scale;
						shot.flPierce = true;
						shot.ray = KadoKadeoManager.S(6) * (scale / 100);
						shot.bList.push(1);
					}
					cooldown = 4;
				case 1:
					var max = Std.int(Num.mm(2, Std.int(build / 4), 25)) + shotPower * 2;
					var ecart = max * 0.07;
					for (i in 0...max) {
						var c = (i / (max - 1)) * 2 - 1;
						var shot = newShot(KadoKadeoManager.S(16), c * ecart);
						shot.setSkin(5);
						shot.damage = Cs.DAMAGE_SPARK;
					}

					cooldown = 6;
				case 2:
					var shot = newShot(KadoKadeoManager.S(16), 0);
					shot.setSkin(6);
					shot.damage = Cs.DAMAGE_LASER * Timer.tmod * (shotPower + 1);
					shot.root._yscale = 60 + shotPower * 50;
					shot.root._xscale = 100 + shotPower * 20;
					shot.flInvincible = true;
					cooldown = 3;
					if (build > 30) {
						rage = build - 30;
					}
			}
		}

		// END BUILD
		cancelBuild();

		// SIDE
		if (sideCooldown < 0 && step == 0) {
			switch (sideType) {
				case 0: // BOMB
					sideCooldown = 30 / (sidePower + 1);
					var s = newShot(0, 0);
					s.setSkin(3);
					s.weight = KadoKadeoManager.S(0.4 + Seed.rand() * 0.2);
					s.x -= KadoKadeoManager.I(10);
					s.vy = -KadoKadeoManager.S(3);
					s.vx = KadoKadeoManager.S(2 + Seed.rand() * 2);
					s.frict = 0.98;
					s.vr = (Seed.rand() * 2 - 1) * 20;
					s.bList.push(0);
					s.damage = Cs.DAMAGE_BOMB;
				case 1: // TENTACULE
				case 2: // HOMING;
					var max = sidePower + 1;

					for (i in 0...max) {
						var c = (i / (max - 1)) * 2 - 1;
						if (max == 1)
							c = 0;
						var s = newShot(KadoKadeoManager.S(5), c * max * 0.4);
						s.trg = getNearestMonster(Math.cos(s.a) * KadoKadeoManager.S(20), Math.sin(s.a) * KadoKadeoManager.S(20));
						s.va = 0.5;
						s.ca = 0.1;
						s.bList = [2, 3];
						s.speed = KadoKadeoManager.S(8);
						s.damage = Cs.DAMAGE_HOMING;
						s.setSkin(7);
						s.timer = 120;
					}
					sideCooldown = 30;
			}
		}
	}

	function cancelBuild() {
		while (sList.length > 0)
			sList.pop().removeMovieClip();
		while (rList.length > 0)
			rList.pop().mc.removeMovieClip();
		build = 0;
		if (aura != null) {
			aura.removeMovieClip();
			aura = null;
		}
	}

	public function hit(shot:Shot) {
		if (shot.ray > KadoKadeoManager.S(15))
			setBodyFrame(BODY_GUM);
		death();
	}

	public function death() {
		step = 9;
		weight = KadoKadeoManager.S(1);
		frict = 0.98;
		vr = 18;
		cancelBuild();
	}

	//
	public function newTentacule() {
		if (tList.length > 4)
			return;
		tList.push({
			phase: 0,
			timer: 100,
			trg: {x: x, y: y}
		});
	}

	function updateTentacule() {
		var g = Cs.game.drawing;
		for (n in 0...tList.length) {
			var info = tList[n];
			info.phase = (info.phase + 37) % 628;

			var c = (n / (tList.length - 1)) * 2 - 1;
			if (tList.length == 1)
				c = 0;
			var list = new Array();
			var pa = -3.14 + c * 1.3;
			var px = x;
			var py = y;
			var lim = 0.6;
			var turnCoef = 1;
			var speed = KadoKadeoManager.S(10);
			var sleep = 0.0;
			var phase = info.phase;

			var sbx = -Math.cos(pa) * KadoKadeoManager.S(100);
			var sby = -Math.sin(pa) * KadoKadeoManager.S(100);
			var m = getNearestMonster(sbx, sby);
			if (m != null) {
				var ddx = m.x - info.trg.x;
				var ddy = m.y - info.trg.y;
				var coef = 0.15;
				info.trg.x += ddx * coef * Timer.tmod;
				info.trg.y += ddy * coef * Timer.tmod;
			}

			// TRACE PATH
			for (i in 0...18) {
				sleep = Math.min(sleep + 0.1, 1);
				phase = (phase + 66) % 628;
				var dx = info.trg.x - px;
				var dy = info.trg.y - py;
				var da = Math.atan2(dy, dx) - pa;
				while (da > 3.14)
					da -= 6.28;
				while (da < -3.14)
					da += 6.28;
				var ma = Math.cos(phase / 100) * 0.5;

				pa += Num.mm(-lim, da * turnCoef, lim) * sleep;
				px += Math.cos(pa + ma) * speed;
				py += Math.sin(pa + ma) * speed;
				py = Math.min(py, Cs.GL - KadoKadeoManager.I(5));
				if (m != null && m.getDist({x: px, y: py}) < m.ray) {
					m.damage(Cs.DAMAGE_TENTACULE * Timer.tmod);
					KadoKadeoManager.kkm.addScore(Cs.C1);
					info.phase = (info.phase + 57) % 628;
					break;
				}
				list.push([px, py]);
			}

			// DRAW
			var bs = KadoKadeoManager.S(6);

			lineStyle(g, KadoKadeoManager.S(6), 0xFF00FF, 0.3);
			g.moveTo(x, y);
			for (i in 0...list.length) {
				var co = 1 - (i / list.length);
				lineStyle(g, KadoKadeoManager.S(5) + co * bs, 0xFF00FF, 1);
				var pos = list[i];
				g.lineTo(pos[0], pos[1]);
			}
			lineStyle(g, KadoKadeoManager.S(1.5), 0xFFFFFF, 1);
			g.moveTo(x, y);
			for (i in 0...list.length) {
				var co = 1 - (i / list.length);
				lineStyle(g, KadoKadeoManager.S(1.5) + co * bs, 0xFFFFFF, 1);
				var pos = list[i];
				g.lineTo(pos[0], pos[1]);
			}
		}
	}

	function removeAllTentacule() {
		tList = new Array();
	}

	//
	public function takeSide(id:Int) {
		if (sideType == id) {
			if (sideType == 1 && sidePower < 2)
				newTentacule();
			sidePower = Std.int(Math.min(sidePower + 1, 2));
		} else {
			if (sideType == 1) {
				removeAllTentacule();
			}
			if (id == 1) {
				for (i in 0...sidePower + 1)
					newTentacule();
			}
			sideType = id;
		}
	}

	public function initShield() {
		if (shield == null) {
			flShield = true;
			shield = dm.empty(DP_SHIELD);
			shieldCore = shield.attachMovie("heroShieldCore", "shield", 1);
			shieldCore.loop = true;
			shieldCore.play();
			var ring = shield.attachMovie("heroShieldRing", "ring", 3);
			ring.loop = true;
			ring.play();
			shieldTimer = 1000;
		}
	}

	public function initSpeedUp() {
		flSpeedUp = true;
		bid = 2;
		// body.balais.gotoAndStop("2"): only the flying broom exists in the air frame
		if (bodyFrame == BODY_AIR)
			setBodyFrame(BODY_AIR);
	}

	//
	public function newShot(sp:Float, ma:Float) {
		var shot = new Shot();
		shot.a = fa + (body._rotation * 0.0174) + ma;
		var ca = Math.cos(shot.a);
		var sa = Math.sin(shot.a);
		shot.x = x + ca * KadoKadeoManager.S(26);
		shot.y = y + sa * KadoKadeoManager.S(26);
		shot.vx = ca * sp;
		shot.vy = sa * sp;
		shot.frict = null;
		shot.orient();
		shot.flGood = true;

		return shot;
	}

	public function getNearestMonster(dx:Float, dy:Float):Bads {
		var dist = 1 / 0;
		var monster:Bads = null;
		for (i in 0...Cs.game.badsList.length) {
			var m = Cs.game.badsList[i];
			var d = getDist({x: m.x + dx, y: m.y + dy});
			if (d < dist) {
				dist = d;
				monster = m;
			}
		}
		return monster;
	}
}
