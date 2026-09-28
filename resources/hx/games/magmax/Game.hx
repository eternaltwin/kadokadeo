package magmax;

import common_haxe_avm1.display.BBox;
import pixi.core.text.Text;
import pixi.filters.colormatrix.ColorMatrixFilter;
import kado.KadoKadeoManager;
import mt.DepthManager;
import mt.Timer;
import magmax.monsters.*;

class PartsSprite extends ASprite {
	public var vx:Float;
	public var vy:Float;
	public var partx:Float;
	public var party:Float;
	public var by:Float;
}

class BonusSprite extends ASprite {
	public var t:Int;
	public var time:Float;
	public var col:BBox;
}

class ComboMcSprite extends ASprite {
	public var c:Text;
}

@:expose('GameMagmax')
class Game implements kado.GameInterface {
	public var dmanager:DepthManager;
	public var bonus:Array<BonusSprite>;
	public var tirs:Array<Tir>;
	public var monsters:Array<Monster>;
	public var hero:Hero;
	public var game_over:Bool;
	public var level:Int;

	var parts:Array<PartsSprite>;
	var bg:ASprite;
	var last_dead:Float;
	var time:Float;
	var combo:Int;
	var combo_mc:ComboMcSprite;
	var death:ASprite;

	public var stats:{
		g:Array<Int>,
		k:Array<Int>,
		b:Array<Int>,
		c:Array<Int>
	};

	public function new(root:ASprite, ?isReplay:Bool = false) {
		level = 1;
		time = 0;
		combo = 0;
		last_dead = -1000;
		dmanager = new DepthManager(root);
		bg = dmanager.attach("bg", Cs.PLAN_BG);
		hero = new Hero(this);
		tirs = new Array();
		parts = new Array();
		bonus = new Array();
		monsters = new Array();
		stats = {
			g: [0, 0, 0],
			k: [0, 0, 0],
			c: [0, 0, 0, 0],
			b: [0, 0, 0, 0, 0, 0]
		};
		genMonster();
	}

	function genMonster() {
		var t = 0;

		if (level >= 10)
			t = Cs.randomProbas([3, 1]);
		if (level >= 20)
			t = Cs.randomProbas([1, 4]);
		if (level >= 30)
			t = Cs.randomProbas([3, 2, 1]);

		stats.g[t]++;
		var m:Monster = null;
		switch (t) {
			case 0:
				m = new Firebomb(this);
			case 1:
				m = new Heliflower(this);
			case 2:
				m = new Cyblock(this);
		}
		monsters.push(m);
		level++;
	}

	public function gameOver() {
		if (!game_over) {
			game_over = true;
			death = dmanager.attach("death", Cs.PLAN_PART);
			death.play();
			death.removeOnFrame = death._totalframes;
			death._x = hero.x;
			death._y = hero.y;
			hero.mc._visible = false;
		}
	}

	public function addPart(p) {
		parts.push(p);
	}

	public function doCombo() {
		var txts = ["DOUBLE BLAST !", "MULTI BLAST !", "ULTRA BLAST !", "MAGMAX !!!"];
		if (time - last_dead < 2.5) {
			if (combo < Cs.COMBOS.length) {
				if (combo_mc != null)
					combo_mc.removeMovieClip();
				combo_mc = cast dmanager.empty(2);
				combo_mc.c = combo_mc.initTextField('c', {
					font: 'Impact',
					size: 30,
					color: 0xFFFFFF,
					stroke: "#000000",
					strokeThickness: KadoKadeoManager.I(2)
				});
				combo_mc._y = KadoKadeoManager.I(300);
				combo_mc.c.text = txts[combo];
				combo_mc._totalframes = 22;
				combo_mc.removeOnFrame = combo_mc._totalframes;
				combo_mc.play();

				var colorFilter = new ColorMatrixFilter();
				colorFilter.matrix = [
					133 / 256,         0,         0, 0, 122 / 255,
					        0, 133 / 256,         0, 0,         0,
					        0,         0, 133 / 256, 0,         0,
					        0,         0,         0, 1,         0
				];
				combo_mc.filters = [colorFilter];
				var compt = 30;

				combo_mc.onFrame.set(1, function() {});
				combo_mc.onFrame.set(2, function() {
					combo_mc._y -= KadoKadeoManager.I(6);
					colorFilter.matrix = [
						92 / 256,        0,        0, 0, 163 / 255,
						       0, 92 / 256,        0, 0,  78 / 255,
						       0,        0, 92 / 256, 0,  78 / 255,
						       0,        0,        0, 1,         0
					];
				});
				combo_mc.onFrame.set(3, function() {
					combo_mc._y -= KadoKadeoManager.I(6);
					colorFilter.matrix = [
						59 / 256,        0,        0, 0, 196 / 255,
						       0, 59 / 256,        0, 0, 142 / 255,
						       0,        0, 59 / 256, 0, 142 / 255,
						       0,        0,        0, 1,         0
					];
				});
				combo_mc.onFrame.set(4, function() {
					combo_mc._y -= KadoKadeoManager.I(6);
					colorFilter.matrix = [
						33 / 256,        0,        0, 0, 222 / 255,
						       0, 33 / 256,        0, 0, 191 / 255,
						       0,        0, 33 / 256, 0, 191 / 255,
						       0,        0,        0, 1,         0
					];
				});
				combo_mc.onFrame.set(5, function() {
					combo_mc._y -= KadoKadeoManager.I(3);
					colorFilter.matrix = [
						15 / 256,        0,        0, 0, 240 / 255,
						       0, 15 / 256,        0, 0, 227 / 255,
						       0,        0, 15 / 256, 0, 227 / 255,
						       0,        0,        0, 1,         0
					];
				});
				combo_mc.onFrame.set(6, function() {
					combo_mc._y -= KadoKadeoManager.I(2);
					colorFilter.matrix = [
						4 / 256,       0,       0, 0, 251 / 255,
						      0, 4 / 256,       0, 0, 248 / 255,
						      0,       0, 4 / 256, 0, 248 / 255,
						      0,       0,       0, 1,         0
					];
				});
				combo_mc.onFrame.set(7, function() {
					combo_mc._y -= KadoKadeoManager.I(1);
					colorFilter.matrix = [
						0, 0, 0, 0, 255,
						0, 0, 0, 0, 255,
						0, 0, 0, 0, 255,
						0, 0, 0, 1,   0
					];
				});
				combo_mc.onFrame.set(8, function() {
					combo_mc._y -= KadoKadeoManager.I(1);
					colorFilter.matrix = [
						85 / 256,        0,        0, 0, 170 / 255,
						       0, 85 / 256,        0, 0, 170 / 255,
						       0,        0, 85 / 256, 0, 170 / 255,
						       0,        0,        0, 1,         0
					];
				});
				combo_mc.onFrame.set(9, function() {
					combo_mc._y -= KadoKadeoManager.I(1);
					colorFilter.matrix = [
						171 / 256,         0,         0, 0, 85 / 255,
						        0, 171 / 256,         0, 0, 85 / 255,
						        0,         0, 171 / 256, 0, 85 / 255,
						        0,         0,         0, 1,        0
					];
				});
				combo_mc.onFrame.set(10, function() {
					combo_mc._y -= KadoKadeoManager.I(1);
					combo_mc.filters = [];
				});
				combo_mc.onFrame.set(11, function() {
					combo_mc._y += KadoKadeoManager.I(1);
					if (compt-- > 0) {
						combo_mc.gotoAndPlay(10);
					}
				});
				combo_mc.onFrame.set(12, function() {
					combo_mc._y += KadoKadeoManager.I(2);
				});
				combo_mc.onFrame.set(13, function() {
					combo_mc._y += KadoKadeoManager.I(2);
				});
				combo_mc.onFrame.set(14, function() {
					combo_mc._y += KadoKadeoManager.I(2);
				});
				combo_mc.onFrame.set(15, function() {
					combo_mc._y += KadoKadeoManager.I(2);
				});
				combo_mc.onFrame.set(16, function() {
					combo_mc._y += KadoKadeoManager.I(2);
				});
				combo_mc.onFrame.set(17, function() {
					combo_mc._y += KadoKadeoManager.I(2);
				});
				combo_mc.onFrame.set(18, function() {
					combo_mc._y += KadoKadeoManager.I(2);
				});
				combo_mc.onFrame.set(19, function() {
					combo_mc._y += KadoKadeoManager.I(2);
				});
				combo_mc.onFrame.set(20, function() {
					combo_mc._y += KadoKadeoManager.I(2);
				});
				combo_mc.onFrame.set(21, function() {
					combo_mc._y += KadoKadeoManager.I(3);
				});
				KadoKadeoManager.kkm.addScore(Cs.COMBOS[combo]);
				stats.c[combo]++;
				combo++;
			}
		} else
			combo = 0;
		last_dead = time;
	}

	public function update(delta:Float) {
		time += Timer.deltaT;

		if (game_over && death != null && death._name == null) {
			death = null;
			KadoKadeoManager.kkm.gameOver(stats);
		}

		if (monsters.length < 6 && Seed.random(Std.int(1500 * monsters.length / (Timer.tmod * level))) == 0)
			genMonster();
		if (!game_over && !hero.update())
			gameOver();
		var i = 0;
		while (i < monsters.length) {
			if (!monsters[i].update())
				monsters.splice(i, 1);
			else
				i++;
		}
		i = 0;
		while (i < tirs.length) {
			if (!tirs[i].update())
				tirs.splice(i, 1);
			else
				i++;
		}
		i = 0;
		while (i < parts.length) {
			var p = parts[i];
			p.partx += p.vx * Timer.tmod;
			p.party += p.vy * Timer.tmod;
			if (p.party > 0) {
				p.party *= -1;
				p.vy *= -0.5;
			}
			p._rotation += (p.vx / KadoKadeoManager.S(1)) * 5 * Timer.tmod;
			p._alpha -= 5;
			if (p._alpha <= 0) {
				p.removeMovieClip();
				parts.splice(i, 1);
			} else {
				i++;
			}
			p.vy += KadoKadeoManager.S(1) * Timer.tmod;
			p._x = p.partx;
			p._y = p.by + p.party;
		}
		dmanager.compact(Cs.PLAN_HERO);
		dmanager.ysort(Cs.PLAN_HERO);
	}

	public function destroy() {}
}
