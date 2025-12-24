package common_haxe_avm1;

import pixi.core.sprites.Sprite;
import haxe.Timer;
import common_haxe_avm1.display.ASprite;
import haxe.ds.StringMap;
import pixi.core.textures.Texture;
import js.lib.Promise;

class BmpTextureHelper {
	static var textures:StringMap<Texture> = new StringMap();

	static public function getSprite(name:String):Null<Sprite> {
		var s = new Sprite(getTexture(name));
		s.anchor.set(0.5, 0.5);
		return s;
	}

	static public function getTexture(name:String):Texture {
		return textures.get(name);
	}

	static public function exists(name:String):Bool {
		return textures.exists(name);
	}

	static public function getASprite(name:String):Null<ASprite> {
		var texture = getTexture(name);
		if (texture == null) {
			trace('Unable to get ASprite for preloaded texture $name');
			return null;
		}

		var a = ASprite.createFromTexture(name, texture);
		a.anchor.set(0.5, 0.5);

		return a;
	}

	static public function preload(urls:Array<String>):Promise<Void> {
		var start = Timer.stamp();
		return Promise.all(urls.map(n -> {
			return (untyped Texture).fromURL('/assets/img/content/$n.png').then(t -> {
				return {name: n, texture: t};
			});
		})).then((loaded:Array<{name:String, texture:Texture}>) -> {
			for (t in loaded) {
				textures.set(t.name, t.texture);
			}
			trace('Preloaded ${urls.length} textures in ${Math.round((Timer.stamp() - start) * 1000)}ms');
		});
	}
}
