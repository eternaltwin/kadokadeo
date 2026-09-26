package kanjisadventure.ent;

import kanjisadventure.*;
import kanjisadventure.Protocol;

class HeroSprite extends ASprite {
	public var heroRight:ASprite;
	public var heroLeft:ASprite;
	public var heroBack:ASprite;
	public var heroFront:ASprite;
	public var heroDie:ASprite;
}

class Hero extends Ent {
	public static var FRAMES_PER_DIRECTION = 10;

	public var skin:ASprite;
	public var futurAction:Action;

	public var flFire:Bool;
	public var luck:Int;

	public function new() {
		super();
		flGood = true;
		flBad = false;
		Game.me.hero = this;
		lifeMax = 12;
		buildCaracs();
		init();
		// strikeId = 1;
	}

	override function init() {
		super.init();
		Game.me.displayLife();
	}

	// CARACS
	public function buildCaracs() {
		flDoubleDamage = false;
		damageMin = 1;
		damageMax = 2;

		armor = 0;
		luck = 0;

		agility = 3;
		dodge = 4;

		// WEAPON
		switch (Game.me.weaponId.get()) {
			case 1: // COUTEAU
				damageMax = 3;
			case 2: // KATANA
				damageMax = 5;
		}

		strikeId = Game.me.weaponId.get();

		// ARMOR
		switch (Game.me.armorId.get()) {
			case 1: // LEATHER
				armor = 1;
				dodge -= 1;
			case 2: // METAL
				armor = 2;
				agility -= 1;
				dodge -= 2;
		}

		for (id in Game.me.inventory) {
			switch (id) {
				case 18: // AMULETTE ROUGE
					damageMin += 1;
					damageMax += 1;

				case 19: // AMULETTE VERTE
					dodge += 1;

				case 20: // AMULETTE BLEUE
					agility += 2;

				case 24: // PORTE BONHEUR
					luck += 5;

				case 33: // DEGATS !!
					flDoubleDamage = true;

				case 34: // ZIPPO !!
					flFire = true;
				default:
			}
		}

		if (life.get() > lifeMax.get())
			life = lifeMax.get();
		Game.me.displayLife();
		Game.me.displayShuriken();

		//
	}

	override function display() {
		super.display();
		skin.stop();
		paint();
	}

	private function hideAll() {
		var r:HeroSprite = cast root;
		r.heroBack._visible = false;
		r.heroFront._visible = false;
		r.heroDie._visible = false;
		r.heroLeft._visible = false;
		r.heroRight._visible = false;
	}

	//
	override function attach():ASprite {
		// trace("attach!");
		var r:HeroSprite;
		r = cast sq.dm.empty(Square.DP_ACTOR);
		r._totalframes = 5;
		r.onFrame.set(1, function() {
			hideAll();
			r.heroRight._visible = true;
			skin = r.heroRight;
		});
		r.onFrame.set(2, function() {
			hideAll();
			r.heroFront._visible = true;
			skin = r.heroFront;
		});
		r.onFrame.set(3, function() {
			hideAll();
			r.heroLeft._visible = true;
			skin = r.heroLeft;
		});
		r.onFrame.set(4, function() {
			hideAll();
			r.heroBack._visible = true;
			skin = r.heroBack;
		});
		r.onFrame.set(5, function() {
			hideAll();
			r.heroDie._visible = true;
		});
		root = r;
		r._xscale = r._yscale = 80;
		var shade = r.attachMovie("heroShade");
		shade._x = KadoKadeoManager.S(12);
		shade._y = KadoKadeoManager.S(-.5 + 16);
		r.heroRight = r.attachMovie("heroRight", Square.DP_ACTOR);
		r.heroLeft = r.attachMovie("heroRight", Square.DP_ACTOR);
		r.heroLeft._x = KadoKadeoManager.S(24);
		r.heroLeft._xscale = -100;
		r.heroBack = r.attachMovie("heroBack", Square.DP_ACTOR);
		r.heroFront = r.attachMovie("heroFront", Square.DP_ACTOR);
		r.heroDie = r.attachMovie("heroDie", Square.DP_ACTOR);

		hideAll();
		r.heroRight._visible = true;
		skin = r.heroRight;
		return root;
	}

	override function move(di, coef:Float) {
		if (di == null)
			return;
		var c = coef;
		if (di == 1)
			c = coef - 1;
		var d = Cs.DIR[di];
		root._x = c * d[0] * Cs.CS;
		root._y = c * d[1] * Cs.CS;

		var fr = anim._currentframe;
		if (fr % FRAMES_PER_DIRECTION == 0)
			fr -= FRAMES_PER_DIRECTION - 1;
		else
			fr++;
		anim.gotoAndStop(fr);

		if (coef == 1) {
			display();
			x = sq.x;
			y = sq.y;
			setAction(null);
		}
	}

	public function paint() {
		if (skin != null) {
			var equipmentId = Game.me.armorId.get() * 3 + Game.me.weaponId.get();
			skin.gotoAndStop(equipmentId * FRAMES_PER_DIRECTION + 1);
		}
	}

	override function setDirection(di) {
		// trace("setDir!");
		super.setDirection(di);
		anim = skin;
		paint();
	}

	override function checkMove() {
		if (futurAction == null)
			return;
		switch (futurAction) {
			case Goto(di):
				setAction(futurAction);
			default:
		}
	}

	override function checkAttack() {
		if (futurAction == null)
			return;
		switch (futurAction) {
			case Attack(di):
				setAction(futurAction);
			default:
		}
	}

	public function incLife(n) {
		var d = lifeMax.get() - life.get();
		if (n > d)
			n = d;
		life += n;
		Game.me.displayLife();
		Game.me.log("Vous guérissez " + n + " blessure(s).");
	}

	public function setFuturAction(ac) {
		futurAction = ac;
	}

	override function hurt(n) {
		super.hurt(n);
		Game.me.displayLife();
	}

	override function kill() {
		sq.fxLight();
		root.gotoAndStop(5);
		root = null;
		super.kill();
	}
	/*
		public function die(){
			super.die();
			Game.me.initGameOver();
		}
	 */
}
