package loader;

import flash.Boot;
import flash.display.MovieClip;
import flash.text.TextField;

[Embed(source = "/_assets/assets.swf", symbol = "symbol8")] public dynamic class WaitServer extends MovieClip {
	public var contacting_server:TextField;

	public function new() {
		if (Boot.skip_constructor) {
			return;
		}
		super();
		contacting_server.text = Loader.TEXT.CONTACTING_SERVER;
	}
}
