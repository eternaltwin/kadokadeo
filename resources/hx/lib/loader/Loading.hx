package loader;

import flash.Boot;
import flash.display.MovieClip;
import flash.text.TextField;

[Embed(source = "/_assets/assets.swf", symbol = "symbol39")] public dynamic class Loading extends MovieClip {
	public var maskXXXX:MovieClip;

	public var loading:TextField;

	public var bar:MovieClip;

	public function new() {
		if (Boot.skip_constructor) {
			return;
		}
		super();
		bar.mask = maskXXXX;
		loading.text = Loader.TEXT.LOADING;
	}
}
