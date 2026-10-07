package happyptitank;

import common_haxe_avm1.display.ASprite;
import pixi.core.textures.Texture;

/**
 * flash.display.Graphics: the drawing commands of a Sprite (the ground of GroundScroll), replayed into a
 * PIXI.Graphics when the sprite is shown. Flash's lines have round caps and joints; a bitmap fill is not smoothed
 * (beginBitmapFill's default) and repeats: the textures are standalone repeating textures (GroundTex).
 */
class Graphics {
	public var cmds:Array<Array<Dynamic>> = [];

	public function new() {}

	public function lineStyle(w:Float, color:Int = 0, alpha:Float = 1.0) {
		cmds.push(["ls", w, color, alpha]);
	}

	public function beginFill(color:Int, alpha:Float = 1.0) {
		cmds.push(["bf", color, alpha]);
	}

	public function beginBitmapFill(t:GroundTex, m:Mat) {
		cmds.push(["bb", t, m]);
	}

	public function endFill() {
		cmds.push(["ef"]);
	}

	public function drawRect(x:Float, y:Float, w:Float, h:Float) {
		cmds.push(["dr", x, y, w, h]);
	}

	public function drawCircle(x:Float, y:Float, r:Float) {
		cmds.push(["dc", x, y, r]);
	}

	public function moveTo(x:Float, y:Float) {
		cmds.push(["mt", x, y]);
	}

	public function lineTo(x:Float, y:Float) {
		cmds.push(["lt", x, y]);
	}

	public function curveTo(cx:Float, cy:Float, x:Float, y:Float) {
		cmds.push(["ct", cx, cy, x, y]);
	}

	public function replay(g:pixi.core.graphics.Graphics) {
		g.clear();
		for (c in cmds) {
			switch (c[0]) {
				case "ls":
					var w:Float = c[1];
					g.lineTextureStyle({
						width: w == 0 ? 1 / Game.K : w,
						color: c[2],
						alpha: c[3],
						cap: "round",
						join: "round",
						texture: Texture.WHITE
					});
				case "bf":
					g.beginFill(c[1], c[2]);
				case "bb":
					var t:GroundTex = c[1];
					var m:Mat = c[2];
					g.beginTextureFill({texture: t.texture, matrix: new pixi.core.math.Matrix(m.a, m.b, m.c, m.d, m.tx, m.ty)});
				case "ef":
					g.endFill();
				case "dr":
					g.drawRect(c[1], c[2], c[3], c[4]);
				case "dc":
					g.drawCircle(c[1], c[2], c[3]);
				case "mt":
					g.moveTo(c[1], c[2]);
				case "lt":
					g.lineTo(c[1], c[2]);
				case "ct":
					g.quadraticCurveTo(c[1], c[2], c[3], c[4]);
			}
		}
	}
}

// a Sprite with its graphics
class GfxSprite extends Sprite {
	public var graphics(default, null):Graphics = new Graphics();

	var drawn:Int = -1;
	var pg:pixi.core.graphics.Graphics = null;

	// port: the rectangle drawn (GroundScroll.createPart), to skip the tiles out of the screen: the original never
	// removes the tiles of a ground redrawn when a circle is crossed (table.reset), they pile up under the new ones
	public var area:{x:Float, y:Float, w:Float, h:Float} = null;

	public function new() {
		super();
	}

	override public function syncTree(mode:Int, f:Float, cxm:Array<Float>, cxa:Array<Float>, ghost:Bool, snap:Bool) {
		if (area != null) {
			var m = matrixTo(null);
			var x0 = m.tx + area.x;
			var y0 = m.ty + area.y;
			view(mode).renderable = x0 < Game.W + 60 && y0 < Game.H + 60 && x0 + area.w > -60 && y0 + area.h > -60;
		}
		if (mode == 0 && drawn != graphics.cmds.length) {
			drawn = graphics.cmds.length;
			if (pg == null) {
				pg = new pixi.core.graphics.Graphics();
				ownViews = [pg];
				viewDirty[0] = true;
			}
			graphics.replay(pg);
		}
		super.syncTree(mode, f, cxm, cxa, ghost, snap);
	}
}

// a BitmapData of the ground (Texture1 / Texture2 of the library, and their copies coloured by
// ColorSet.setColorBitmap): a repeating texture, sampled without smoothing
class GroundTex {
	public var texture(default, null):Texture;

	public function new(picture:String, ?color:Null<Int>) {
		var t = Tex.get(picture)[0];
		var canvas:js.html.CanvasElement = cast js.Browser.document.createElement("canvas");
		var w = Std.int(t.frame.width);
		var h = Std.int(t.frame.height);
		canvas.width = w;
		canvas.height = h;
		var ctx = canvas.getContext2d();
		var src:Dynamic = (cast t.baseTexture).resource.source;
		ctx.drawImage(src, t.frame.x, t.frame.y, w, h, 0, 0, w, h);
		if (color != null) {
			// ColorSet.setColorBitmap: BitmapData.colorTransform(rect, ColorTransform(r / 125, g / 125, b / 125))
			var r = ((color >> 16) & 0xFF) / 125;
			var g = ((color >> 8) & 0xFF) / 125;
			var b = (color & 0xFF) / 125;
			var img = ctx.getImageData(0, 0, w, h);
			var d = img.data;
			var i = 0;
			while (i < d.length) {
				d[i] = Std.int(Math.min(255, d[i] * r));
				d[i + 1] = Std.int(Math.min(255, d[i + 1] * g));
				d[i + 2] = Std.int(Math.min(255, d[i + 2] * b));
				i += 4;
			}
			ctx.putImageData(img, 0, 0);
		}
		var bt = pixi.core.textures.BaseTexture.from(canvas);
		bt.wrapMode = untyped 10497;
		bt.scaleMode = untyped 0;
		texture = new Texture(bt);
	}

	public function destroy() {
		texture.destroy(true);
	}
}
