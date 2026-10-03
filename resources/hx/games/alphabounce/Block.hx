package alphabounce;

import mt.bumdum.Phys;
import mt.bumdum.Sprite;

// mcBlock: frame 1 = a block of the level, `smc` with one frame per life (its `smc` coloured by the code, under an
// outline); frames 2-4 = bonus blocks, 5 = block with a ball inside
class BlockSkin extends ASprite {
	static var LEVELS = [136, 221, 255];

	var base:Array<Mc>;
	var top:Mc;
	var bonus:Mc;
	var col:Int;
	var dark:Float;

	public function new() {
		super();
		base = [for (k in 0...3) new Mc("blockBase" + k, false)];
		top = new Mc("blockTop", false);
		bonus = new Mc("blockBonus", false);
		for (b in base)
			addChild(b);
		addChild(top);
		addChild(bonus);
		col = 0xFFFFFF;
		dark = 1;
		gotoAndStop(1);
		setLife(1);
	}

	override public function gotoAndStop(frame:Dynamic) {
		var f:Int = Std.int(frame);
		if (f < 1)
			f = 1;
		if (f > 6)
			f = 6;
		_currentframe = f;
		for (b in base)
			b._visible = f == 1;
		top._visible = f == 1 && lifeFrame <= 3;
		bonus._visible = f > 1;
		if (f > 1)
			bonus.gotoAndStop(f - 1);
	}

	var lifeFrame = 1;

	// smc.gotoAndStop(n)
	public function setLife(n:Int) {
		if (n < 1)
			n = 1;
		if (n > 5)
			n = 5;
		lifeFrame = n;
		for (b in base)
			b.gotoAndStop(Std.int(Math.min(n, 4)));
		if (n <= 3)
			top.gotoAndStop(n);
		top._visible = _currentframe == 1 && n <= 3;
	}

	// Col.setColor(smc.smc, col)
	public function setColor(c:Int) {
		col = c;
		applyTint();
	}

	// Col.setPercentColor(mc, prc, 0): towards black
	public function darken(c:Float) {
		dark = c;
		applyTint();
	}

	function applyTint() {
		for (k in 0...3)
			base[k].tint = mul(Cs.offCol(col, LEVELS[k]), dark);
		top.tint = mul(0xFFFFFF, dark);
		bonus.tint = mul(0xFFFFFF, dark);
	}

	static function mul(c:Int, f:Float):Int {
		var r = Std.int(((c >> 16) & 255) * f);
		var g = Std.int(((c >> 8) & 255) * f);
		var b = Std.int((c & 255) * f);
		return (r << 16) | (g << 8) | b;
	}
}

class Block {
	var flIce:Bool;

	public var flDeath:Bool;
	public var root:BlockSkin;
	public var x:Int;
	public var y:Int;
	public var type:Int;
	public var life:Float;
	public var color:Null<Int>;
	public var score:Int;

	var blink:Mc;
	var halo:Mc;

	public static inline var XS = 100 * 28 / 30;
	public static inline var YS = 100 * 12 / 10;

	public function new(px:Int, py:Int, ?t:Int) {
		Game.me.block++;
		Game.me.blocks.push(this);

		x = px;
		y = py;
		Game.me.grid[x][y] = this;
		flIce = false;
		flDeath = false;


		root = new BlockSkin();
		Game.me.bdm.add(root, 1);
		root._x = Cs.getX(x);
		root._y = Cs.getY(y);
		root._xscale = XS;
		root._yscale = YS;

		if (t != null)
			setType(t);
	}

	public function setType(t:Int) {
		type = t;
		if (type < 10) {
			life = Math.min(type, 5);
			type = 0;
			color = Game.me.paint(x, y);
			score = Cs.SCORE_BLOCK;
		} else if (type <= 12) {
			var id = type - 10;
			score = Cs.SCORE_BONUS[id];
			life = 0;
			color = [0xB3FD02, 0x0BCDFD, 0xFF5599][id];
		}

		switch (type) {
			case 13:
				life = 0;
				score = Cs.SCORE_0;
				color = 0xFFFFFF;
		}

		setSkin(root);
		setHalo();
	}

	// glow of the block layer: a halo under the block (the block with a ball has a hole, lit too)
	function setHalo() {
		if (flDeath)
			return;
		if (halo != null)
			halo.removeMovieClip();
		halo = new Mc(type == 13 ? "blockHaloBall" : "blockHalo", false);
		halo._x = Cs.getX(x);
		halo._y = Cs.getY(y);
		Game.me.halos.addChild(halo);
	}

	public function setColor(col:Int) {
		color = col;
		root.setColor(color);
	}

	public function setLife(n:Float) {
		life = n;
		root.setLife(Std.int(life) + 1);
		if (color != null)
			setColor(color);
	}

	public function setSkin(mc:BlockSkin) {
		if (type < 5) {
			mc.gotoAndStop(1);
		} else if (type <= 12) {
			var id = type - 10;
			mc.gotoAndStop(id + 2);
		} else {
			mc.gotoAndStop(type - 8);
		}
		mc.setLife(Std.int(life) + 1);
		mc.gotoAndStop(mc._currentframe);
		if (color != null)
			mc.setColor(color);
	}

	// damage of a ball (Wave: type 0, 1; Laser: no type, 1)
	public function damage(btype:Int, n:Float) {
		if (flIce) {
			explode();
			return;
		}

		if (btype == Cs.BALL_ICE) {
			iceIt();
			return;
		}

		if (life >= n) {
			setLife(life - n);

			// BLINK
			var mc = Game.me.dm.attach("blink", Game.DP_BLOCK);
			mc.removeAfter = true;
			mc._x = root._x;
			mc._y = root._y;
			mc._xscale = root._xscale;
			mc._yscale = root._yscale;
			blink = mc;
			Game.me.addScore(Cs.SCORE_BOUNCE);
		} else {
			explode();
		}
	}

	function iceIt() {
		type = 0;
		score = Cs.SCORE_ICE;
		flIce = true;
		var mc = new Mc("ice", false);
		root.addChild(mc);
		var nx = Seed.randomVfx(2);
		var ny = Seed.randomVfx(2);
		mc._xscale = (nx * 2 - 1) * 100;
		mc._yscale = (ny * 2 - 1) * 100;
		mc._x = (1 - nx) * 30;
		mc._y = (1 - ny) * 10;
	}

	public function explode() {
		Game.me.addScore(score);

		// PARTS
		var max = Std.int(Num.mm(2, 24 - Sprite.spriteList.length * 0.25, 16));
		if (type < 5) {
			var mc = Game.me.dm.attach("explode", Game.DP_PARTS);
			mc.removeAfter = true;
			mc._x = root._x;
			mc._y = root._y;
			mc._xscale = root._xscale;
			mc._yscale = root._yscale;
			if (color != null)
				mc.tint = Cs.offCol(color, 221);
			for (n in 0...max) {
				var p = new alphabounce.fx.Part(Game.me.dm.attach("part", Game.DP_PARTS));
				initExplode(p);
				p.bouncer.setPos(p.x, p.y);
				p.updatePos();
				if (color != null)
					p.root.tint = Cs.offCol(color, 204);
			}
			if (Seed.rand() < Cs.OPTION_COEF && Game.me.options.length < Cs.MAX_OPTION)
				Game.me.newOption(null, Cs.getX(x + 0.5), Cs.getY(y + 0.5));
		} else if (type <= 12) {
			// (half the stars of the original: added over each other they made a white blot)
			var max = Std.int(Math.max(2, max / 2));
			for (i in 0...max) {
				var p = new Phys(Game.me.dm.add(new Mc.TwinkleMc(), Game.DP_PARTS));
				var a = i / max * 6.28;
				var ray = 5 + Seed.randVfx() * 20;
				p.x = Cs.getX(x + 0.5) + Math.cos(a) * ray;
				p.y = Cs.getY(y + 0.5) + Math.sin(a) * ray;

				p.timer = 10 + Seed.randVfx() * 10;
				p.fadeType = 0;
				p.setScale(50 + Seed.randVfx() * 100);
				p.sleep = Seed.randVfx() * (ray - 5);
				p.vy -= Seed.randVfx();
				p.root.blendMode = pixi.core.Pixi.BlendModes.ADD;
				p.root.gotoAndPlay(Seed.randomVfx(2) + 1);
				p.updatePos();
			}
		}

		// EFFECT
		switch (type) {
			case 13:
				var b = Game.me.newBall();
				b.moveTo(root._x + Cs.BW * 0.5, root._y + Cs.BH * 0.5);
				b.setAngle(Seed.rand() * 6.28);
				for (n in 0...max) {
					var p = new alphabounce.fx.Part(Game.me.dm.attach("glass", Game.DP_PARTS));
					initExplode(p);
					p.bouncer.setPos(p.x, p.y);
					p.root._rotation = Seed.randVfx() * 2 - 1;
					p.vr = (Seed.randVfx() * 2 - 1) * 12;
					p.setScale(p.scale * (1 + Seed.randVfx() * 0.6));
					p.updatePos();
				}
		}

		// PART ICE
		if (flIce) {
			for (n in 0...Std.int(max * 0.5)) {
				var p = new Phys(Game.me.dm.attach("iceShard", Game.DP_PARTS));
				initExplode(p);
				p.weight *= 0.5;
				p.root._rotation = Math.atan2(p.vy, p.vx) / 0.0174;
				p.vr = (Seed.randVfx() * 2 - 1) * 6;
			}
		}

		// PART SCORE
		if (score >= 200) {
			var o = Col.colToObj(color);
			o.r = Std.int(Math.max(o.r - 100, 0));
			o.g = Std.int(Math.max(o.g - 100, 0));
			o.b = Std.int(Math.max(o.b - 100, 0));
			Game.me.displayScore(Cs.getX(x + 0.5), Cs.getY(y + 0.5), score, Col.objToCol(o), 1);
		}
		kill();
	}

	function initExplode(p:Phys) {
		var cx = root._x + Cs.BW * 0.5;
		var cy = root._y + Cs.BH * 0.5;

		p.x = Cs.getX(x + Seed.randVfx());
		p.y = Cs.getY(y + Seed.randVfx());
		var dx = p.x - cx;
		var dy = p.y - cy;
		var a = Math.atan2(dy, dx);
		var sp = Math.sqrt(dx * dx + dy * dy) * 0.2;
		p.vx = Math.cos(a) * sp;
		p.vy = Math.sin(a) * sp;
		p.timer = 10 + Seed.randVfx() * 30;
		p.weight = 0.05 + Seed.randVfx() * 0.1;
		p.fadeType = 0;
		p.frict = 0.98;
		p.setScale(p.weight * 700);
	}

	public function kill() {
		flDeath = true;
		Game.me.removeBlock();
		if (blink != null && !blink.dead)
			blink.removeMovieClip();
		Game.me.grid[x][y] = null;
		Game.me.blocks.remove(this);
		root.removeMovieClip();
		if (halo != null)
			halo.removeMovieClip();
	}
}
