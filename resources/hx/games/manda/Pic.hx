package manda;

import pixi.core.textures.Texture;

// A picture of the SWF (frames of an animation of the sheet): _xscale / _yscale 100 = its size in the Flash player,
// whatever the resolution of its textures.
class Pic extends ASprite {
	public var frames(default, null):Array<Texture>;
	public var cur(default, null):Int;

	var baseScale:Float;

	public function new(anim:String) {
		super();
		baseScale = 1 / (Game.K * Data.RES.get(anim));
		setAnim(anim);
		_xscale = 100;
		_yscale = 100;
	}

	// another animation drawn at the same resolution
	public function setAnim(anim:String) {
		frames = Tex.get(anim);
		texture = frames[0];
		anchor.copyFrom(frames[0].defaultAnchor);
		cur = 1;
	}

	public inline function show(i:Int) {
		if (i != cur) {
			cur = i;
			texture = frames[i - 1];
		}
	}

	override public function get__xscale():Float {
		return _curState.xscale * 100 / baseScale;
	}

	override public function set__xscale(v:Float) {
		_curState.xscale = v / 100 * baseScale;
		return v;
	}

	override public function get__yscale():Float {
		return _curState.yscale * 100 / baseScale;
	}

	override public function set__yscale(v:Float) {
		_curState.yscale = v / 100 * baseScale;
		return v;
	}
}
