package loader;

import flash.Boot;
import flash.geom.ColorTransform;
import mt.Timer;

public class GameOver {
	public var timer:Number;
	public var saving:Boolean;
	public var loader:Loader;
	public var done:Function;

	public function new(l:Loader = undefined) {
		if (Boot.skip_constructor) {
			return;
		}
		loader = l;
		timer = 0;
		saving = false;
	}

	public function update():void {
		if (saving) {
			return;
		}
		timer += Timer.tmod;
		var lim:int = 80;
		var inc:Number = timer * (255 / lim);
		var ct:ColorTransform = new ColorTransform(1, 1, 1, 1, inc, inc, inc, 0);
		loader.swf.transform.colorTransform = ct;
		if (timer >= lim) {
			saving = true;
			done();
		}
	}
}
