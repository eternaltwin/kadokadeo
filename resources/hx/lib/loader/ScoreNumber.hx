package loader;

import flash.Boot;
import flash.display.MovieClip;

[Embed(source = "/_assets/assets.swf", symbol = "symbol92")] public dynamic class ScoreNumber extends MovieClip {
	public function new() {
		if (Boot.skip_constructor) {
			return;
		}
		super();
	}
}
