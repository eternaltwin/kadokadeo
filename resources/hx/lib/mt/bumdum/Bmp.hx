package mt.bumdum;

import common_haxe_avm1.display.ASprite;
import pixi.core.textures.Texture;

class Bmp extends Texture { // }
	public var root:ASprite;

	public var pq:Float;

	public function new(mc:ASprite, ?w:Int, ?h:Int, ?fl:Bool, ?color:Int, ?q:Float) {
		if (w == null)
			w = 100;
		if (h == null)
			h = 100;
		if (fl == null)
			fl = true;
		if (color == null)
			color = 0;
		if (q == null)
			q = 1;

		pq = q;
		super(null);

		root = mc;
		root.attachBitmap(this, 0);
		root._xscale = 100 / pq;
		root._yscale = 100 / pq;
	}

	public function setPos(x, y) {
		root._x = x;
		root._y = y;
	}

	public function kill() {
		this.destroy();
		root.removeMovieClip();
	}

	// DRAW
	public function drawMc(mc:ASprite, ?dx:Float, ?dy:Float, ?ct) {
		/*if (dx == null)
				dx = 0;
			if (dy == null)
				dy = 0;
			var m = new Matrix();
			m.scale((mc._xscale / 100) * pq, (mc._yscale / 100) * pq);
			m.rotate(mc._rotation * 0.0174);
			m.translate(mc._x * pq + dx, mc._y * pq + dy);
			if (ct == null)
				ct = new flash.geom.ColorTransform(1, 1, 1, 1, 0, 0, 0, -255 + mc._alpha * 2.55);
			var b = mc.blendMode;
			draw(mc, m, ct, b, null, false); */
		trace('FIXME !!');
	}

	//
	// TOOLS
	function initCache() {}

	public function restore() {}

	public function gray(c:Float, ?a) {
		/*var im = [
				1, 0, 0, 0, 0,
				0, 1, 0, 0, 0,
				0, 0, 1, 0, 0,
				0, 0, 0, 1, 0
			];
			var r = 0.4;
			var g = 0.5;
			var b = 0.1;
			if (a == null)
				a = 30;
			var gm = [
				r, g, b, 0, a,
				r, g, b, 0, a,
				r, g, b, 0, a,
				0, 0, 0, 1, 0
			];

			var fm = [];
			for (i in 0...im.length) {
				fm.push(im[i] * (1 - c) + gm[i] * c);
			}
			var fl = new flash.filters.ColorMatrixFilter();
			fl.matrix = fm;

			applyFilter(this, rectangle, new flash.geom.Point(0, 0), fl); */

		trace('FIXME !!');
	}

	// {
}
