package pacifik;

import pacifik.FlashFilters;
import pixi.core.sprites.Sprite as PixiSprite;
import pixi.core.textures.Texture;

/**
 * The particles of Pacifik (mcBallPart, mcCanonPart, mcLaserPart, mcCarPart, mcSmoke): polylines of 0.25 pixel strokes,
 * which Flash draws at least 1 pixel wide whatever the scale of the clip (the bonus sparks grow ~9 times, the laser
 * sparks get a _yscale of 0). Each segment (Data.PARTS) is drawn by the game: placed with the clip's scales, 1 Flash
 * pixel wide (more once the scaled stroke is wider), in the colour of the frame.
 *
 * Their GlowFilter (Filt.glow(mc, 8, 1, colour): a box blur of 8 stage pixels of the alpha, strength 1, in a colour,
 * under the clip) is drawn for all the particles of a plane at once (GlowLayer): a twin of every particle, in the colour
 * of its glow, blurred together. With strength 1 the glow of a particle is linear in its alpha, so the blur of the sum
 * is the sum of the glows; the layer sits under the oldest particle of the plane (Flash: under each particle).
 */
class Part extends MC {
	// a horizontal stroke 1 texel long: 2 texels of ink between 2 transparent ones (the anti-aliasing of the edges)
	static var brush:Texture;

	var kind:Array<{segs:Array<Array<Float>>, color:Int, width:Float}>;
	var segs:Array<PixiSprite> = [];
	var twinSegs:Array<PixiSprite> = [];
	var shownFrame:Int = -1;

	// the glow: colour (-1: none), blur (stage pixels) and the twin in the glow layer of the plane
	public var glowColor:Int = -1;
	public var glowBlur:Float = 8;

	var twin:ASprite = null;
	var layer:GlowLayer = null;

	public function new(name:String) {
		super();
		kind = Reflect.field(Data.PARTS, name);
		_totalframes = kind.length;
	}

	static function getBrush():Texture {
		if (brush == null) {
			var px = new js.lib.Uint8Array([0, 0, 0, 0, 255, 255, 255, 255, 255, 255, 255, 255, 0, 0, 0, 0]);
			brush = (cast Texture : Dynamic).fromBuffer(px, 1, 4);
		}
		return brush;
	}

	// Filt.glow(mc, blur, 1, colour)
	public function glow(color:Int, blur:Float):Void {
		glowColor = color;
		glowBlur = blur;
	}

	function makeSprites(into:Array<PixiSprite>, holder:pixi.core.display.Container, n:Int):Void {
		while (into.length < n) {
			var s = new PixiSprite(getBrush());
			s.anchor.set(0.5, 0.5);
			holder.addChild(s);
			into.push(s);
		}
		for (i in 0...into.length)
			into[i].visible = i < n;
	}

	override function display(f:Float):Void {
		if (glowColor >= 0 && twin == null && parent != null)
			attachTwin();
		// the scales of the clip are applied to the segments, not to the picture (the stroke keeps its width)
		var fr = fresh ? 1.0 : f;
		var sx = (pxs + (_xscale - pxs) * fr) / 100;
		var sy = (pys + (_yscale - pys) * fr) / 100;
		super.display(f);
		spr._xscale = 100;
		spr._yscale = 100;
		var k = kind[_currentframe - 1];
		var sw = Math.max(k.width * Math.sqrt(Math.abs(sx * sy)), 1);
		var n = k.segs.length;
		makeSprites(segs, spr, n);
		if (twin != null)
			makeSprites(twinSegs, twin, n);
		for (i in 0...n) {
			var g = k.segs[i];
			var x1 = g[0] * sx, y1 = g[1] * sy, x2 = g[2] * sx, y2 = g[3] * sy;
			var dx = x2 - x1, dy = y2 - y1;
			var len = Math.sqrt(dx * dx + dy * dy);
			for (s in (twin != null ? [segs[i], twinSegs[i]] : [segs[i]])) {
				s.position.set((x1 + x2) / 2, (y1 + y2) / 2);
				// (round caps: half the width more at each end)
				s.scale.set(len + sw, sw / 2);
				s.rotation = Math.atan2(dy, dx);
			}
			segs[i].tint = k.color;
			if (twin != null)
				twinSegs[i].tint = glowColor;
		}
		if (twin != null) {
			twin._curState.copyFrom(spr._curState);
			if (spr._prevState != null) {
				if (twin._prevState == null)
					twin._prevState = new common_haxe_avm1.display.ASprite.TransformState(twin);
				twin._prevState.copyFrom(spr._prevState);
			}
			twin.visible = spr.visible;
			twin.position.copyFrom(spr.position);
			twin.rotation = spr.rotation;
			twin.alpha = spr.alpha;
		}
	}

	function attachTwin():Void {
		layer = GlowLayer.of(parent, glowBlur);
		twin = new ASprite();
		layer.add(this, twin);
	}

	override function onDestroy():Void {
		if (twin != null) {
			layer.remove(this, twin);
			// (the layer may have gone first, with its children: MC.clearAll after GlowLayer.clearAll)
			if (!(cast twin : Dynamic)._destroyed)
				twin.destroy({children: true});
			twin = null;
		}
	}

	public function picture():ASprite {
		return spr;
	}
}

// the glows of the particles of a plane (of one blur): their twins blurred together (a box, quality 1)
class GlowLayer {
	static var layers:Array<GlowLayer> = [];

	var plane:MC;
	var b:Float;
	var spr:ASprite;
	var parts:Array<Part> = [];
	var blur:FlashBoxBlur;

	function new(plane:MC, b:Float) {
		this.plane = plane;
		this.b = b;
		spr = new ASprite();
		blur = cast FlashFilters.take(FlashBoxBlur);
		blur.set(b, 1);
		spr.filters = [blur];
		spr.visible = false;
		plane.spr.addChildAt(spr, 0);
	}

	public static function of(plane:MC, b:Float):GlowLayer {
		for (l in layers)
			if (l.plane == plane && l.b == b)
				return l;
		var l = new GlowLayer(plane, b);
		layers.push(l);
		return l;
	}

	public function add(p:Part, twin:ASprite):Void {
		parts.push(p);
		spr.addChild(twin);
	}

	public function remove(p:Part, twin:ASprite):Void {
		parts.remove(p);
		if (twin.parent == spr)
			spr.removeChild(twin);
	}

	// after the display of the clips: the layer just under the oldest particle that glows
	public static function placeAll():Void {
		for (l in layers)
			l.place();
	}

	function place():Void {
		var ps = plane.spr;
		if (ps == null)
			return;
		var low = -1;
		for (p in parts) {
			var s = p.picture();
			if (s == null || s.parent != ps)
				continue;
			var i = ps.getChildIndex(s);
			if (low < 0 || i < low)
				low = i;
		}
		spr.visible = low >= 0;
		if (low < 0)
			return;
		var cur = ps.getChildIndex(spr);
		var want = cur < low ? low - 1 : low;
		if (cur != want)
			ps.setChildIndex(spr, want);
	}

	public static function clearAll():Void {
		for (l in layers) {
			l.spr.filters = null;
			FlashFilters.release(l.blur);
			// (destroyed with its plane by MC.clearAll, or still to destroy)
			if (!(cast l.spr : Dynamic)._destroyed) {
				if (l.spr.parent != null)
					l.spr.parent.removeChild(l.spr);
				l.spr.destroy({children: true});
			}
		}
		layers = [];
	}
}
