package eltortuganemesis;

import eltortuganemesis.Actors;
import eltortuganemesis.Bmp;
import eltortuganemesis.Cs;
import pixi.core.Pixi.BlendModes;
import pixi.core.display.Container;
import pixi.core.math.shapes.Rectangle;
import pixi.core.sprites.Sprite as PixiSprite;
import pixi.core.textures.RenderTexture;
import pixi.core.textures.Texture;

// Text of the original (TextField autoSize LEFT, Debussy bold italic, gradient inner glow and shadow): glyph pictures
class Text extends ASprite {
	public var textWidth(default, null):Float;
	public var textHeight(default, null):Float;

	var anim:String;
	var chars:String;
	var adv:Array<Float>;
	var asc:Float;
	var text:String;

	public function new(anim:String, chars:String, adv:Array<Float>, asc:Float, desc:Float, s:String) {
		super();
		this.anim = anim;
		this.chars = chars;
		this.adv = adv;
		this.asc = asc;
		textHeight = asc + desc + 4;
		text = null;
		setText(s);
	}

	public function setText(s:String) {
		if (s == text)
			return;
		text = s;
		removeChildren();
		var pen = 2.0;
		for (i in 0...s.length) {
			var k = chars.indexOf(s.charAt(i));
			if (k < 0) {
				pen += Data.SPACE60 * asc / Data.T60_ASC;
				continue;
			}
			var g = new Mc(anim, false);
			g.gotoAndStop(k + 1);
			g._x = pen;
			g._y = 2 + asc;
			addChild(g);
			pen += adv[k];
		}
		// autoSize: the width of the text + 4
		textWidth = pen + 2;
	}
}

enum LevelScreenState {
	APPEAR;
	WAIT;
	DISAPPEAR;
}

// "LEVEL n": a lawn with the title, cut in 10 bands sliding in from both sides (a turtle at the end of each band)
// over the picture of the game, then out
class LevelScreen extends ASprite {
	static inline var NBANDS = 10;

	public var timing:Float;
	public var ratio:Float;
	public var state:LevelScreenState;
	public var direction:Int;

	var back:PixiSprite;
	var backRt:RenderTexture;
	var panelRt:RenderTexture;
	var bands:Array<PixiSprite>;
	var turtles:Array<Sym>;

	public function new(n:Int, backRt:RenderTexture) {
		super();
		state = APPEAR;
		direction = 1;
		timing = 0.0001;
		ratio = Math.NaN;
		this.backRt = backRt;
		back = new PixiSprite(backRt);
		back.scale.set(1 / Game.K);
		addChild(back);

		// the panel: lawn + title
		var holder = new Container();
		var lawn = new PixiSprite(Tex.get("lawn")[0]);
		lawn.scale.set(1 / Game.K);
		holder.addChild(lawn);
		var title = new Text("txt60", Data.T60_CHARS, Data.T60_ADV, Data.T60_ASC, Data.T60_DESC, "LEVEL " + n);
		title._x = (Game.VW - title.textWidth) / 2;
		title._y = (Game.VH / 2) - title.textHeight;
		title.updateState();
		title.updateGraphics(1);
		holder.addChild(title);
		panelRt = RenderTexture.create(Game.VW * Game.K, Game.VH * Game.K);
		var renderer:Dynamic = KadoKadeoManager.kkm.renderer;
		renderer.render(holder, {renderTexture: panelRt, clear: true, transform: new pixi.core.math.Matrix(Game.K, 0, 0, Game.K, 0, 0)});
		holder.destroy({children: true});

		bands = [];
		turtles = [];
		for (i in 0...NBANDS) {
			var t = new Texture(cast panelRt.baseTexture,
				new Rectangle(0, i * Game.VH / NBANDS * Game.K, Game.VW * Game.K, Game.VH / NBANDS * Game.K));
			var s = new PixiSprite(t);
			s.scale.set(1 / Game.K);
			s.visible = false;
			addChild(s);
			bands.push(s);
			var tu = new Sym("tortue", Data.SUB_TORTUE);
			tu.gotoAndStop(1);
			tu.visible = false;
			addChild(tu);
			turtles.push(tu);
		}
	}

	inline public static function expo(ratio:Float):Float {
		return Math.pow(2, 8 * (ratio - 1));
	}

	public function step(subProcessReady:Bool):Bool {
		timing += Timer.deltaT * 1000;
		switch (state) {
			case APPEAR:
				ratio = Math.min(1.0, timing / 1000);
				if (ratio >= 1.0) {
					timing = 0.0;
					back.visible = false;
					state = WAIT;
				}
			case WAIT:
				if (timing >= 1000 && subProcessReady) {
					timing = 0.0;
					direction = -1;
					state = DISAPPEAR;
				}
			case DISAPPEAR:
				ratio = 1 - Math.min(1.0, timing / 1000);
				if (ratio <= 0)
					return true;
		}
		layout();
		return false;
	}

	function layout() {
		if (Math.isNaN(ratio))
			return;
		var th = 18;
		var tw = 36;
		var fxratio = expo(ratio);
		for (i in 0...NBANDS) {
			var by = i * Game.VH / NBANDS;
			var x = (i % 2 == 0) ? (1 - fxratio) * (Game.VW + tw) : (1 - fxratio) * -(Game.VW + tw);
			bands[i].visible = true;
			bands[i].position.set(x, by);
			var tu = turtles[i];
			tu.visible = true;
			if (i % 2 == 1) {
				tu._xscale = direction * 100;
				tu._x = x + Game.VW + tw / 2;
			} else {
				tu._xscale = -direction * 100;
				tu._x = x - tw / 2;
			}
			tu._y = by + th;
		}
	}

	public function dispose() {
		removeMovieClip();
		panelRt.destroy(true);
	}
}

// particles of a cut: blades of grass flying away from the zone just mown
class CutParticle {
	public var dx:Float;
	public var dy:Float;
	public var rs:Float;
	public var sx:Float;
	public var sy:Float;
	public var x:Float;
	public var y:Float;
	public var r:Float;
	public var alive:Bool;
	public var spr:PixiSprite;

	public function new(ox:Float, oy:Float, dx:Float, dy:Float, rs:Float, sx:Float, sy:Float) {
		this.dx = dx;
		this.dy = dy;
		this.rs = rs;
		this.sx = sx;
		this.sy = sy;
		this.x = ox;
		this.y = oy;
		this.r = rs;
		this.alive = true;
	}

	public function update() {
		x += dx;
		y += dy;
		r += rs;
		sx -= 0.02;
		sy -= 0.02;
		if (sx <= 0 || sy <= 0)
			alive = false;
	}
}

class CutParticleSystem extends ASprite {
	static var maxSize:Float = 200 * 200;
	static var maxParticles:Float = 1000;

	var particles:Array<CutParticle>;
	var wild:Array<Texture>;

	inline static function random(low:Float, max:Float):Float {
		return low + (max - low) * Seed.randVfx();
	}

	// the zone of the last cut: pixels of lastFill whose red is 255
	public function new(lastFill:Bmp) {
		super();
		particles = [];
		wild = Tex.get("grass_wild");
		var x0 = lastFill.width, y0 = lastFill.height, x1 = -1, y1 = -1;
		for (y in 0...lastFill.height)
			for (x in 0...lastFill.width)
				if (((lastFill.data[y * lastFill.width + x] >> 16) & 255) == 255) {
					if (x < x0)
						x0 = x;
					if (x > x1)
						x1 = x;
					if (y < y0)
						y0 = y;
					if (y > y1)
						y1 = y;
				}
		if (x1 < 0)
			return;
		var rw = x1 - x0 + 1, rh = y1 - y0 + 1;
		var surface = rw * rh;
		var nparticles = Math.min(maxParticles, maxParticles * surface / maxSize);
		var step = Math.round(Math.sqrt(surface / nparticles));
		if (step < 1)
			step = 1;
		for (i in 0...Math.ceil(rw / step)) {
			for (j in 0...Math.ceil(rh / step)) {
				var x = Math.round(x0 + step * i);
				var y = Math.round(y0 + step * j);
				if (((lastFill.get(x, y) >> 16) & 255) == 255) {
					var p = new CutParticle(x + random(-3, 3), y - random(2, 4), random(-0.3, 0.3), random(-1, -0.5), random(-Math.PI / 80, Math.PI / 80),
						0.3 + Seed.randVfx(), 0.3 + Seed.randVfx());
					p.spr = new PixiSprite(wild[0]);
					p.spr.visible = false;
					addChild(p.spr);
					particles.push(p);
				}
			}
		}
	}

	public function step():Bool {
		var complete = true;
		for (p in particles)
			if (p.alive) {
				complete = false;
				p.update();
			}
		layout();
		return complete;
	}

	// a random blade for each particle on each frame (like the original)
	function layout() {
		for (p in particles) {
			if (!p.alive) {
				p.spr.visible = false;
				continue;
			}
			var t = wild[Seed.randomVfx(wild.length)];
			p.spr.texture = t;
			p.spr.anchor.set(0, 0);
			p.spr.visible = true;
			p.spr.scale.set(p.sx / Game.K, p.sy / Game.K);
			p.spr.rotation = p.r;
			p.spr.position.set(p.x, p.y);
		}
	}

	public function dispose() {
		removeMovieClip();
		destroy({children: true});
	}
}
