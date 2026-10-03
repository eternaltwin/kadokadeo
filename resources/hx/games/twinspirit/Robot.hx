package twinspirit;

// plays the commands (destiny) of an enemy: moves, turns, shots
class Robot {
	public var flMain:Bool;

	var p:Bad;
	var did:Int;

	var shotType:ShotType;
	var shotSpeed:Float;

	public var angle:Float;

	var orient:Orient;

	var loops:Array<Null<Int>>;
	var turner:{inc:Float, time:Int};
	var accel:{inc:Float, time:Int};
	var turret:{cycle:Float, cs:Float};
	var shootPos:{x:Float, y:Float};

	var gear:Null<Float>;

	public var push:Null<Float>;

	var wait:Float;

	public var destiny:Array<Command>;

	public function new(trg:Bad) {
		p = trg;
		destiny = [];
		loops = [];
		flMain = false;

		setShotType(STNormal);

		wait = 0;
		did = 0;
		angle = 1.57;
	}

	public function update() {
		if (wait > 0)
			wait--;
		while (wait <= 0 && did < destiny.length) {
			playNext();
		}

		if (turner != null) {
			turner.time--;
			incAngle(turner.inc);
			if (turner.time == 0)
				turner = null;
		}

		if (accel != null) {
			accel.time--;
			gear += accel.inc;
			if (accel.time == 0)
				accel = null;
			updateGear();
		}

		if (orient != null) {
			switch (orient) {
				case Front(coef):
					var a = Cs.atan2(p.vy, p.vx);
					var dr = Num.hMod((a / 0.0174 - 90) - p.root._rotation, 180);
					p.root._rotation += dr * coef;
				case Incline(coef):
					var c = 0.5;
					var dr = Num.hMod(p.vx * coef - p.root._rotation, 180);
					p.root._rotation += dr * c;
			}
		}

		if (turret != null) {
			turret.cycle = (turret.cycle + turret.cs) % 628;
		}

		if (push != null) {
			p.vx += Cs.cos(angle) * push;
			p.vy += Cs.sin(angle) * push;
		}

		if (wait <= 0 && did == destiny.length) {
			if (flMain) {
				if (p.isOut(p.ray))
					p.vanish();
			} else {
				p.robs.remove(this);
			}
		}
	}

	// COMMANDS
	function playNext() {
		var cmd = destiny[did];
		playCommand(cmd);
		did++;
	}

	function playCommand(cmd:Command) {
		switch (cmd) {
			// POSITION
			case Pos(px, py):
				p.x = px;
				p.y = py;
				p.updatePos();
				p.root.updateState();

			case StarPos(px, py, a, d):
				p.x = px + Cs.cos(a) * d;
				p.y = py + Cs.sin(a) * d;
				angle = a + 3.14;
				updateGear();
				p.updatePos();
				p.root.updateState();

			// POUSSEE
			case Gear(n):
				setGear(n);

			case Impulse(n, a):
				gear = null;
				if (a == null)
					a = angle;
				p.vx += Cs.cos(a) * n;
				p.vy += Cs.sin(a) * n;

			case Push(n, a):
				gear = null;
				if (a == null)
					a = angle;
				push = n;

			case Acc(n, t):
				if (gear == null)
					setGear(0);
				accel = {
					inc: n / t,
					time: t
				};

			// ROTATION
			case Rot(n):
				angle = Num.hMod(angle + n, 3.14);
				updateGear();

			case Angle(n):
				angle = n;
				updateGear();

			case Turn(n, t):
				turner = {
					inc: n / t,
					time: t
				};

			case SetOrient(or):
				orient = or;

			// SHOOT
			case Shoot(ca, ra):
				var na = 0.0;
				if (ra != null)
					na += (p.seed.rand() * 2 - 1) * ra;
				shoot(angle + (ca + na) * 3.14);

			case Fire(ca, ra):
				var na = 0.0;
				if (ra != null)
					na += (p.seed.rand() * 2 - 1) * ra;
				shoot((ca + 0.5 + na) * 3.14);

			case Aim(ra, sp):
				var h = Game.me.getMainHero();
				var dx = h.x - p.x;
				var dy = h.y - p.y;
				shoot(Cs.atan2(dy, dx) + (p.seed.rand() * 2 - 1) * ra * 3.14, sp);

			case ShotType(n):
				setShotType(n);
			case ShotPos(px, py):
				shootPos = {x: px, y: py};
				if (px == null)
					shootPos = null;

			// TURRET
			case Turret(cs):
				turret = {cycle: 0.0, cs: cs};

			case TurretStrafe(ec):
				var a = angle + Cs.sin(turret.cycle * 0.01) * ec;
				shoot(a);

			case TurretShoot(max):
				for (i in 0...max) {
					var na = 6.28 * i / max;
					var a = turret.cycle * 0.01 + na;
					shoot(a);
				}

			case TurretCycle(n):
				turret.cycle = (turret.cycle + n) % 628;

			// MISC
			case Back(n, time):
				if (loops[did] == null)
					loops[did] = 0;
				if (loops[did] < time) {
					loops[did]++;
					did -= n + 1;
					for (i in did...did + n + 1) {
						if (loops[i] != null && loops[i] > 0)
							loops[i] = 0;
					}
				}

			case Wait(n):
				wait = n;
			case Frict(n):
				p.frict = n;
			case AddBehaviour(bh):
				bh.init(p);
			case RemoveBehaviour(id):
				if (id == null)
					id = 0;
				var bh = p.behaviours[id];
				if (bh != null)
					bh.kill();
			case AddStatus(st):
				p.addStatus(st);
			case RemoveStatus(st):
				p.removeStatus(st);

			// GFX
			case PlayAnim(fr):
				var s = p.skinSmc();
				if (s != null)
					s.gotoAndPlay(fr);
			case Spin(rot, vr):
				p.root._rotation = rot;
				p.vr = vr;
		}
	}

	// MOVE
	function setGear(n:Float) {
		gear = n;
		p.frict = null;
		updateGear();
	}

	function updateGear() {
		if (gear == null)
			return;
		p.vx = Cs.cos(angle) * gear;
		p.vy = Cs.sin(angle) * gear;
	}

	function incAngle(n:Float) {
		angle = Num.hMod(angle + n, 3.14);
		updateGear();
	}

	// SHOOT
	public function setShotType(n:ShotType) {
		shotType = n;
		switch (shotType) {
			case STNormal:
				shotSpeed = 2.0;
			case STSpeed:
				shotSpeed = 4.0;
			default:
		}
	}

	public function shoot(a:Float, ?sp:Null<Float>) {
		if (sp == null)
			sp = shotSpeed;

		var shot = new BadShot(Game.me.dm.add(new Clip("mcBadShot"), Game.DP_BADS), p.rid, p.bsid);
		p.bsid++;
		shot.setType(shotType);
		var ca = Cs.cos(a);
		var sa = Cs.sin(a);
		shot.vx = ca * sp;
		shot.vy = sa * sp;

		if (shootPos == null) {
			shot.x = p.x + ca * p.ray;
			shot.y = p.y + sa * p.ray;
		} else {
			shot.x = p.x + shootPos.x;
			shot.y = p.y + shootPos.y;
		}

		switch (shotType) {
			case STSpeed:
				shot.vr = 17;
				shot.root._rotation = Seed.randVfx() * 360;
			default:
		}

		shot.updatePos();
		shot.root.updateState();
	}
}
