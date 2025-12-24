package common_haxe_avm1;

import pixi.core.math.shapes.Rectangle;
import pixi.core.graphics.Graphics;
import pixi.core.display.DisplayObject;
import pixi.core.math.Matrix;
import pixi.core.textures.RenderTexture;
import haxe.io.UInt8Array;
import common_haxe_avm1.display.ASprite;

using Lambda;
using Std;

class PixelHelper {
	var pixels:UInt8Array;

	public var width:Int;
	public var height:Int;

	static public function fillRect(onto:RenderTexture, rectangle:Rectangle, col:Int) {
		var gfx = new Graphics();
		gfx.beginFill(col);
		gfx.drawRect(rectangle.x, rectangle.y, rectangle.width, rectangle.height);
		draw(onto, gfx, new Matrix());
	}

	static public function fill(onto:RenderTexture, col:Int) {
		var gfx = new Graphics();
		gfx.beginFill(col);
		gfx.drawRect(0, 0, onto.width, onto.height);
		draw(onto, gfx, new Matrix());
	}

	static public function draw(onto:RenderTexture, object:DisplayObject, matrix:Matrix) {
		(untyped ASprite.app.renderer).render(object, cast {renderTexture: onto, clear: false, transform: matrix});
	}

	static public function extract(texture:RenderTexture) {
		return new PixelHelper(untyped ASprite.app.renderer.plugins.extract.pixels(texture), texture.width.int(), texture.height.int());
	}

	public function new(pixels:UInt8Array, width:Int, height:Int) {
		this.pixels = pixels;
		this.width = width;
		this.height = height;
	}

	public function getPixelAlpha(x:Int, y:Int):Int {
		var pIndex = (y * width + x) * 4;
		return pixels[pIndex + 3];
	}

	public function getPixel(x:Int, y:Int):Int {
		var pIndex = (y * width + x) * 4;

		return pixels[pIndex] << 16 | pixels[pIndex + 1] << 8 | pixels[pIndex + 2];
	}
}
