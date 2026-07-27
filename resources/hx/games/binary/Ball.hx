package binary;

import kado.KadoKadeoManager;
import pixi.core.Pixi.BlendModes;
import pixi.core.textures.Texture;
import pixi.core.sprites.Sprite;
import mt.bumdum.Lib;

class Ball {
	static var particleGlowTexture:Texture;

	public var flIce:Bool;
	public var gid:Int;
	public var fall:Int;

	public var color:Int;
	public var px:Int;
	public var py:Int;
	public var save:{x:Int, y:Int};

	public var root:ASprite;
	public var skin:ASprite;
	public var dm:mt.DepthManager;

	public var mcArrow:ASprite;
	public var mcShade:ASprite;
	public var glow:ASprite;

	public function new(x, y, ?col) {
		root = Game.me.dm.empty(Game.DP_BALLS);
		dm = new mt.DepthManager(root);
		skin = dm.attach("mcBall2", 2);
		glow = dm.empty(0);
		var s = drawRadialGradientCircle(KadoKadeoManager.I(18), KadoKadeoManager.I(20), 0xFFFFFF);
		glow.addChild(s);

		mcShade = Game.me.sdm.attach("mcShade", 1);

		Game.me.balls.push(this);
		setPos(x, y);
		setColor(col);
	}

	public function setPos(x, y) {
		px = x;
		py = y;
		insertInGrid();
		display(px, py);
	}

	public function display(x, y) {
		root._x = Cs.getX(x);
		root._y = Cs.getY(y);

		mcShade._x = root._x + KadoKadeoManager.I(5);
		mcShade._y = root._y + KadoKadeoManager.I(5);
	}

	public function setColor(?col) {
		if (col == null)
			col = Seed.random(Cs.COLOR_MAX);
		color = col;
		var fr = color + 1;
		skin.gotoAndStop(fr);
	}

	public function select() {
		glow._xscale = glow._yscale = 115;
		Game.me.dm.over(root);
	}

	public function unselect() {
		glow._xscale = glow._yscale = 100;
	}

	public function insertInGrid() {
		Game.me.grid[px][py] = this;
	}

	public function removeFromGrid() {
		Game.me.grid[px][py] = null;
	}

	public function top() {
		removeFromGrid();
		var py = Cs.YMAX;
		while (true) {
			if (Game.me.grid[px][py] == null) {
				setPos(px, py);
				setColor(10);
				break;
			}
			py++;
		}
		setVisible(false);
		root._xscale = root._yscale = 0;
		mcShade._xscale = mcShade._yscale = 0;
	}

	public function drawRadialGradientCircle(innerRadius:Float, outerRadius:Float, color:Int = 0xFFFFFF, alpha:Float = 1):Sprite {
		if (outerRadius < innerRadius)
			outerRadius = innerRadius;

		var size = Math.ceil(outerRadius * 2);
		var center = size * 0.5;
		var canvas = js.Browser.document.createCanvasElement();
		canvas.width = size;
		canvas.height = size;

		var ctx = canvas.getContext2d();
		var gradient = ctx.createRadialGradient(center, center, innerRadius, center, center, outerRadius);
		gradient.addColorStop(0, Col.col2Rgba(color, alpha));
		gradient.addColorStop(1, Col.col2Rgba(color, 0));

		ctx.fillStyle = gradient;
		ctx.beginPath();
		ctx.arc(center, center, outerRadius, 0, Math.PI * 2);
		ctx.fill();

		var s = new Sprite(Texture.from(canvas));
		s.anchor.set(0.5, 0.5);
		return s;
	}

	static function getParticleGlowTexture():Texture {
		if (particleGlowTexture == null) {
			var radius = KadoKadeoManager.I(8);
			var size = Std.int(radius * 2);
			var canvas = js.Browser.document.createCanvasElement();
			canvas.width = size;
			canvas.height = size;

			var ctx = canvas.getContext2d();
			var gradient = ctx.createRadialGradient(radius, radius, 0, radius, radius, radius);
			gradient.addColorStop(0, Col.col2Rgba(0xFFFFFF, 0.9));
			gradient.addColorStop(1, Col.col2Rgba(0xFFFFFF, 0));

			ctx.fillStyle = gradient;
			ctx.beginPath();
			ctx.arc(radius, radius, radius, 0, Math.PI * 2);
			ctx.fill();

			particleGlowTexture = Texture.from(canvas);
		}
		return particleGlowTexture;
	}

	static function addParticleGlow(root:ASprite, color:Int):Void {
		var s = new Sprite(getParticleGlowTexture());
		s.anchor.set(0.5, 0.5);
		s.tint = color;
		s.blendMode = BlendModes.ADD;
		root.addChildAt(s, 0);
	}

	public function setVisible(fl) {
		root._visible = fl;
		mcShade._visible = fl;
	}

	// BRICOLE
	public function savePos() {
		save = {x: px, y: py};
	}

	public function loadPos() {
		px = save.x;
		py = save.y;
	}

	// KILL
	public function explode() {
		for (x in 0...4) {
			for (y in 0...4) {
				var p = new mt.bumdum.Phys(Game.me.dm.attach("partExplode", Game.DP_FX));
				var a = Seed.randVfx() * 6.28;
				var sp = Seed.randVfx() * KadoKadeoManager.I(3);
				var cr = Seed.randVfx() * 20;
				p.x = root._x + (x - 2) * KadoKadeoManager.I(14);
				p.y = root._y + (y - 2) * KadoKadeoManager.I(14);
				p.weight = KadoKadeoManager.S(-(0.05 + Seed.randVfx() * 0.05));
				p.vy = KadoKadeoManager.S(1 + Seed.randVfx());
				p.timer = 10 + Seed.randVfx() * 30;
				p.frict = 0.9;
				p.fadeType = 0;
				p.setScale(80 - (Math.abs(x - 2) + Math.abs(y - 2)) * 15);
				p.updatePos();
				addParticleGlow(p.root, Cs.COLOR_LIST[color]);
				p.root.gotoAndStop(Seed.randomVfx(p.root._totalframes) + 1);
			}
		}

		// LIGHT
		var cr = 3;
		for (i in 0...8) {
			var p = new mt.bumdum.Phys(Game.me.dm.attach("partLight", Game.DP_FX));
			var a = Seed.randVfx() * 6.28;
			var sp = Seed.randVfx() * KadoKadeoManager.I(4);
			p.vx = Math.cos(a) * sp;
			p.vy = Math.sin(a) * sp;
			p.x = root._x + p.vx * cr;
			p.y = root._y + p.vy * cr;
			p.timer = 10 + Seed.randVfx() * 20;
			p.frict = 0.9;
			p.fadeType = 0;
			p.updatePos();
		}
		top();
	}

	function kill() {
		removeFromGrid();
		Game.me.balls.remove(this);
		root.removeMovieClip();
	}
}
