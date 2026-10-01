package kanjisadventure;

import kanjisadventure.ent.Bad;

class Ent {
	var flDamage:Bool;
	var flDeath:Bool;
	var flDoubleDamage:Bool;

	public var flFreeze:Bool;
	public var flBad:Bool;
	public var flGood:Bool;
	public var flTrader:Bool;

	public var x:Int;
	public var y:Int;

	public var direction:Int;

	public var damageMin:Int;
	public var damageMax:Int;
	public var armor:Int;
	public var lifeMax:Int;
	public var life:Int;

	public var agility:Int;
	public var dodge:Int;
	public var damage:Null<Int>;

	public var strikeId:Null<Int>;

	public var floor:Floor;
	public var sq:Square;

	public var action:Action;

	// clip of the original, attached in the square "host" (it stays in the square it leaves while it moves)
	public var root:ASprite;
	public var host:Square;
	// its "smc" child, moved by the attacks
	public var body:ASprite;

	// rest position of "smc" in the original clip (the attack code leaves it at (12, 16))
	var restX:Float;
	var restY:Float;
	var bodyX:Float;
	var bodyY:Float;
	// walk cycle frame of the clip ("anim" of the original, only the hero has one)
	var animFrame:Int;
	var animFrames:Int;

	public function new() {
		flDamage = false;
		flDeath = false;
		flDoubleDamage = false;
		flFreeze = false;
		flBad = false;
		flGood = false;
		flTrader = false;
		damageMin = 1;
		damageMax = 1;
		armor = 0;
		agility = 3;
		dodge = 4;
		lifeMax = 3;
		restX = 12;
		restY = 16;
		bodyX = 0;
		bodyY = 0;
		animFrame = 1;
		animFrames = 0;
	}

	public function init() {
		life = lifeMax;
		setDirection(1);
	}

	public function setFloor(fl:Floor) {
		if (floor != null)
			floor.ents.remove(this);
		floor = fl;
		if (this == Game.me.hero)
			floor.ents.unshift(this);
		else
			floor.ents.push(this);
	}

	public function first() {
		floor.ents.remove(this);
		floor.ents.unshift(this);
	}

	// CHECK
	public function checkAttack() {}

	public function checkMove() {}

	// ACTION
	public function setAction(ac:Action) {
		action = ac;
		if (ac != null) {
			Game.me.work.push(this);
			Game.me.active.remove(this);
		} else {
			Game.me.work.remove(this);
		}

		switch (action) {
			case Goto(dir):
				initMove(dir);
			case Attack(dir):
				initAttack(dir);
			case null:
		}
	}

	public function update(coef:Float) {
		if (flDeath) {
			setAction(null);
			return;
		}
		switch (action) {
			case Goto(dir):
				move(dir, coef);
			case Attack(dir):
				attack(dir, coef);
			case null:
		}
	}

	// MOVE
	function initMove(di:Null<Int>) {
		if (di == null)
			return;
		var d = Cs.DIR[di];
		var next = floor.grid[sq.x + d[0]][sq.y + d[1]];
		setSquare(next);
		if (di == 1) {
			display();
			root._y -= Cs.CS;
			root.updateState();
		}

		if (getHeroDist() <= Game.me.huntMax)
			floor.buildTracks();

		setDirection(di);
	}

	function move(di:Null<Int>, coef:Float) {
		if (di == null)
			return;
		var c = coef;
		if (di == 1)
			c = coef - 1;
		var d = Cs.DIR[di];
		root._x = c * d[0] * Cs.CS;
		root._y = c * d[1] * Cs.CS;

		if (animFrames > 0) {
			animFrame = animFrame == animFrames ? 1 : animFrame + 1;
			if (body != null)
				body.gotoAndStop(animFrame);
		}

		if (coef == 1) {
			display();
			x = sq.x;
			y = sq.y;
			setAction(null);
		}
	}

	// ATTACK
	function initAttack(di:Int) {
		setDirection(di);
	}

	function attack(di:Int, coef:Float) {
		var d = Cs.DIR[di];
		var trg = floor.grid[sq.x + d[0]][sq.y + d[1]].ent;

		if (!flDamage) {
			flDamage = true;

			// DODGE
			damage = null;
			if (trg == null) {
				// the target is gone (killed by an ally): the original rolled against NaN
				Seed.rand();
			} else {
				var c = agility / trg.dodge;
				if (Seed.rand() < c) {
					damage = getDamage();
					damage -= trg.armor;
					if (damage < 0)
						damage = 0;
				}

				trg.fxDamage(damage);
				if (damage != null) {
					trg.fxStrike(strikeId, di);
					trg.hurt(damage);
				}

				if (Game.me.hero == this) {
					if (damage != null && damage > 0)
						Game.me.log("Vous infligez " + damage + " dégat(s) à " + trg.getName() + ".");
					else if (damage == 0)
						Game.me.log(trg.getName() + " encaisse votre attaque sans broncher.");
					else
						Game.me.log(trg.getName() + " évite votre coups.");
				}
				if (Game.me.hero == trg) {
					if (damage != null && damage > 0)
						Game.me.log(getName() + " vous inflige " + damage + " dégat(s).");
					else if (damage == 0)
						Game.me.log(getName() + " ne parvient pas a vous blesser.");
					else
						Game.me.log("Vous esquivez l'attaque de " + getName() + ".");
				}
			}
		}

		var c = Math.max(1 - coef * 1.5, 0);
		var cx = 12;
		var cy = 16;
		var dc = 4;
		setBodyPos(cx + c * d[0] * dc, cy + c * d[1] * dc);

		if (damage != null && damage > 0 && trg != null && trg.body != null) {
			var sens = trg.bodyX + trg.restX > cx ? -1 : 1;
			trg.setBodyPos(cx + c * 6 * sens, trg.bodyY + trg.restY);
			Col.setPercentColor(trg.body, (1 - coef) * 100, 0xFF0000);
		}

		if (coef == 1) {
			flDamage = false;
			setAction(null);
		}
	}

	// position of "smc" in the clip of the original (1x units)
	public function setBodyPos(px:Float, py:Float) {
		bodyX = px - restX;
		bodyY = py - restY;
		if (body != null) {
			body._x = KadoKadeoManager.S(bodyX);
			body._y = KadoKadeoManager.S(bodyY);
		}
	}

	//
	public function freeze() {
		flFreeze = true;
		display();
	}

	//
	public function hurt(n:Null<Int>) {
		if (n == null)
			return;
		life -= n;
		if (n > 0 && Game.me.hero == this) {
			Game.me.fxFlash(0xFF0000);
		}
		if (life <= 0) {
			life = 0;
			die();
		}
	}

	public function fxDamage(n:Null<Int>) {
		var mc = floor.dm.empty(Square.DP_FX);
		var top = root != null ? root.getLocalBounds().y : -Cs.CS;
		new LossPart(mc, (x + 0.5) * Cs.CS, (y + 0.5) * Cs.CS + top, n == null ? "miss" : Std.string(n), n == null ? 0x000000 : 0xFF0000);
	}

	public function fxStrike(id:Null<Int>, di:Int) {
		if (id == null)
			return;
		var mc = sq.dm.attach("mcStrike" + (id + 1), Square.DP_FX);
		mc._x = Cs.CS * 0.5;
		mc._y = Cs.CS * 0.5;
		mc._rotation = di * 90;
		mc.removeOnFrame = mc._totalframes;
		mc.play();
	}

	public function getDamage() {
		var dmg = damageMin + Seed.random(1 + damageMax - damageMin);
		if (flDoubleDamage)
			dmg *= 2;
		return dmg;
	}

	public function die() {
		flDeath = true;
		kill();
	}

	public function setPos(x:Int, y:Int) {
		this.x = x;
		this.y = y;
		setSquare(floor.grid[x][y]);
	}

	public function setSquare(square:Square) {
		if (sq != null && sq.ent == this)
			sq.ent = null;
		sq = square;
		sq.ent = this;
	}

	// DISPLAY / ATTACH
	public function display() {
		if (root != null)
			root.removeMovieClip();
		// a new clip: its walk cycle starts again
		animFrame = 1;
		bodyX = 0;
		bodyY = 0;
		attach();
		refreshBody();
		if (flFreeze) {
			Filt.grey(root, 1, 0, {r: 0, g: 150, b: 210});
		}
	}

	function attach() {
		host = sq;
		root = sq.dm.empty(Square.DP_ACTOR);
		body = null;
	}

	// animation and frame of the "smc" clip
	function bodyName():String {
		return "";
	}

	function bodyFrame():Int {
		return 1;
	}

	function refreshBody() {
		if (root == null)
			return;
		if (body != null)
			body.removeMovieClip();
		body = root.attachMovie(bodyName(), "smc", 1);
		body.gotoAndStop(bodyFrame());
		body._x = KadoKadeoManager.S(bodyX);
		body._y = KadoKadeoManager.S(bodyY);
	}

	function setDirection(di:Int) {
		direction = di;
		animFrame = 1;
		refreshBody();
	}

	// TOOLS
	public function getHeroDist():Int {
		var dx = Math.abs(sq.x - Game.me.hero.sq.x);
		var dy = Math.abs(sq.y - Game.me.hero.sq.y);
		return Std.int(dx + dy);
	}

	public function getNearBads(ray:Int):Array<Bad> {
		var list:Array<Bad> = [];
		for (dx in 0...ray * 2 + 1) {
			for (dy in 0...ray * 2 + 1) {
				var b = floor.getBad(x + dx - ray, y + dy - ray);
				if (b != null)
					list.push(b);
			}
		}
		return list;
	}

	public function getNearestBad(min:Int, max:Int):Ent {
		var trg:Ent = null;
		var dmax = 99;
		for (d in Cs.DIR) {
			for (i in 1...max) {
				var sq = floor.getSquare(x + i * d[0], y + i * d[1]);
				var e = sq != null ? sq.ent : null;
				var bad = e != null && e.flBad;
				if (sq == null || !sq.isGround() || (i < min && bad))
					break;
				if ((i < dmax || (bad && (trg == null || !trg.flBad))) && e != null && !e.flGood) {
					trg = e;
					dmax = i;
					break;
				}
				if (i == dmax)
					break;
			}
		}
		return trg;
	}

	public function getNearFreeList():Array<Square> {
		var list = [];
		var ray = 1;
		for (dx in 0...ray * 2 + 1) {
			for (dy in 0...ray * 2 + 1) {
				var sq = floor.getSquare(x + dx - ray, y + dy - ray);
				if (sq != null && sq.ent == null && sq.isGround())
					list.push(sq);
			}
		}
		return list;
	}

	// TEXT
	public function getName() {
		return "no name";
	}

	// KILL
	public function kill() {
		Game.me.active.remove(this);
		if (root != null)
			root.removeMovieClip();
		floor.ents.remove(this);
		sq.ent = null;
	}
}

// "mcLoss": damage / "miss" text over an actor
class LossPart extends mt.bumdum.Sprite {
	var holder:ASprite;
	var frame:Int;
	var compt:Int;

	public function new(mc:ASprite, px:Float, py:Float, str:String, col:Int) {
		super(mc);
		holder = root.createEmptyMovieClip("smc", 1);
		var t = Txt.make(KadoKadeoManager.S(Data.TEXT_LOSS[3]), Txt.TAHOMA, "center", col, 4);
		t.y = KadoKadeoManager.S(Data.TEXT_LOSS[1]);
		t.text = str;
		holder.addChild(t);
		x = px;
		y = py;
		frame = 1;
		compt = 0;
		showFrame();
		updatePos();
		root.updateState();
	}

	override function update() {
		frame++;
		// frame 9: compt = 5 / frame 11: if (compt-- > 0) gotoAndPlay(_currentframe - 1) / frame 14: removeMovieClip()
		if (frame == 9)
			compt = 5;
		if (frame == 11 && compt-- > 0)
			frame = 10;
		if (frame >= 14) {
			kill();
			return;
		}
		showFrame();
		super.update();
	}

	function showFrame() {
		var r = Data.LOSS[frame - 1];
		holder._x = KadoKadeoManager.S(r[0]);
		holder._y = KadoKadeoManager.S(r[1]);
		holder._xscale = r[2] * 100;
		holder._yscale = r[3] * 100;
	}
}
