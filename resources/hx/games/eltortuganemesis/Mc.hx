package eltortuganemesis;

import pixi.core.textures.Texture;

// A clip of the SWF: the frames of an animation of the sheet, played like a Flash timeline (advanced once per frame by
// Game.advanceClips, before the code of the frame). _xscale / _yscale 100 = its size in the Flash player.
// Frame scripts of the original: `stops` (stop() on these frames), `removeAfter` (removeMovieClip() on the frame
// after the last one), else the timeline loops.
class Mc extends ASprite {
	public var frames(default, null):Array<Texture>;
	public var cur(default, null):Int;
	public var playing:Bool;
	public var stops:Array<Int>;
	public var removeAfter:Bool;
	// called after the last frame (obj.kill() of a frame script), before removeAfter
	public var onEnd:Void->Void;
	public var dead(default, null):Bool;

	var baseScale:Float;

	// res: resolution of the textures of the animation (1 = 2 px per Flash pixel)
	public function new(anim:String, ?playing:Bool = true, ?res:Float = 1) {
		super();
		baseScale = 1 / (Game.K * res);
		frames = Tex.get(anim);
		texture = frames[0];
		anchor.copyFrom(frames[0].defaultAnchor);
		cur = 1;
		_totalframes = frames.length;
		stops = [];
		removeAfter = false;
		dead = false;
		_xscale = 100;
		_yscale = 100;
		this.playing = playing && frames.length > 1;
		if (frames.length > 1 && Game.me != null)
			Game.me.mcs.push(this);
	}

	public function show(i:Int) {
		if (i < 1)
			i = 1;
		if (i > frames.length)
			i = frames.length;
		cur = i;
		_currentframe = i;
		texture = frames[i - 1];
	}

	// one frame of the Flash player
	public function advance() {
		if (!playing || dead)
			return;
		if (cur >= frames.length) {
			if (onEnd != null) {
				var f = onEnd;
				onEnd = null;
				f();
			}
			if (removeAfter) {
				removeMovieClip();
				return;
			}
			show(1);
		} else {
			show(cur + 1);
		}
		if (stops.indexOf(cur) >= 0)
			playing = false;
	}

	override public function play() {
		playing = frames.length > 1;
	}

	override public function stop() {
		playing = false;
	}

	override public function gotoAndStop(frame:Dynamic) {
		show(Std.int(frame));
		playing = false;
	}

	override public function gotoAndPlay(frame:Dynamic) {
		show(Std.int(frame));
		playing = frames.length > 1 && stops.indexOf(cur) < 0;
	}

	override public function prevFrame() {
		if (cur > 1)
			show(cur - 1);
		playing = false;
	}

	override public function nextFrame() {
		if (cur < frames.length)
			show(cur + 1);
		playing = false;
	}

	override public function removeMovieClip() {
		dead = true;
		playing = false;
		super.removeMovieClip();
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

