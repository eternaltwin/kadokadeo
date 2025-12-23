package common_haxe_avm1.display;

import pixi.core.textures.Texture;
import js.lib.Uint8Array;
import pixi.core.Pixi.Formats;
import js.lib.Uint32Array;
import haxe.io.UInt8Array;
import pixi.resources.BufferResource;
import pixi.core.textures.BaseTexture;

using Std;

class PixelDrawer {
	var texture:BaseTexture;
	var buffer:BufferResource;
	var pixelArray:Uint32Array;
	var width:Int;
	var height:Int;

	public function new(w:Int, h:Int) {
		this.width = w;
		this.height = h;

		pixelArray = new Uint32Array(w * h);
		pixelArray.fill(0);

		buffer = new BufferResource(cast new UInt8Array(cast pixelArray.buffer), {width: w, height: h});
		texture = new BaseTexture(buffer);
		texture.format = Formats.RGBA;
	}

	public function scroll(scrollX:Int, _) {
		if (scrollX < 0) {
			for (x in 0...(width - scrollX)) {
				for (y in 0...height) {
					/*var toIndex = y * buffer.width.int() + x;
						var fromIndex = toIndex + scrollX * height;
						pixelArray[toIndex] = pixelArray[fromIndex]; */
					setPixel32(x, y, getPixel32(x - scrollX, y));
				}
			}
		}
	}

	public function getTexture() {
		return texture;
	}

	public function update() {
		buffer.update();
	}

	public function getPixel32(x:Int, y:Int) {
		if (x >= width || y >= height || x < 0 || y < 0)
			return 0;
		return pixelArray[y * width + x];
	}

	public function setPixel32(x:Int, y:Int, col:Int) {
		pixelArray[y * width + x] = col;
	}

	static public function test() {
		var pd = new PixelDrawer(900, 900);
		for (i in 0...900) {
			for (n in 0...3) {
				pd.setPixel32(n + 50, i + n, 0xCCCCCCCC);
			}
		}
		pd.update();

		var root = new ASprite();
		root.texture = new Texture(pd.getTexture());

		var t = new haxe.Timer(20);
		t.run = () -> {
			pd.scroll(-1, 0);
			pd.update();
		};

		return root;
	}
}
