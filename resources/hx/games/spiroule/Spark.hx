package spiroule;

import pixi.core.sprites.Sprite as PixiSprite;

/**
 * fxSpark (Runner, Ball.fxPart): its timeline loops on 8 frames (frame 1: the dot and its star, 2..8: the dot), the code
 * scales it (Phys fadeType 0) and gives it Filt.glow(root, 10, 2, 0xFFFFFF). Flash draws the scaled clip, then blurs it
 * by 10 stage pixels: the glow does not shrink with the clip. The pictures with their glow are drawn by the asset
 * pipeline for Data.SPARK_STEPS scales (anim "spark"): shown the one of the scale just above, shrunk to the scale.
 */
class Spark extends MC {
	var spr:PixiSprite;

	public function new() {
		super("fxSpark");
		var t = Tex.get("spark");
		spr = new PixiSprite(t[0]);
		spr.anchor.copyFrom(t[0].defaultAnchor);
		clip.addChild(spr);
	}

	override function display(f:Float):Void {
		super.display(f);
		if (removed)
			return;
		var s = clip._xscale / 100;
		var n = Data.SPARK_STEPS;
		var step = Math.ceil(s * n - 1e-9);
		if (step < 1)
			step = 1;
		if (step > n)
			step = n;
		var type = clip.frame == 1 ? 0 : 1;
		spr.texture = Tex.get("spark")[type * n + step - 1];
		var k = s / (step / n);
		clip._xscale = k * 100;
		clip._yscale = k * 100;
	}
}
