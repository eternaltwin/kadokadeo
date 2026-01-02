package loader;

import flash.Boot;
import flash.display.MovieClip;
import flash.text.TextField;

[Embed(source = "/_assets/assets.swf", symbol = "symbol12")] public dynamic class Saving extends MovieClip {
	public var saving:TextField;

	public function new() {
		if (Boot.skip_constructor) {
			return;
		}
		super();
	}
}
