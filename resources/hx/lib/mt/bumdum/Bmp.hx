package mt.bumdum;

import pixi.core.math.Matrix;
import pixi.core.display.DisplayObject;
import pixi.core.sprites.Sprite;
import pixi.filters.colormatrix.ColorMatrixFilter;
import common_haxe_avm1.display.ASprite;
import pixi.core.textures.RenderTexture;
import pixi.core.math.shapes.Rectangle;
import pixi.core.textures.BaseRenderTexture;

class Bmp extends RenderTexture {
	public var root:ASprite;

	public var pq:Float;

	var workTexture:RenderTexture;

	public var workSprite:Sprite;
	public var copySprite:Sprite;

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
		var base = new BaseRenderTexture(w, h);
		super(base, new Rectangle(0, 0, w, h));

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
		destroyWorkTexture();
		this.destroy();
		root.removeMovieClip();
	}

	// DRAW
	public function drawMc(mc:ASprite, ?dx:Float, ?dy:Float, ?ct:ColorMatrixFilter) {
		if (dx == null)
			dx = 0;
		if (dy == null)
			dy = 0;

		var oldFilters = mc.filters;
		var oldBlendMode = mc.blendMode;
		var oldX = mc.position.x;
		var oldY = mc.position.y;
		var oldScaleX = mc.scale.x;
		var oldScaleY = mc.scale.y;
		var oldRotation = mc.rotation;
		var drawFilter = ct;
		if (drawFilter == null)
			drawFilter = getDefaultDrawFilter(mc);
		drawFilter = normalizeColorMatrixFilter(drawFilter);

		mc.filters = oldFilters == null ? [drawFilter] : oldFilters.concat([drawFilter]);
		mc.position.set(0, 0);
		mc.scale.set(1, 1);
		mc.rotation = 0;

		var m = new Matrix();
		m.scale((mc._xscale / 100) * pq, (mc._yscale / 100) * pq);
		m.rotate(mc._rotation * 0.0174);
		m.translate(mc._x * pq + dx, mc._y * pq + dy);

		renderToTexture(mc, this, m, false);

		mc.filters = oldFilters;
		mc.blendMode = oldBlendMode;
		mc.position.set(oldX, oldY);
		mc.scale.set(oldScaleX, oldScaleY);
		mc.rotation = oldRotation;
	}

	public function applyFilterToSelf(filter:Dynamic):Void {
		ensureWorkTexture();

		workSprite.texture = this;
		workSprite.filters = [filter];
		renderToTexture(workSprite, workTexture, new Matrix(), true);
		workSprite.filters = null;

		copySprite.texture = workTexture;
		renderToTexture(copySprite, this, new Matrix(), true);
	}

	function getDefaultDrawFilter(mc:ASprite):ColorMatrixFilter {
		var filter = new ColorMatrixFilter();
		filter.matrix = [
			1, 0, 0, 0,           0,
			0, 1, 0, 0,           0,
			0, 0, 1, 0,           0,
			0, 0, 0, 1, mc.alpha - 1,
		];
		return filter;
	}

	function normalizeColorMatrixFilter(filter:ColorMatrixFilter):ColorMatrixFilter {
		if (filter == null || filter.matrix == null)
			return filter;

		var matrix = filter.matrix.copy();
		for (i in [4, 9, 14, 19]) {
			if (Math.abs(matrix[i]) > 2)
				matrix[i] /= 255;
		}

		var normalized = new ColorMatrixFilter();
		normalized.matrix = matrix;
		return normalized;
	}

	function ensureWorkTexture():Void {
		if (workTexture == null)
			workTexture = RenderTexture.create(Std.int(width), Std.int(height));
		if (workSprite == null)
			workSprite = new Sprite(this);
		if (copySprite == null)
			copySprite = new Sprite(workTexture);
	}

	function destroyWorkTexture():Void {
		if (workSprite != null) {
			workSprite.destroy();
			workSprite = null;
		}
		if (copySprite != null) {
			copySprite.destroy();
			copySprite = null;
		}
		if (workTexture != null) {
			workTexture.destroy(true);
			workTexture = null;
		}
	}

	inline function renderToTexture(object:DisplayObject, texture:RenderTexture, matrix:Matrix, clear:Bool):Void {
		(untyped common_haxe_avm1.MouseManager.getApp().renderer).render(object, cast {renderTexture: texture, clear: clear, transform: matrix});
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
