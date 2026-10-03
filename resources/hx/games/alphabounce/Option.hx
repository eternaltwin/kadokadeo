package alphabounce;

import mt.bumdum.Phys;
import pixi.core.graphics.Graphics;

// mcOption: the capsule `smc` (coloured), the reel `scroll` (coloured back + letter) seen through a mask, a gloss
class OptionSkin extends ASprite {
	public var scroll:ASprite;
	public var back:Mc;
	public var back1:Mc;
	public var scrollBack:Mc;
	public var letter:Mc;
	public var letterGlow:Mc;

	public function new() {
		super();
		back = new Mc("optBack0", false);
		addChild(back);
		back1 = new Mc("optBack1", false);
		addChild(back1);
		smc = back;
		scroll = new ASprite();
		scroll._x = -8;
		scroll._y = -5;
		scrollBack = new Mc("scrollBack", false);
		scroll.addChild(scrollBack);
		letterGlow = new Mc("letterGlow", false);
		scroll.addChild(letterGlow);
		letter = new Mc("letter", false);
		scroll.addChild(letter);
		addChild(scroll);
		var mask = new Graphics();
		mask.beginFill(0xFFFFFF);
		mask.drawRect(-10, -5, 20, 10);
		mask.endFill();
		addChild(mask);
		scroll.mask = mask;
		var gloss = new Mc("optGloss", false);
		gloss._x = -13;
		gloss._y = -5.05;
		gloss.blendMode = pixi.core.Pixi.BlendModes.ADD;
		addChild(gloss);
	}
}

class Option extends Phys {
	public static var FALL_SPEED = 3;
	public static var PROB:Array<Float> = [
		4, // A IMANT
		1, // B LINDAGE
		12, // C OLLE
		10, // D IMINUTION
		30, // E XTENSION
		10, // F LAMME
		7, // G LACE
		5, // H ALO
		3, // I NVERSION
		10, // J AVELOT
		0.5, // K AMIKAZE
		5, // L ASER
		36, // M ULTI-BALL
		6, // N ERVEUX
		4, // O UVRE
		3, // P ROTECTION
		2, // Q UASAR
		5, // R ALLENTISSEMENT
		5, // S AUVETAGE
		10, // T EMPORALITE
		0.5, // U NIFICATION
		2, // V AGUE
		2, // W HISKY
		1, // X ENOPHOBIE
		1, // Y OYO
		5, // Z ELE
	];

	public var id:Int;
	public var color:Int;

	var skin:OptionSkin;

	public function new(mc:OptionSkin) {
		super(mc);
		Game.me.options.push(this);
		vy = FALL_SPEED;
		skin = mc;
	}

	function getRandomId():Int {
		var sum:Int = 0;
		for (n in PROB)
			sum += Std.int(n * 10);
		var rnd = Seed.random(sum);
		sum = 0;
		for (i in 0...PROB.length) {
			sum += Std.int(PROB[i] * 10);
			if (sum > rnd)
				return i;
		}
		return 0;
	}

	public function setType(?n:Int) {
		if (n == null) {
			n = getRandomId();
			while (isBad(n) && Game.me.lvl == 0)
				n = getRandomId();
		}
		id = n;
		skin.letter.gotoAndStop(n + 1);
		skin.letterGlow.gotoAndStop(n + 1);

		// COLOR
		var col = getCol(id);
		skin.back.tint = Cs.offCol(col, 204);
		skin.back1.tint = col;
		skin.scrollBack.tint = Cs.offCol(col, 204);
		var o = Col.colToObj(col);
		var inc = -200;
		o.r = Std.int(Math.max(o.r + inc, 0));
		o.g = Std.int(Math.max(o.g + inc, 0));
		o.b = Std.int(Math.max(o.b + inc, 0));
		skin.letter.tint = Col.objToCol(o);
		color = col;
	}

	override public function update() {
		super.update();

		// SCROLL
		skin.scroll._y += 1;
		if (skin.scroll._y > -5) {
			skin.scroll._y -= 26;
			skin.scroll.updateState();
		}

		// COLS
		if (Math.abs(y - (Game.me.pad.y + Cs.BH * 0.5)) < Cs.BH && Math.abs(x - Game.me.pad.x) < Game.me.pad.ray + Cs.BW * 0.5) {
			apply();
		}
	}

	function apply() {
		// PARTS
		for (i in 0...16) {
			var p = new alphabounce.fx.LineUp(Game.me.dm.attach("lineUp", Game.DP_PARTS));
			p.y = y + (Seed.randVfx() * 2 - 1) * Cs.BH * 0.5;
			p.x = x + (Seed.randVfx() * 2 - 1) * Cs.BW * 0.5;
			p.vx = (Seed.randVfx() * 2 - 1) * 5;
			p.factor = 8;
			p.timer = 10 + Seed.randVfx() * 10;
			p.frict = 0.9;
		}

		var mc = Game.me.dm.attach("onde", Game.DP_UNDERPARTS);
		mc.removeAfter = true;
		mc._x = x;
		mc._y = y;

		Game.me.getOption(id);
		kill();
	}

	override public function kill() {
		Game.me.options.remove(this);
		super.kill();
	}

	public static function getCol(id:Int):Int {
		return Data.OPT_COL[id];
	}

	public static function isBad(id:Int) {
		return id == 1 || id == 3 || id == 6 || id == 8 || id == 13 || id == 22 || id == 23 || id == 25;
	}
}
