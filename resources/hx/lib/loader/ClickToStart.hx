package loader;

import flash.Boot;
import flash.display.MovieClip;
import flash.text.TextField;

[Embed(source = "/_assets/assets.swf", symbol = "symbol10")] public dynamic class ClickToStart extends MovieClip {
	public var click_to_start:TextField;

	public function new() {
		if (Boot.skip_constructor) {
			return;
		}
		super();
		click_to_start.text = Loader.TEXT.CLICK_TO_START;
	}
}
