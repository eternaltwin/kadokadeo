package kanjisadventure.ent;

import kanjisadventure.*;
import kanjisadventure.Protocol;
import common_haxe_avm1.KKApi;
import kado.KadoKadeoManager;
import mt.bumdum.Lib;

class Bad extends Ent {
	public var flEatable:Bool;
	public var flUndead:Bool;
	public var flChaos:Bool;

	var skin:ASprite;

	var bid:Int;
	var lastDir:Int;

	public var swapDir:Int;

	var seek:Int;

	public var bhAtt:AttackBehaviour;
	public var bhMove:MoveBehaviour;

	public function new(bid) {
		super();
		seek = 0;
		flBad = true;
		flChaos = false;
		setType(bid);
		init();
		strikeId = 0;
	}

	override function setFloor(fl) {
		if (floor != null)
			floor.bads.remove(this);
		super.setFloor(fl);
		floor.bads.push(this);
	}

	override function checkAttack() {
		if (flFreeze)
			return;
		if (action != null)
			return;
		if (swapDir != null)
			return;

		var trgList = getTrgList(sq);
		if (trgList.length > 0) {
			var rdi = trgList[Seed.random(trgList.length)];
			switch (bhAtt) {
				case BStick:
					setAction(Attack(rdi));
				case BRandom(c):
					if (Seed.rand() < c)
						setAction(Attack(rdi));
			}
		}
	}

	override function checkMove() {
		if (flFreeze)
			return;
		if (action != null)
			return;
		if (swapDir != null) {
			setAction(Goto(swapDir));
			swapDir = null;
			return;
		}
		/*
			if( futurAction!=null ){
				switch(futurAction){
					case Goto(di): setAction(futurAction);
					default:
				}
				return;
			}
		 */

		var moveList = [];
		var di = 0;
		for (d in Cs.DIR) {
			var next = floor.grid[sq.x + d[0]][sq.y + d[1]];
			if (next.isFree())
				moveList.push(di);
			di++;
		}

		if (moveList.length > 0) {
			var bh = bhMove;
			var flFollow:Bool;
			switch (bh) {
				case BFollow(c):
					flFollow = true;
				case _:
					flFollow = false;
			}

			var hdi = Std.int(getHeroDist());
			var rdi = 0;
			if (hdi <= seek && !Type.enumEq(bh, BCoward) && !flFollow && !flChaos)
				bh = BHunt;

			switch (bh) {
				default:
			}
			if (!flFollow)
				rdi = moveList[Seed.random(moveList.length)];

			switch (bh) {
				case BFollow(c):
					if (Seed.rand() < c) {
						var direction = sq.getNextDirectionTo(Game.me.hero.sq);
						if (direction != null && moveList.contains(direction)) {
							setAction(Goto(direction));
							lastDir = direction;
							return;
						}
					}
					var direction = moveList[Seed.random(moveList.length)];
					setAction(Goto(direction));
					lastDir = direction;
				case BNormal(c):
					var fdi = rdi;
					if (Seed.rand() < c) {
						for (di in moveList)
							if (di == lastDir)
								fdi = di;
					}
					setAction(Goto(fdi));
					lastDir = fdi;
				case BErratic(c):
					if (Seed.rand() < c)
						setAction(Goto(rdi));

				case BHunt:
					if (flBad && hdi <= 2) {
						if (Game.me.hero.futurAction != null
							&& Type.enumConstructor(Game.me.hero.futurAction) == Type.enumConstructor(Goto(2))
							&& Seed.random(hdi) == 0)
							return;
					}

					if (flGood) {
						// if( hdi==1 )return;
						// if( hdi==2 && Std.random(3)==0 )return;
						if (Seed.random(Std.int(Math.pow(hdi, 2))) == 0)
							return;
					}
					var fdi = rdi;

					var d = Cs.DIR[fdi];
					var sq2 = floor.grid[sq.x + d[0]][sq.y + d[1]];
					var rh = sq2.heat;
					for (di in moveList) {
						var d = Cs.DIR[di];
						var sq2 = floor.grid[sq.x + d[0]][sq.y + d[1]];
						if (sq2.heat < rh || rh == null) {
							rh = sq2.heat;
							fdi = di;
						}
					};
					setAction(Goto(fdi));

				case BCoward:
					var fdi = rdi;
					var d = Cs.DIR[fdi];
					var sq2 = floor.grid[sq.x + d[0]][sq.y + d[1]];
					var rh = sq2.heat;
					for (di in moveList) {
						var d = Cs.DIR[di];
						var sq2 = floor.grid[sq.x + d[0]][sq.y + d[1]];
						if (sq2.heat > rh || sq2.heat == null) {
							rh = sq2.heat;
							fdi = di;
						}
					};
					setAction(Goto(fdi));
			}
		}

		/*
			if( moveList.length>0 && Std.random(3)>0 ){
				setAction( Goto(moveList[Std.random(moveList.length)]) );

			}
		 */
	}

	// --- TYPE ---
	public function setType(id) {
		bid = id;
		switch (bid) {
			case 0: // CACA

				bhMove = BNormal(0.1);
				bhAtt = BRandom(0.5);

				agility = 1;
				dodge = 3;

				lifeMax = 2;
				damageMax = 2;
				seek = 2;

			case 1: // ORK
				flEatable = true;
				bhMove = BNormal(0.6);
				bhAtt = BStick;

				agility = 2;
				dodge = 2;

				lifeMax = 4;
				damageMax = 3;

				seek = 3;

			case 2: // INSECT
				bhMove = BNormal(0.1);
				bhAtt = BStick;

				agility = 3;
				dodge = 4;

				damageMax = 2;
				lifeMax = 2;
				seek = 10;

			case 3: // SKELETTONS
				flUndead = true;
				bhMove = BNormal(0.5);
				bhAtt = BStick;

				agility = 3;
				dodge = 3;

				lifeMax = 3;
				damageMax = 5;

				seek = 3;

			case 4: // HYDRA
				flEatable = true;
				bhMove = BNormal(0.2);
				bhAtt = BStick;

				agility = 4;
				dodge = 2;

				damageMin = 2;
				damageMax = 4;
				lifeMax = 8;
				seek = 3;

			case 5: // ZOMBI
				flUndead = true;
				bhMove = BNormal(0.3);
				bhAtt = BStick;

				agility = 2;
				dodge = 1;

				damageMax = 5;
				lifeMax = 12;
				seek = 10;

			case 6: // WARRIOR
				flEatable = true;

				bhMove = BNormal(0.8);
				bhAtt = BStick;

				agility = 4;
				dodge = 4;

				damageMin = 2;
				damageMax = 6;

				lifeMax = 6;
				seek = 4;

			case 7: // SORCERER
				flUndead = true;
				bhMove = BNormal(0.2);
				bhAtt = BStick;

				agility = 3;
				dodge = 7;

				damageMin = 1;
				damageMax = 10;

				lifeMax = 5;
				seek = 5;

			case 20: // OURS
				flEatable = true;
				flGood = true;
				flBad = false;
				bhMove = BFollow(0.4);
				bhAtt = BStick;

				agility = 3;
				dodge = 3;

				damageMin = 2;
				damageMax = 5;

				lifeMax = 10;
				seek = 10;

			case 21: // DOG
				flEatable = true;
				flGood = true;
				flBad = false;
				bhMove = BFollow(0.9);
				bhAtt = BStick;

				agility = 4;
				dodge = 6;
				damageMin = 1;
				damageMax = 3;

				lifeMax = 3;
				seek = 10;

			default:
		}
	}

	//
	override function attach():ASprite {
		root = sq.dm.empty(Square.DP_ACTOR);
		var rootroot = root.createEmptyMovieClip();
		var shade = rootroot.attachMovie("mcBadShade");
		shade._x = KadoKadeoManager.S(0.5);
		shade._y = KadoKadeoManager.I(14);
		skin = rootroot.attachMovie("mcBad" + (bid + 1));
		if (flChaos) {
			Filt.glow(root, KadoKadeoManager.I(4), 2, 0xFFFFFF);
			Filt.glow(root, KadoKadeoManager.I(2), 4, 0xAA00FF);
		}

		var dieMask = root.createEmptyMovieClip();
		dieMask._visible = false;
		dieMask.getGraphics()
			.beginFill(0xFFFFFF, 0.5)
			.drawCircle(0, 0, KadoKadeoManager.I(12))
			.drawRect(KadoKadeoManager.I(-11), KadoKadeoManager.I(-40), KadoKadeoManager.I(24), KadoKadeoManager.I(40))
			.endFill();
		root._totalframes = 10;
		root.removeOnFrame = 10;
		root.onFrame.set(2, function() {
			dieMask._visible = true;
			root.mask = dieMask;
			root._y += KadoKadeoManager.I(11);
		});
		root.onFrame.set(3, () -> root._y += KadoKadeoManager.I(32));
		root.onFrame.set(4, () -> root._y += KadoKadeoManager.I(53));
		root.onFrame.set(5, () -> root._y += KadoKadeoManager.I(74));
		root.onFrame.set(6, () -> root._y += KadoKadeoManager.I(96));
		root.onFrame.set(7, () -> root._y += KadoKadeoManager.I(117));
		root.onFrame.set(8, () -> root._y += KadoKadeoManager.I(138));
		root.onFrame.set(9, () -> root._y += KadoKadeoManager.I(159));

		return root;
	}

	override function setDirection(di) {
		direction = di;
		if (skin != null)
			skin.gotoAndStop(direction + 1);
	}

	//
	override function die() {
		if (flBad) {
			// DROP
			if (sq.itemId == null) {
				var gid = getDrop();
				if (gid != null) {
					sq.addItem(gid);
					sq.showItem();
				}
			}
			// SCORE
			var sc = KKApi.cmult(KKApi.const(bid + 1), Cs.SCORE_MONSTER);
			KadoKadeoManager.kkm.addScore(sc);
			sq.fxScore(KKApi.val(sc) + "");
		}
		root._visible = false;
		var c = attach();
		c.gotoAndPlay(2);

		super.die();
	}

	public function getDrop() {
		switch (bid) {
			case 0:
				if (Seed.random(2) == 0)
					return null; // CACA -> RIEN
			case 3:
				if (Seed.random(10) == 0)
					return 32; // SQUELETTE -> OS
			case 4:
				if (Seed.random(10) == 0)
					return 29; // HYDRA -> TELEPORT
			// case 5:  if( Std.random(10)==0 ) return 0;	// ZOMBI -> OEIL
			case 6:
				if (Seed.random(100) == 0)
					return 8; // WARRIOR -> KATANA
		}

		// FOOD
		if (flEatable && Seed.random(12) == 0) {
			return 10;
		}

		// GOLD
		var gid = 1;
		var rnd = 10 - (Game.me.hero.luck + bid);
		if (rnd < 1)
			rnd = 1;
		if (Seed.random(rnd) == 0)
			gid++;
		if (Seed.random(10 + rnd) == 0)
			gid++;
		return gid;
	}

	// TEXT
	override function getName() {
		return Lang.getBadName(bid);
	}

	//
	public function setChaos() {
		flChaos = true;
		bhMove = BErratic(0.7);
		sq.fxChaos();
		display();
	}

	//
	override function kill() {
		super.kill();
		floor.bads.remove(this);
	}

	//
	public function getTrgList(sq) {
		var a = [];
		var di = 0;
		for (d in Cs.DIR) {
			var next = floor.grid[sq.x + d[0]][sq.y + d[1]];
			if (next.ent != null) {
				if (flBad && ((next.ent.flGood || flChaos)))
					a.push(di);
				if (flGood && next.ent.flBad)
					a.push(di);
			}
			di++;
		}
		return a;
	}
}
/*





	enum AttackBehaviour {
	ABRandom(c:Float);
	ABStick;
	ABCoward;
	}
	enum MoveBehaviour {
	ABFollow;
	ABRandom(c:Float);
	}





 */
