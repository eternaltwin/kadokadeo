package loader;

import flash.Boot;
import flash.display.MovieClip;
import flash.text.TextField;

[Embed(source = "/_assets/assets.swf", symbol = "symbol60")] public dynamic class Score extends MovieClip {
	public var tokens:TextField;
	public var maskXXXX:MovieClip;
	public var click:MovieClip;
	public var bar:MovieClip;

	public function new() {
		if (Boot.skip_constructor) {
			return;
		}
		super();
		tokens.visible = false;
	}
}
