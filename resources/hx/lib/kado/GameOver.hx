package kado;

import pixi.core.graphics.Graphics;

class GameOver extends Graphics {
	var saving:Bool = false;
	var timer:Float = 0;
	var done:() -> Void;

	var prevAlpha:Float = 0.0;
	var nextAlpha:Float = 0.0;

	public function new(done:() -> Void) {
		super();
		beginFill(0xFFFFFF);
		drawRect(0, 0, 900, 900);
		endFill();
		alpha = 0.0;
		this.done = done;
	}

	public function update():Void {
		if (saving) {
			return;
		}
		prevAlpha = nextAlpha;
		timer += mt.Timer.tmod;
		var lim:Int = 80;
		nextAlpha = timer / lim;
		if (timer >= lim) {
			saving = true;
			done();
		}
	}

	public function updateGraphics(a:Float):Void {
		alpha = mt.gx.MathEx.lerp(prevAlpha, nextAlpha, a);
	}
}
