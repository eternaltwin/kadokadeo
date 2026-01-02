package loader;

import flash.Boot;
import flash.display.MovieClip;
import flash.events.Event;

public class Skinner {
	public var mc:MovieClip;
	public var f:Function;

	public function new(mc:MovieClip = undefined, f:Function = undefined) {
		if (Boot.skip_constructor) {
			return;
		}
		mc = mc;
		f = f;
		mc.addEventListener(Event.ENTER_FRAME, onAdded);
	}

	public function onAdded(_: *):void {
		if (f(mc)) {
			mc.removeEventListener(Event.ENTER_FRAME, onAdded);
		}
	}
}
