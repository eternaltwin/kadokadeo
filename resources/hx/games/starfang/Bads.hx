package starfang;

import kado.KadoKadeoManager;
import mt.bumdum.Lib;

@:publicFields
class Bads extends Phys {
	var flDeath:Bool;
	var hp:Float;
	var score:Int;
	var mid:Int;

	var dif:Float;
	var spawnDist:Float;
	var flash:Float;

	function new(mc) {
		Cs.game.badsList.push(this);
		super(mc);
		score = Cs.C5;
		dif = 1;
		mid = 0;
	}

	function initStartPosition() {
		var ntry = 0;
		/*
			while(true){
				var flBreak = true;
				x = Math.random()*Cs.mcw;
				y = Math.random()*Cs.mch;

				if( getDist(Cs.game.hero) < Cs.START_SAFE_DIST+ray+Cs.game.hero.ray ){
					flBreak = false;
				}

				if(try<30){
					for (i in 0...Cs.game.badsList.length) {
						var b = Cs.game.badsList[i];
						if(b!=this && getDist(b)<ray+b.ray ){
							flBreak = false;
						}
					}
				}

				if(try++>50){
					kill();

				}

				if(flBreak)break;
			}
		 */
		var rnd = Seed.random(4);
		var rx = Seed.rand() * (Cs.mcw + 2 * ray);
		var ry = Seed.rand() * (Cs.mch + 2 * ray);

		switch (rnd) {
			case 0:
				x = rx;
				y = -ray;

			case 1:
				x = rx;
				y = Cs.mch + ray;

			case 2:
				x = -ray;
				y = ry;

			case 3:
				x = Cs.mcw + ray;
				y = ry;
		}
		root.updateState();
	}

	override function update() {
		super.update();
		checkCols();
		updateFlash();
	}

	function updateFlash() {
		if (flash != null) {
			var prc = Math.min(flash, 100);
			flash *= 0.6;
			if (flash < 2) {
				flash = null;
				prc = 0;
			}
			Col.setPercentColor(root, prc, 0xFFFFFF);
		}
	}

	function checkCols() {
		if (Cs.game.hero == null) {
			return;
		}
		if (getDist({x: Cs.game.hero.x, y: Cs.game.hero.y}) < ray + Cs.game.hero.ray) {
			heroCollide();
		}
	}

	function heroCollide() {
		var h = Cs.game.hero;
		if (!h.flInvincible) {
			h.explode();
		} else {
			if (h.flBounce) {
				var a = getAng({x: h.x, y: h.y});
				var sp = Math.sqrt(h.vx * h.vx + h.vy * h.vy) + Math.sqrt(vx * vx + vy * vy) + ray * 0.1;
				h.vx = Math.cos(a) * sp;
				h.vy = Math.sin(a) * sp;
			}
		}
		score = Cs.C0;
		damage(10);
	}

	function hit(shot:Shot) {
		damage(shot.damage);
	}

	function damage(n:Float) {
		flash = 100;
		hp -= n;
		if (hp <= 0) {
			if (!flDeath)
				explode();
		}
	}

	function explode() {
		/*
			// ONDE
			{
				var p = Cs.game.dm.attach("partOnde",Game.DP_UNDERPARTS);
				p._x = x;
				p._y = y;
				var sc = ray*2 + 30;
				p._xscale = sc;
				p._yscale = sc;
			}

			// PAILLETES
			{
				var p = new Part(Cs.game.dm.attach("partExplosion",Game.DP_UNDERPARTS))//Cs.game.newPart("partExplosion");
				p.x = x;
				p.y = y;
				p.updatePos();
				p.root._rotation = Math.random()*360;
				var sc = 20+ray*6;
				p.root._xscale = sc;
				p.root._yscale = sc;
			}
			// DEBRIS

		 */

		// SCORE
		KadoKadeoManager.kkm.addScore(score);
		//
		Cs.game.stats.k[mid]++;
		kill();
	}

	override function kill() {
		flDeath = true;
		Cs.game.badsList.remove(this);
		super.kill();
	}
}
