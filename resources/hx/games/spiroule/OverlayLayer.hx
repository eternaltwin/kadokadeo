package spiroule;

import pixi.core.renderers.systems.FilterSystem;
import pixi.core.renderers.webgl.filters.Filter;
import pixi.core.textures.RenderTexture;

/**
 * The clips Spiroule draws in blendMode "overlay" (multiply where the picture under them is darker than 50 % grey,
 * screen where it is lighter) over moving pictures: the light of the turret (mcLauncher.smc, over the turret, the
 * balls and the decor) and the sparks of Ball.fxPart. PIXI cannot blend a sprite with what is under it in that mode:
 * each of them is a container kept out of the picture (renderable off), drawn into a texture of the stage just before
 * the picture is drawn (after the interpolation of the frame); the planes under DP_FX are drawn together (`low`) and an
 * OverlayFilter per container blends its texture over them, in order (the light of the turret, then the sparks).
 * (Flash blends each spark over everything drawn before it, the effects of DP_FX attached before it too: here they are
 * drawn over the sparks. These are white glows and explosions drawn in "add" mode, which the overlay of a white spark
 * would only have made whiter.)
 */
class OverlayLayer {
	var low:ASprite;
	var layers:Array<OverlaySub> = [];
	var listener:Dynamic;

	public function new(low:ASprite) {
		this.low = low;
		listener = function(_) draw();
		var ticker:Dynamic = KadoKadeoManager.kkm.ticker;
		// after the interpolation (NORMAL priority), before the picture of the page (LOW)
		ticker.add(listener, null, -10);
	}

	// a container drawn in "overlay" mode over `low` and the containers added before it (a child of `root`, so that it is
	// interpolated with the game)
	public function add(root:ASprite):ASprite {
		var c = new OverlaySub();
		root.addChild(c);
		layers.push(c);
		return c;
	}

	function draw():Void {
		var renderer:Dynamic = KadoKadeoManager.kkm.renderer;
		var root = Game.me != null ? Game.me.root : null;
		var fl = [];
		if (renderer != null && root != null) {
			// the stage (300 x 300 Flash pixels) at the resolution of the screen
			var res = Math.abs(root.worldTransform.a) * renderer.resolution;
			if (!(res > 0))
				res = Clip.K;
			for (c in layers)
				if (c.parent != null && c.shown()) {
					c.drawInto(renderer, res);
					fl.push(c.filter);
				}
		}
		var cur:Array<Dynamic> = low.filters;
		var same = cur != null && cur.length == fl.length;
		if (same)
			for (i in 0...fl.length)
				if (cur[i] != fl[i])
					same = false;
		if (!same && !(cur == null && fl.length == 0))
			low.filters = fl.length == 0 ? null : cast fl;
	}

	// the shader, compiled at the start of the game (an empty texture blended once)
	public function warm():Void {
		var renderer:Dynamic = KadoKadeoManager.kkm.renderer;
		if (renderer == null)
			return;
		var f = new OverlayFilter();
		var tmp:RenderTexture = (cast RenderTexture : Dynamic).create({width: 8, height: 8});
		f.setSource(tmp);
		var s = new pixi.core.sprites.Sprite(pixi.core.textures.Texture.WHITE);
		s.filters = [f];
		var holder = new pixi.core.display.Container();
		holder.addChild(s);
		var out:RenderTexture = (cast RenderTexture : Dynamic).create({width: 16, height: 16});
		renderer.render(holder, {renderTexture: out, clear: true});
		s.filters = null;
		holder.destroy({children: true});
		out.destroy(true);
		tmp.destroy(true);
	}

	public function dispose():Void {
		if (listener != null) {
			var ticker:Dynamic = KadoKadeoManager.kkm.ticker;
			ticker.remove(listener);
			listener = null;
		}
		if (low != null)
			low.filters = null;
		for (c in layers)
			c.dispose();
		layers = [];
	}
}

// one container of OverlayLayer: its clips (in planes), its texture, its filter
class OverlaySub extends ASprite {
	public var filter(default, null):OverlayFilter;

	var rt:RenderTexture;

	public function new() {
		super();
		renderable = false;
		filter = new OverlayFilter();
	}

	// any clip shown
	public function shown():Bool {
		for (c in children)
			for (cc in (cast c : ASprite).children)
				if (cc.visible && cc.alpha > 0)
					return true;
		return false;
	}

	public function drawInto(renderer:Dynamic, res:Float):Void {
		if (rt == null || Math.abs(rt.baseTexture.resolution - res) > 1e-6) {
			if (rt != null)
				rt.destroy(true);
			rt = (cast RenderTexture : Dynamic).create({width: Cs.mcw, height: Cs.mch, resolution: res});
		}
		renderable = true;
		renderer.render(this, {renderTexture: rt, clear: true});
		renderable = false;
		filter.setSource(rt);
	}

	public function dispose():Void {
		if (rt != null) {
			rt.destroy(true);
			rt = null;
		}
	}
}

/**
 * Flash's "overlay" of a texture of the stage (premultiplied, W3C separable blend: Cs (1 - ab) + Cb (1 - as) +
 * as ab B(cb, cs)) over the planes under DP_FX. (opalusfactory.OverlayFilter, the source drawn at run time)
 */
class OverlayFilter extends Filter {
	public function new() {
		super(null, FRAG, {
			uSrc: pixi.core.textures.Texture.EMPTY,
			uMap: [0.0, 0.0, 0.0, 0.0],
		});
	}

	public function setSource(rt:RenderTexture) {
		uniforms.uSrc = rt;
	}

	override public function apply(filterManager:FilterSystem, input:RenderTexture, output:RenderTexture, ?clear:Bool,
			?currentState:Dynamic):Void {
		var r = Game.me != null ? Game.me.root : null;
		if (r != null) {
			// screen (CSS pixels) -> Flash pixels -> the texture of the stage (0..1)
			var wt = r.worldTransform;
			var sx = 1 / (wt.a * Cs.mcw);
			var sy = 1 / (wt.d * Cs.mch);
			uniforms.uMap = [sx, sy, -wt.tx * sx, -wt.ty * sy];
		}
		filterManager.applyFilter(this, input, output, clear);
	}

	static var FRAG = "precision highp float;
varying vec2 vTextureCoord;
uniform sampler2D uSampler;
uniform sampler2D uSrc;
uniform vec4 inputSize;
uniform vec4 outputFrame;
uniform vec4 uMap;

void main(void) {
	vec4 b = texture2D(uSampler, vTextureCoord);
	vec2 screen = vTextureCoord * inputSize.xy + outputFrame.xy;
	vec2 t = screen * uMap.xy + uMap.zw;
	if (t.x < 0.0 || t.y < 0.0 || t.x > 1.0 || t.y > 1.0) {
		gl_FragColor = b;
		return;
	}
	vec4 s = texture2D(uSrc, t);
	float as = s.a;
	float ab = b.a;
	vec3 cs = as > 0.0 ? s.rgb / as : vec3(0.0);
	vec3 cb = ab > 0.0 ? b.rgb / ab : vec3(0.0);
	vec3 mul = 2.0 * cs * cb;
	vec3 scr = 1.0 - 2.0 * (1.0 - cs) * (1.0 - cb);
	vec3 bl = mix(mul, scr, step(0.5000001, cb));
	gl_FragColor = vec4(s.rgb * (1.0 - ab) + b.rgb * (1.0 - as) + as * ab * bl, as + ab * (1.0 - as));
}
";
}
