package loader;

import flash.Boot;
import flash.display.Sprite;

[Embed(source = "/_assets/assets.swf", symbol = "symbol96")] public class McLayer extends Sprite {
	public function new() {
		if (Boot.skip_constructor) {
			return;
		}
		super();
	}
}
