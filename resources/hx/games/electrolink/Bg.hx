package electrolink;

import pixi.core.sprites.Sprite as PixiSprite;
import pixi.core.textures.Texture;
import electrolink.Gfx.Piece;

// mcBg (38): the board and its circuit, 4 electric sparks, the circuit drawn over them.
// Each spark is a controller (sprites 32, 34, 36) whose frame scripts, every frame after the first one, play its
// anim when `random(n) + base == base + 1`; the anim (28, 33, 35) runs its path once and stops on its frame 1
// (stop()). The spark is a part1 dot (2 frames looping since the decor was created) drawn with blendMode "overlay":
// one picture per frame of the path and per frame of part1 (electrolink_assets.py). Only pictures: random of the
// visual seed.
class Bg extends MC {
	var sparks:Array<PixiSprite> = [];
	var pics:Array<Array<Texture>> = [];
	var frame:Array<Int> = [];
	var on:Array<Bool> = [];
	var age:Int = 0;

	public function new() {
		super();
		Piece.sprite(spr, "bg", 1 / Game.K);
		for (i in 0...Data.SPARK_FRAMES.length) {
			pics.push(Tex.get("spark" + i));
			sparks.push(Piece.sprite(spr, "spark" + i, 1 / Game.K));
			frame.push(1);
			on.push(false);
		}
		Piece.sprite(spr, "bgTop", 1 / Game.K);
	}

	override function advance():Void {
		age++;
		for (i in 0...sparks.length) {
			if (!on[i])
				continue;
			frame[i]++;
			if (frame[i] > Data.SPARK_FRAMES[i]) {
				// back on frame 1: stop()
				frame[i] = 1;
				on[i] = false;
			}
		}
		// the controllers: random(n) + base == base + 1 (play() on a playing anim changes nothing)
		for (i in 0...sparks.length)
			if (Seed.randomVfx(Data.SPARK_ODDS[i]) == 1)
				on[i] = true;
	}

	override function drawn(f:Float):Void {
		for (i in 0...sparks.length) {
			var t = pics[i][(frame[i] - 1) * 2 + age % 2];
			var s = sparks[i];
			if (s.texture != t) {
				s.texture = t;
				s.anchor.copyFrom(t.defaultAnchor);
			}
		}
	}
}
