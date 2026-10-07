package oursouinvader;

// Ship.mt of the original: the sea urchin of the player
class Ship extends Phys {
	public static var RAY = 22;
	public static var COOLDOWN = 20;

	public var speed:Float;

	var coolDown:Float;

	public var fireRate:Float;

	var angle:Float;

	public var type:Float;

	// (the dead hero is replaced by {x: x, y: y} in the original: these read undefined, NaN)
	public var hWidth:Float;
	public var hHeight:Float;

	var shield:Int;
	var flh:Null<Float>;
	var mcBubble:MC;

	// port: Cs.game.hero = {x: x, y: y} in kill(): the methods of the hero no longer exist (a call does nothing)
	public var dead(default, null):Bool = false;

	public function new(mc:MC) {
		super(mc);

		x = 150;
		y = 285;
		vx = 0;
		vr = 0;
		hWidth = 22;
		hHeight = 15;

		coolDown = 0;
		angle = 0;
		shield = 0;

		initState();

		// GlowFilter(color 0x3333FF, alpha 0.1, blur 15 x 15, strength 0.8)
		root.setGlow(0x3333FF, 0.1, 15, 15, 0.8);
	}

	public function initState() {
		if (dead)
			return;
		type = 1;
		speed = 4;
		fireRate = 20;
	}

	override public function update() {
		super.update();
		// CONTROLE
		control();

		// SLOW DOWN
		if (!KeyboardManager.isDown(KeyboardManager.RIGHT) && !KeyboardManager.isDown(KeyboardManager.LEFT)) {
			// (rounded: Math.pow of the gameplay, see Cs.q)
			vx *= Cs.q(Math.pow(0.1, Timer.tmod));
			angle *= Cs.q(Math.pow(0.7, Timer.tmod));
		}
		x += vx * Timer.tmod;

		// HIT TEST
		if ((x + RAY) > 300)
			x = (300 - RAY);
		if ((x - RAY) < 0)
			x = RAY;

		// COOLDOWN
		if (coolDown > 0) {
			coolDown -= Timer.tmod;
		}
		// INCLINAISON
		root._rotation = angle;

		//
		if (mcBubble != null) {
			mcBubble._x = x;
			mcBubble._y = y;
		}
		//
		updateFlasher();
	}

	function control() {
		if (KeyboardManager.isDown(KeyboardManager.RIGHT)) {
			x += speed;
			angle = (angle * 0.89) + 5;
		}
		if (KeyboardManager.isDown(KeyboardManager.LEFT)) {
			x -= speed;
			angle = (angle * 0.89) - 5;
		}

		if (KeyboardManager.isDown(KeyboardManager.SPACE)) {
			if (coolDown <= 0 && Cs.game.step == 1)
				newShot(type);
		}
	}

	function newShot(type:Float) {
		coolDown = fireRate;
		#if debug
		Cs.game.stats.shots++;
		#end
		if (type == 1) {
			var shot = new Shot(null, 0);

			var radAngle = (angle + 90) * (Math.PI / 180);
			// (rounded: the direction of the shot is gameplay, see Cs.q)
			shot.vx = Cs.q(-(Math.cos(radAngle) * shot.sShot));
			shot.vy = Cs.q(Math.sin(-radAngle) * shot.sShot);
			shot.root._rotation = angle;
			shot.x = x;
			shot.y = y - RAY;
			Cs.game.hero.root.gotoAndPlay("shoot");
		}

		if (type == 2) {
			// (the "version factorisée" of the original; the 3 shots written one by one are commented out)
			for (i in 0...3) {
				var orient = i - 1;
				var shot = new Shot(null, 0);
				var radAngle = (angle + 90 + orient * 17.5) * (Math.PI / 180);
				shot.vx = Cs.q(-(Math.cos(radAngle) * shot.sShot));
				shot.vy = Cs.q(Math.sin(-radAngle) * shot.sShot);
				// (0.0174 and not PI / 180: the side shots are drawn about 0.3 degrees off their direction)
				shot.root._rotation = radAngle / 0.0174 - 90;
				shot.x = x + 10 * orient;
				shot.y = y - RAY;
			}
			Cs.game.hero.root.gotoAndPlay("shoot");
		}
	}

	// m: the enemy shot or the monster that touched the hero
	public function shooted(m:Sprite) {
		if (dead)
			return;
		if (shield == 0) {
			explode();
		} else {
			shield--;
			m.kill();
			#if debug
			Cs.game.stats.shield++;
			#end
			if (shield == 0) {
				mcBubble.gotoAndPlay("burst");
				mcBubble = null;
			}
		}
	}

	function explode() {
		eAnim();
		kill();
	}

	function eAnim() {
		root.gotoAndPlay("die");
	}

	public function initBubble() {
		if (dead)
			return;
		if (mcBubble != null)
			return;
		shield = 1;
		mcBubble = Cs.game.dm.attach("mcBubble", 1);
		mcBubble._x = x;
		mcBubble._y = y;
	}

	public function flasher() {
		if (dead)
			return;
		flh = 100;
	}

	function updateFlasher() {
		if (flh != null) {
			var prc = flh;
			flh *= 0.9;
			if (flh < 1) {
				prc = 0;
				flh = null;
			}
			// (0xFFFFF, not 0xFFFFFF: a flash of cyan, red at 15)
			Cs.setPercentColor(root, prc, 0xFFFFF);
		}
	}

	override public function kill() {
		Cs.game.gameOver();
		// Cs.game.hero = downcast({x: x, y: y}): what the code still reads of the hero is undefined (hWidth, hHeight, the
		// position of its clip) and its methods do nothing (dead)
		dead = true;
		hWidth = Math.NaN;
		hHeight = Math.NaN;
		// root = null: the clip plays "die" and removes itself
		root = MC.NONE;
		super.kill();
	}
}
