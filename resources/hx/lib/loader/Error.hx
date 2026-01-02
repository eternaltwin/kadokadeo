package loader;

import flash.Boot;
import flash.display.MovieClip;
import flash.text.TextField;

[Embed(source = "/_assets/assets.swf", symbol = "symbol42")] public dynamic class Error extends MovieClip {
	public var msg:TextField;

	public function new() {
		if (Boot.skip_constructor) {
			return;
		}
		super();
	}
}
