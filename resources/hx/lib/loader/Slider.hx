package loader;

import flash.Boot;
import flash.display.Sprite;

public class Slider extends Sprite {
	public var time:Number;
	public var isTitle:Boolean;

	public function new() {
		if (Boot.skip_constructor) {
			return;
		}
		super();
	}
}
