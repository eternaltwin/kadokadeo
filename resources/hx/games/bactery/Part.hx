package bactery;

import mt.Timer;
import mt.bumdum.Lib;

class Part {
	public var x:Float;
	public var y:Float;
	public var vitx:Float;
	public var vity:Float;
	public var vitr:Float;
	public var vits:Float;
	public var timer:Float;

	public var sleep:Float;
	public var weight:Float;

	public var friction:Float;
	public var scale:Float;
	public var alpha:Float;
	public var fadeLimit:Float;

	public var skin:ASprite;

	public var fadeTypeList:Array<Int>;
	public var fadeColor:Int;

	public var game:Game;

	public function new() {
		x = 0;
		y = 0;
		vitx = 0;
		vity = 0;
		scale = 100;
		alpha = 100;
		fadeTypeList = [0];
		fadeLimit = 10;
	}

	public function init():Void {
		skin._xscale = scale;
		skin._yscale = scale;
		skin._alpha = alpha;
	}

	public function setSkin(mc:ASprite):Void {
		skin = mc;
		mc.obj = cast this;
	}

	public function update():Void {
		if (sleep != null) {
			sleep -= Timer.tmod;
			if (sleep < 0) {
				skin._visible = true;
				sleep = null;
			}
			return;
		}

		var flKill = false;
		if (weight != null)
			vity += weight * Timer.tmod;

		if (friction != null) {
			vitx *= friction;
			vity *= friction;
		}

		x += vitx * Timer.tmod;
		y += vity * Timer.tmod;

		if (timer != null) {
			timer -= Timer.tmod;
			if (timer < 0) {
				flKill = true;
			} else if (timer < fadeLimit) {
				var c = timer / fadeLimit;
				for (fadeType in fadeTypeList) {
					switch (fadeType) {
						case 0:
							skin._xscale = c * scale;
							skin._yscale = c * scale;
						case 1:
							skin._alpha = c * alpha;
						case 2:
							Col.setPercentColor(skin, 100 - c * 100, fadeColor);
						case 3:
							skin._xscale = scale * (2 - c);
							skin._yscale = scale * (2 - c);
						case 4:
							skin._yscale = c * scale;
					}
				}
			}
		}

		if (vitr != null) {
			if (friction != null)
				vitr *= friction;
			skin._rotation += vitr * Timer.tmod;
		}

		if (vits != null) {
			if (friction != null)
				vits *= friction;
			scale += vits * Timer.tmod;
			skin._xscale = scale;
			skin._yscale = scale;
		}

		if (flKill)
			kill();

		skin._x = x;
		skin._y = y;
	}

	public function orient():Void {
		skin._rotation = Math.atan2(vity, vitx) / 0.0174;
	}

	public function kill():Void {
		for (i in 0...game.pList.length) {
			if (game.pList[i] == this) {
				game.pList.splice(i, 1);
				break;
			}
		}
		skin.removeMovieClip();
	}
}
