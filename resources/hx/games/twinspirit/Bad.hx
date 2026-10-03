package twinspirit;

enum ShipSize {
	Normal;
	Huge;
}

class Bad extends Phys {
	var fam:BadFamily;
	var size:ShipSize;

	var flDeath:Bool;

	public var rid:Int;
	public var bsid:Int;

	var px:Null<Int>;
	var py:Null<Int>;

	var life:Float;
	var flh:Null<Float>;

	public var scy:Float;

	public var behaviours:Array<Behaviour>;
	public var status:Array<Status>;

	public var seed:mt.Rand;
	public var skin:Clip;
	public var robs:Array<Robot>;

	public function new(mc:ASprite, rid:Int) {
		super(mc);
		this.rid = rid;
		Game.me.bads.push(this);

		behaviours = [];

		bsid = 0;
		life = 1;
		ray = 10;
		scy = 1;
		flDeath = false;

		x = -100;
		y = 0;
		size = Normal;
	}

	public function addDestiny(d:Array<Command>, ?flMain:Bool) {
		if (robs == null)
			robs = [];
		var rob = new Robot(this);
		rob.flMain = true;
		rob.destiny = d;
		robs.push(rob);
	}

	public function setSeed(n:Int) {
		seed = new mt.Rand(n);
	}

	override public function update() {
		super.update();

		if (robs != null) {
			// (a robot removing itself makes the loop skip the next one, like the original)
			var i = 0;
			while (i < robs.length) {
				robs[i].update();
				i++;
			}
		}
		updateGridPos();

		updateBehaviours();

		if (skin != null) {
			var reac = skin.get("reac");
			if (reac != null)
				reac._visible = Math.abs(vx) + Math.abs(vy) > 3;
		}

		if (flh != null)
			fxFlash();
	}

	// FAMILY
	public function setFamily(fam:BadFamily) {
		this.fam = fam;
		root.gotoAndStop(Type.enumIndex(fam) + 1);

		skin = (cast root : Clip).getClip("smc");

		switch (fam) {
			case DRONE:
				life = 2;
				ray = 10;
			case SUPER_DRONE:
				life = 4;
				ray = 10;
			case SENTINELLE:
				life = 10;
				ray = 15;
			case ZILA:
				life = 40;
				ray = 20;
			case ASSASSIN:
				life = 15;
				ray = 15;
			case VOLT_BALL:
				life = 50;
				ray = 15;
			case BEHEMOTH:
				life = 100;
				ray = 30;
				scy = 0.7;
			case KOBOLD:
				life = 4;
				ray = 12;
		}
	}

	// skin.smc: the part of the skin animated by the code
	public function skinSmc():Clip {
		return skin != null ? skin.getClip("smc") : null;
	}

	// BEHAVIOURS
	public function updateBehaviours() {
		var i = 0;
		while (i < behaviours.length) {
			behaviours[i].update();
			i++;
		}
	}

	// GRID
	function updateGridPos() {
		if (flDeath || size != Normal)
			return;
		var npx = Cs.getPX(x);
		var npy = Cs.getPY(y);
		if (npx != px || npy != py) {
			removeFromGrid();
			px = npx;
			py = npy;
			insertInGrid();
		}
	}

	function insertInGrid() {
		for (x in 0...3)
			for (y in 0...3)
				Game.me.badCell(px + x - 1, py + y - 1).push(this);
	}

	function removeFromGrid() {
		if (px == null)
			return;
		for (x in 0...3)
			for (y in 0...3)
				Game.me.badCell(px + x - 1, py + y - 1).remove(this);
	}

	// DAMAGE
	public function impact(shot:HeroShot) {
		if (haveStatus(INVINCIBLE)) {
			shot.fxBounce(this);
			return;
		}

		shot.fxImpact();
		damage(shot.damage);
	}

	function damage(n:Float) {
		fxFlash(1);
		life = Math.max(0, life - n);
		if (life == 0)
			explode();
	}

	public function explode(?flSuicide:Bool) {
		if (flSuicide != true) {
			var sc = Cs.getScore(fam);
			sc += Game.me.bonus;
			Game.me.fayot._k[Type.enumIndex(fam)]++;
			var col = 0;
			if (rid == Game.me.robertId) {
				col = 0xFF0000;
				sc = Cs.SCORE_ROBERT;
			}
			Game.me.genScore(x, y, sc, col);
			Game.me.addScore(sc);
			Game.me.incBonus(1);
		}

		fxExplode();
		kill();
	}

	// KILL
	override public function warp() {
		var max = Std.int(ray * 0.3);

		var dx = x - Game.me.htrg.x;
		var dy = y - Game.me.htrg.y;
		var dist = Math.sqrt(dx * dx + dy * dy);

		for (i in 0...max) {
			var p = new mt.bumdum.Phys(Game.me.dm.attach("partLight", Game.DP_FX));
			p.x = x + (Seed.randVfx() * 2 - 1) * ray * 2;
			p.y = y + (Seed.randVfx() * 2 - 1) * ray * 2;

			var dx = p.x - Game.me.htrg.x;
			var dy = p.y - Game.me.htrg.y;
			var a = Math.atan2(dy, dx);
			var sp = Math.max(70 - Math.pow(dist, 0.4) * 8, 5) * 0.8 + Seed.randVfx() * 0.4;

			p.vx = Math.cos(a) * sp;
			p.vy = Math.sin(a) * sp;
			p.frict = 0.95;
			p.timer = 10 + Seed.randVfx() * 10;
			p.setScale(50 + Seed.randVfx() * 100);
			p.fadeType = 0;
			p.updatePos();
		}

		kill();
	}

	public function vanish() {
		if (Game.me.bonus > 5)
			Game.me.fayot._m.push(Game.me.bonus);
		Game.me.setBonus(0);
		kill();
	}

	override public function kill() {
		if (mcLabel != null)
			mcLabel.removeMovieClip();
		flDeath = true;
		removeFromGrid();
		Game.me.bads.remove(this);
		super.kill();
	}

	// FX
	function fxExplode() {
		var max = 1 + Std.int(ray / 5);

		for (i in 0...max) {
			var mc = Game.me.dm.add(new Mc("explosion", true, 0.5), Game.DP_UNDER_FX);
			var p = new mt.bumdum.Phys(mc);
			mc.onEnd = p.kill;
			p.x = x + (Seed.randVfx() * 2 - 1) * ray;
			p.y = y + (Seed.randVfx() * 2 - 1) * ray;
			p.root._rotation = Seed.randVfx() * 360;
			p.weight = 3 + Seed.randVfx();
			p.vx = (Seed.randVfx() * 2 - 1) * 3;
			p.vy = -(8 + Seed.randVfx() * 6);
			p.updatePos();
			p.sleep = i;
			p.root.stop();
			p.setScale(ray * 5);
			p.updatePos();
		}
	}

	// Col.setColor(root, 0, inc): white added
	function fxFlash(?n:Null<Float>) {
		if (n != null)
			flh = n;
		var inc = Std.int(flh * 255);
		flh *= 0.5;
		if (flh < 0.1) {
			flh = null;
			inc = 0;
		}
		(cast root : Clip).setColour(0xFFFFFF, (inc << 16) | (inc << 8) | inc);
	}

	// STATUS
	public function addStatus(st:Status) {
		if (status == null)
			status = [];
		status.push(st);
	}

	public function removeStatus(st:Status) {
		if (status != null)
			status.remove(st);
	}

	public function haveStatus(st:Status) {
		if (status == null)
			return false;
		for (sta in status)
			if (sta == st)
				return true;
		return false;
	}

	// TOOLS
	public function isOut(n:Float) {
		return x < -n || x > Cs.mcw + n || y < -n || y > Cs.mch + n;
	}
}
