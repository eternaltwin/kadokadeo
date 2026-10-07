package phagocytoz.cell;

import phagocytoz.Cell;
import phagocytoz.Element;
import phagocytoz.Game;
import phagocytoz.Gfx;
import phagocytoz.Level;

class Hero extends Cell {
	var arrow:Gfx.McArrow;

	public function new(r:Float) {
		super(r);
		consume = true;
		sprite.env.gotoAndStop(3);
		sprite.noyau.gotoAndStop(3);

		arrow = new Gfx.McArrow();
		arrow.blendMode = "add";
		Game.me.lvl.dm.add(arrow, 3);
	}

	override function update() {
		// CONTROL
		// (the direction of the mouse: the push recorded by Game.readControls, the replay's events)
		var an = Game.me.pushAngle;
		arrow.alpha = 0.2;
		arrow.filters = [];
		if (Game.me.click) {
			arrow.alpha = 1;
			Filt.glow(arrow, 4, 0.5, 0xFFFFFF);
			var acc = 0.125 + (0.2 / Game.me.lvl.scale) * 0.25;
			vx += Num.q(Math.cos(an)) * acc;
			vy += Num.q(Math.sin(an)) * acc;
		}

		// FRICT
		var frict = 0.98;
		vx *= frict;
		vy *= frict;

		// TIMER
		var lim = 2500 - Game.me.dif * 200;
		var c = Game.me.timer / lim;
		if (Game.me.timer > lim) {
			var area = getDiscArea(ray);
			grow(-area * 0.01);
		}

		super.update();

		// ARROW (the mouse live, the push in a replay)
		var aim = Game.me.aimAngle;
		var ma = 3 / Game.me.lvl.scale;
		// (the hero across a border of the level: a jump of a level)
		arrow.moveWrapped(x + Math.cos(aim) * (ray + ma), y + Math.sin(aim) * (ray + ma), Level.WIDTH, Level.HEIGHT);
		arrow.rotation = aim / 0.0174;
		arrow.scaleX = arrow.scaleY = 0.5 / Game.me.lvl.scale;
	}

	override function grow(inc:Float) {
		super.grow(inc);
		if (inc < 0) {
			Game.me.pink.alpha += 0.1;
		}
	}

	override public function kill() {
		super.kill();
		arrow.parent.removeChild(arrow);
		vx = 0;
		vy = 0;
		Game.me.pink.alpha = 1;
	}

	override function eat(c:Cell, dif:Float) {
		super.eat(c, dif);
		if (c.dead)
			scoreCell(c);
	}

	function scoreCell(c:Cell) {
		var score = KKApi.const(25);
		if (c.baseRay > 16)
			score = KKApi.const(50);
		if (c.baseRay > 50)
			score = KKApi.const(100);
		if (c.baseRay > 80)
			score = KKApi.const(200);
		Game.me.addScore(score);

		var mc = new Gfx.McScore();
		mc.gfx.field.text = Std.string(KKApi.val(score));
		Game.me.lvl.dm.add(mc, 4);
		var sp = new Element(mc, c.sprite.x, c.sprite.y);

		var sc = 0.75;
		if (c.baseRay > 16)
			sc = 2;
		if (c.baseRay > 50)
			sc = 3.5;
		if (c.baseRay > 80)
			sc = 5;

		var lim = 0.5;
		if (sc * Game.me.lvl.scale < lim) {
			sc = lim / Game.me.lvl.scale;
		}

		mc.scaleX = mc.scaleY = sc;

		// (the colour of the glow: a picture only, the visual random)
		var base = 50;
		var inc = 255 - base;
		var color = Col.objToCol({r: base + Seed.randomVfx(inc), g: 0, b: base + Seed.randomVfx(inc)});

		// new GlowFilter(color, 1, 2, 2, 10)
		mc.gfx.field.filters = [
			{
				type: "glow",
				blurX: 2,
				blurY: 2,
				strength: 10,
				color: color,
				passes: 1
			}
		];
	}
}
