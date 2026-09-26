package kanjisadventure;

import common_haxe_avm1.kac.ProtectedInt;
import kanjisadventure.Protocol;
import mt.bumdum.Lib;

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

	public var damageMin:ProtectedInt;
	public var damageMax:ProtectedInt;
	public var armor:ProtectedInt;
	public var lifeMax:ProtectedInt;
	public var life:ProtectedInt;

	public var agility:ProtectedInt;
	public var dodge:ProtectedInt;
	public var damage:ProtectedInt;
	public var coef:Float;

	public var strikeId:Int;

	public var floor:Floor;
	public var sq:Square;

	public var action:Action;

	public var root:ASprite;
	public var anim:ASprite;

	public function new() {
		damage = new ProtectedInt(0);
		damageMin = new ProtectedInt(1);
		damageMax = new ProtectedInt(1);
		armor = new ProtectedInt(0);
		agility = new ProtectedInt(3);
		dodge = new ProtectedInt(4);
		lifeMax = new ProtectedInt(3);
		life = new ProtectedInt(lifeMax.get());
	}

	public function init() {
		life = new ProtectedInt(lifeMax.get());
		setDirection(1);
	}

	public function setFloor(fl) {
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
	public function setAction(ac) {
		action = ac;
		if (ac != null) {
			Game.me.work.push(this);
			Game.me.active.remove(this);
			switch (action) {
				case Goto(dir):
					initMove(dir);
				case Attack(dir):
					initAttack(dir);
			}
		} else {
			Game.me.work.remove(this);
		}
	}

	public function update(coef) {
		if (flDeath) {
			setAction(null);
			return;
		}
		switch (action) {
			case Goto(dir):
				move(dir, coef);
			case Attack(dir):
				attack(dir, coef);
		}
	}

	// MOVE
	function initMove(di) {
		if (di == null)
			return;
		var d = Cs.DIR[di];
		var next = floor.grid[sq.x + d[0]][sq.y + d[1]];
		setSquare(next);
		if (di == 1) {
			display();
			root._y -= Cs.CS;
		}

		if (getHeroDist() <= Game.me.huntMax)
			floor.buildTracks();

		setDirection(di);
	}

	function move(di, coef:Float) {
		if (di == null)
			return;
		var c = coef;
		if (di == 1)
			c = coef - 1;
		var d = Cs.DIR[di];
		root._x = c * d[0] * Cs.CS;
		root._y = c * d[1] * Cs.CS;

		if (anim != null) {
			var fr = anim._currentframe;
			if (fr == anim._totalframes)
				fr = 1;
			else
				fr++;
			anim.gotoAndStop(fr);
		}

		if (coef == 1) {
			display();
			x = sq.x;
			y = sq.y;
			setAction(null);
		}
	}

	// ATTACK
	function initAttack(di) {
		setDirection(di);
	}

	function attack(di:Int, coef:Float) {
		var d = Cs.DIR[di];
		var trg = floor.grid[sq.x + d[0]][sq.y + d[1]].ent;

		if (!flDamage && trg != null) {
			flDamage = true;

			// DODGE
			var c = agility.get() / trg.dodge.get();
			damage.set(-1);
			if (Seed.rand() < c) {
				damage = getDamage();
				damage -= trg.armor.get();
				if (damage.get() < 0)
					damage = 0;
			}

			trg.fxDamage(damage.get());
			if (damage.get() >= 0) {
				trg.fxStrike(strikeId, di);
				trg.hurt(damage.get());
			}

			if (Game.me.hero == this) {
				if (damage.get() > 0)
					Game.me.log("Vous infligez " + damage.get() + " dégât(s) à " + trg.getName() + ".");
				else if (damage.get() == 0)
					Game.me.log(trg.getName() + " encaisse votre attaque sans broncher.");
				else
					Game.me.log(trg.getName() + " évite votre coup.");
			}
			if (Game.me.hero == trg) {
				if (damage.get() > 0)
					Game.me.log(getName() + " vous inflige " + damage.get() + " dégât(s).");
				else if (damage.get() == 0)
					Game.me.log(getName() + " ne parvient pas à vous blesser.");
				else
					Game.me.log("Vous esquivez l'attaque de " + getName() + ".");
			}
		}

		var c = Math.max(1 - coef * 1.5, 0);
		var d = Cs.DIR[di];

		var cx = 0;
		var cy = 0;

		var dc = KadoKadeoManager.I(4);
		root._x = cx + c * d[0] * dc;
		root._y = cy + c * d[1] * dc;

		if (damage.get() > 0 && trg != null && trg.root != null) {
			var sens = trg.root._x > cx ? -1 : 1;
			trg.root._x = cx + c * KadoKadeoManager.I(6) * sens;
			Col.setPercentColor(trg.root, (1 - coef) * 100, 0xFF0000);
		} else {
			// var n = Math.sin(coef*3.14);
			// trg.root._x = cx+n*d[0]*16;
			// trg.root._y = cy+n*d[1]*16;
		}

		if (coef == 1) {
			flDamage = false;
			setAction(null);
		}
	}

	//
	public function freeze() {
		flFreeze = true;
		display();
	}

	//
	public function hurt(n) {
		if (n == null)
			return;
		life -= n;
		if (n > 0 && Game.me.hero == this) {
			Game.me.fxFlash(0xFF0000);
		}
		if (life.get() <= 0) {
			life = 0;
			die();
		}
	}

	public function fxDamage(n:Int) {
		var mc = floor.dm.empty(Square.DP_FX);
		var tf = mc.initTextField("tf", {
			font: 'tahoma',
			size: 30,
			color: 0xFFFFFF,
			align: "center",
		});
		var compt = 5;
		mc._totalframes = 14;
		mc.onFrame.set(1, () -> {});
		mc.onFrame.set(2, () -> mc._y -= KadoKadeoManager.I(5));
		mc.onFrame.set(3, () -> mc._y -= KadoKadeoManager.I(6));
		mc.onFrame.set(4, () -> mc._y -= KadoKadeoManager.I(7));
		mc.onFrame.set(5, () -> mc._y -= KadoKadeoManager.I(9));
		mc.onFrame.set(6, () -> mc._y -= KadoKadeoManager.I(10));
		mc.onFrame.set(7, () -> mc._y -= KadoKadeoManager.I(11));
		mc.onFrame.set(8, () -> mc._y += KadoKadeoManager.I(12));
		mc.onFrame.set(9, () -> mc._y += KadoKadeoManager.I(30));
		mc.onFrame.set(10, function() {
			mc._xscale = mc._yscale = 100;
		});
		mc.onFrame.set(11, function() {
			mc._xscale = mc._yscale = 77;
			if (compt-- > 0) {
				mc.gotoAndPlay(10);
			}
		});
		mc.onFrame.set(12, function() {
			mc._y += KadoKadeoManager.I(1);
			mc._xscale = mc._yscale = 55;
		});
		mc.onFrame.set(13, function() {
			mc._y -= KadoKadeoManager.I(1);
			mc._xscale = mc._yscale = 31;
		});
		mc.onFrame.set(14, function() {
			mc._xscale = mc._yscale = 8;
		});
		mc.removeOnFrame = mc._totalframes;
		mc.play();

		mc._x = (x + 0.5) * Cs.CS; //*0.5;
		mc._y = (y + 0.5) * Cs.CS; // + b.y;
		var str = n + "";
		var col = 0xFF0000;
		if (n == -1) {
			col = 0;
			str = "miss";
		}

		Filt.glow(mc, KadoKadeoManager.I(2), 4, col);
		tf.text = str;
	}

	public function fxStrike(id, di) {
		if (id == null)
			return;
		var mc = sq.dm.attach("mcStrike" + (id + 1), Square.DP_FX);
		mc.play();
		switch (id) {
			case 0:
				mc.removeOnFrame = 5;
			case 1 | 2 | 3:
				mc.removeOnFrame = 6;
			case 4:
				mc.removeOnFrame = 4;
		}
		mc._x = Cs.CS * 0.5;
		mc._y = Cs.CS * 0.5;
		// if( di!=0 )mc._xscale*=-1;
		mc._rotation = di * 90;
	}

	public function getDamage() {
		var dmg = damageMin.get() + Seed.random(1 + damageMax.get() - damageMin.get());
		if (flDoubleDamage)
			dmg *= 2;
		return dmg;
	}

	public function die() {
		flDeath = true;
		kill();
	}

	public function setPos(x, y) {
		this.x = x;
		this.y = y;
		setSquare(floor.grid[x][y]);
	}

	public function setSquare(square) {
		if (sq != null && sq.ent == this)
			sq.ent = null;
		sq = square;
		sq.ent = this;
	}

	// DISPLAY / ATTACH
	public function display() {
		if (root != null)
			root.removeMovieClip();
		attach();
		setDirection(direction);
		if (flFreeze) {
			Filt.grey(untyped this.skin, 1, 0, {r: 0, g: 150, b: 210});
		}
	}

	function attach():ASprite {
		root = sq.dm.attach("mcEnt", Square.DP_ACTOR);
		return root;
	}

	function setDirection(di) {
		direction = di;
		if (root != null) {
			root.gotoAndStop(direction + 1);
		}
	}

	// TOOLS
	public function getHeroDist() {
		var dx = Math.abs(sq.x - Game.me.hero.sq.x);
		var dy = Math.abs(sq.y - Game.me.hero.sq.y);
		return dx + dy;
	}

	public function getNearBads(ray) {
		var list:Array<kanjisadventure.ent.Bad> = [];
		for (dx in 0...ray * 2 + 1) {
			for (dy in 0...ray * 2 + 1) {
				var x = x + dx - ray;
				var y = y + dy - ray;
				if (floor.grid[x] == null || floor.grid[x][y] == null)
					continue;
				var ent = floor.grid[x][y].ent;
				if (ent != null && ent.flBad)
					list.push(cast ent);
			}
		}
		return list;
	}

	public function getNearestBad(min, max) {
		var trg:Ent = null;
		var dmax = 99;
		for (d in Cs.DIR) {
			for (i in 1...max) {
				var x = x + i * d[0];
				var y = y + i * d[1];
				var sq = floor.grid[x][y];
				if (!sq.isGround() || (i < min && sq.ent != null && sq.ent.flBad))
					break;
				if (sq.ent != null && sq.ent.flGood != true && (i < dmax || (sq.ent.flBad && trg.flBad != true))) {
					trg = sq.ent;
					dmax = i;
					// trace("="+sq.ent);
					break;
				}
				if (i == dmax)
					break;
			}
		}
		return trg;
	}

	public function getNearFreeList() {
		var list = [];
		var ray = 1;
		for (dx in 0...ray * 2 + 1) {
			for (dy in 0...ray * 2 + 1) {
				var x = x + dx - ray;
				var y = y + dy - ray;
				var sq = floor.grid[x][y];
				if (sq.ent == null && sq.isGround())
					list.push(sq);
				// if( ent.flBad )list.push( cast ent);
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
