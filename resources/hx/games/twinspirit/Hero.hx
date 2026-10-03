package twinspirit;

import common_haxe_avm1.KeyboardManager;

typedef Move = {
	x:Int,
	y:Int,
	fire:Bool
}

enum State {
	Birth;
	Play;
	Death;
}

enum Control {
	Keyboard;
	Replay;
	Follow;
}

class Hero extends Phys {
	static var SPEED = 4.5;
	static var INCLINE_MAX = 5;

	var flStand:Bool;

	var cooldown:Int;

	public var id:Int;

	var timer:Int;
	var incline:Int;
	var smokeLoop:Float;

	var state:State;

	public var control:Control;

	var destiny:Array<Move>;
	var oldPos:Array<{x:Float, y:Float}>;

	var decal:Move;

	public var move:Move;

	var skin:Clip;

	public function new(id:Int) {
		this.id = id;

		Game.me.heros.push(this);
		super(Game.me.dm.add(new Clip("mcHero"), Game.DP_HERO));
		var c:Clip = cast root;
		c.gotoAndStop(id + 1);
		root._xscale = root._yscale = 90;
		skin = c.getClip("smc");
		if (skin != null)
			skin.gotoAndStop(6);

		ray = 8;
		incline = 0;
		smokeLoop = 0;
		flStand = false;

		control = Keyboard;
		destiny = [];
	}

	override public function update() {
		switch (state) {
			case Birth:
				updateBirth();
			case Play:
				updatePlay();
			case Death:
			case null:
		}
		super.update();
		fxQueue();
	}

	// BIRTH
	public function birth() {
		state = Birth;
		timer = 18;
		x = Cs.mcw * 0.5 + (id * 2 - 1) * 30;
		y = Cs.mch + 10;
		cooldown = 0;
		root._visible = true;
		oldPos = [];
		updatePos();
		root.updateState();

		setLabel(0xFFFFFF, id, 60);
		mcLabel.sy = 1;
		mcLabel.dec = 14;
	}

	public function updateBirth() {
		y -= Math.min(6, timer * 0.5);
		if (timer-- < 0)
			initPlay();
	}

	// PLAY
	public function initPlay() {
		state = Play;
	}

	public function updatePlay() {
		if (cooldown > 0)
			cooldown--;
		fly();
		recal();
		updateSkin();
		checkCols();
	}

	public function updateSkin() {
		var lim = INCLINE_MAX;
		incline = Std.int(Num.mm(-lim, incline - move.x, lim));
		if (move.x == 0 && incline != 0)
			incline += incline > 0 ? -1 : 1;
		if (skin != null)
			skin.gotoAndStop(lim + 1 + incline);
	}

	// COLS
	function checkCols() {
		var bx = Cs.getPX(x);
		var by = Cs.getPY(y);

		for (nx in 0...3) {
			for (ny in 0...3) {
				var px = bx + nx - 1;
				var py = by + ny - 1;
				// SHOTS
				for (shot in Game.me.shotCell(px, py).copy()) {
					var dx = shot.x - x;
					var dy = shot.y - y;
					var dist = Math.sqrt(dx * dx + dy * dy);
					if (dist < ray + shot.ray) {
						if (Game.me.robertId == null) {
							Game.me.robertId = shot.owner;
							Game.me.shotId = shot.bsid;
						}
						shot.kill();
						death();
					}
				}

				// BADS
				for (b in Game.me.badCell(px, py).copy()) {
					var dx = b.x - x;
					var dy = (b.y - y) / b.scy;
					var dist = Math.sqrt(dx * dx + dy * dy);
					if (dist < ray + b.ray) {
						if (Game.me.robertId == null)
							Game.me.robertId = b.rid;
						b.explode(true);
						death();
					}
				}
			}
		}
	}

	function recal() {
		if (x < ray || x > Cs.mcw - ray)
			x = Num.mm(ray, x, Cs.mcw - ray);
		if (y < ray || y > Cs.mch - ray)
			y = Num.mm(ray, y, Cs.mch - ray);
	}

	// ACTION
	public function fly() {
		// BUILD MOVE
		move = {x: 0, y: 0, fire: false};
		switch (control) {
			case Keyboard:
				if (KeyboardManager.isDown(KeyboardManager.LEFT))
					move.x -= 1;
				if (KeyboardManager.isDown(KeyboardManager.RIGHT))
					move.x += 1;
				if (KeyboardManager.isDown(KeyboardManager.UP))
					move.y -= 1;
				if (KeyboardManager.isDown(KeyboardManager.DOWN))
					move.y += 1;
				if (KeyboardManager.isDown(KeyboardManager.SPACE))
					move.fire = true;
				if (KeyboardManager.isDown(KeyboardManager.ENTER))
					move.fire = true;
				if (KeyboardManager.isDown(KeyboardManager.CONTROL))
					move.fire = true;
				if (!Game.me.flTwinMode)
					destiny.push(move);

			case Replay:
				var m = destiny.shift();
				if (m != null)
					move = m;
				if (destiny.length == 0) {
					control = Follow;
				}

			case Follow:
				var h = getTwin();
				if (h != null && h.move != null && (h.move.x != 0 || h.move.y != 0))
					decal = h.move;
				var coef = 0.2;
				if (decal != null && h != null) {
					var wpx = h.x - decal.x * ray * 2;
					var wpy = h.y - decal.y * ray * 2;

					var dx = wpx - x;
					var dy = wpy - y;
					x += dx * coef;
					y += dy * coef;
				}

				move.fire = true;
		}

		var coef = 1.0;

		var fls = move.x == 0 && move.y == 0;
		if (flStand && !fls)
			coef = 0.5;
		flStand = fls;

		x += move.x * SPEED * coef;
		y += move.y * SPEED * coef;

		if (move.fire)
			fire();
	}

	public function fire() {
		if (cooldown > 0)
			return;

		cooldown = 4;

		switch (id) {
			case 0:
				for (i in 0...2) {
					var sens = i * 2 - 1;
					var shot = new HeroShot(Game.me.dm.add(new Clip("mcHeroShot"), Game.DP_SHOTS));
					var a = -1.57 + sens * 0.2;
					var ca = Cs.cos(a);
					var sa = Cs.sin(a);
					var sp = 20;
					shot.x = x + ca * ray + sens * 10;
					shot.y = y + sa * ray - 5;
					shot.vx = ca * sp;
					shot.vy = sa * sp;
					shot.root._xscale = shot.root._yscale = 70;
					shot.root._rotation = a / 0.0174 + 90;
					shot.updatePos();
					shot.root.updateState();
				}

			case 1:
				for (i in 0...2) {
					var sens = i * 2 - 1;
					var shot = new HeroShot(Game.me.dm.add(new Clip("mcHeroShot"), Game.DP_SHOTS));
					var a = -1.57;
					var ca = Cs.cos(a);
					var sa = Cs.sin(a);
					var sp = 20;
					shot.x = x + ca * ray + sens * 5;
					shot.y = y + sa * ray - 5;
					shot.vx = ca * sp;
					shot.vy = sa * sp;
					shot.root._xscale = shot.root._yscale = 70;
					shot.root._rotation = a / 0.0174 + 90;
					shot.updatePos();
					shot.root.updateState();
				}
		}
	}

	public function death() {
		if (!Game.me.isPlaying())
			return;
		if (mcLabel != null)
			mcLabel.removeMovieClip();
		root._visible = false;
		if (!Game.me.flTwinMode) {
			control = Replay;
			Game.me.initBomb(this, Reverse);
			state = Death;
		} else {
			if (control == Keyboard) {
				if (Game.me.heros.length > 1) {
					var h = getTwin();
					h.control = Keyboard;
					Game.me.initBomb(this, Transfert);
				} else {
					Game.me.initGameOver();
				}
			} else {
				Game.me.initBomb(this, Standard);
			}
			kill();
		}

		fxExplode();
	}

	override public function kill() {
		Game.me.heros.remove(this);
		super.kill();
	}

	// TOOLS
	public function getTwin():Hero {
		for (h in Game.me.heros)
			if (h != this)
				return h;
		return null;
	}

	// FX
	public function fxExplode() {
		for (i in 0...10) {
			var mc = Game.me.dm.add(new Mc("explosion", true, 0.5), Game.DP_FRONT_FX);
			var p = new mt.bumdum.Phys(mc);
			mc.onEnd = p.kill;
			p.x = x + (Seed.randVfx() * 2 - 1) * 6 * i;
			p.y = y + (Seed.randVfx() * 2 - 1) * 6 * i;
			p.root._rotation = Seed.randVfx() * 360;
			p.vx = (Seed.randVfx() * 2 - 1) * 3;
			p.updatePos();
			p.sleep = i * 0.5;
			p.root.stop();
			p.setScale(100 + Seed.randVfx() * 100);
			p.root._visible = false;
		}
	}

	// exhaust: a stretched streak from the previous position (scrolled) to the reactor
	public function fxQueue() {
		var speed = Scroller.HIGHSPEED;

		var dist = 0.0;
		var ec = 6;
		var size = 35;
		var my = 10;
		var max = 2;

		if (id == 0) {
			ec = 0;
			size = 50;
			my = 8;
			max = 1;
		}

		for (i in 0...max) {
			var nx = x + (i * 2 - 1) * (ec - Math.abs(incline) * 0.5) + incline * (ec / 6);
			var ny = y + my;
			var ox = nx, oy = ny;
			if (oldPos[i] != null) {
				ox = oldPos[i].x;
				oy = oldPos[i].y + speed;
			}

			var dx = ox - nx;
			var dy = oy - ny;
			dist = Math.sqrt(dx * dx + dy * dy);

			var mc = Game.me.dm.add(new Mc("queueHero"), Game.DP_UNDER_FX);
			mc.removeAfter = true;
			var p = new Part(mc);
			p.x = nx;
			p.y = ny;
			p.root._rotation = Math.atan2(dy, dx) / 0.0174;
			p.root._xscale = dist;
			p.root._yscale = size;
			p.updatePos();
			p.root.updateState();
			p.vy = speed;
			p.timer = 10;
			p.fadeLimit = 0;
			oldPos[i] = {x: nx, y: ny};
		}

		smokeLoop = (smokeLoop + dist) % 800;
	}
}
