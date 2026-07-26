package travoltax.opt;

import kado.Seed;
import mt.bumdum.Sprite;
import pixi.core.math.Matrix;
import common_haxe_avm1.display.ASprite;
import pixi.core.math.Point;
import pixi.core.math.shapes.Rectangle;
import pixi.core.textures.RenderTexture;
import travoltax.Common.Cs;
import travoltax.Common.Step;
import travoltax.Game;
import travoltax.Option;
import mt.bumdum.Lib;
import mt.bumdum.Phys;
import mt.bumdum.Part;

class Cut extends Option { // }
	var bmp:RenderTexture;
	var mcPart:ASprite;
	var mcSlash:ASprite;

	public function new() {
		super();
		Game.me.step = Freeze;
		destroyPiece();

		var sy = null;
		for (y in 0...Cs.YMAX) {
			for (x in 0...Cs.XMAX) {
				if (Game.me.grid[y][x] != null) {
					sy = y;
					break;
				}
			}
			if (sy != null)
				break;
		}

		var ey = Std.int(Math.min(sy + 3, Cs.YMAX));

		for (y in sy...ey)
			Game.me.grid[y] = [];

		// trace(sy+"->"+ey+" /"+Cs.YMAX);

		var w = Std.int(Cs.XMAX * Cs.SIZE);
		var h = Std.int((ey - sy) * Cs.SIZE);

		bmp = RenderTexture.create(w, h);
		var m = new Matrix();

		var rect = new Rectangle(0, sy * Cs.SIZE, w, h);
		bmp.copyPixels(Game.me.board, rect, new pixi.core.math.Point.Point(0, 0));
		Game.me.board.clearRect(rect);

		mcPart = Game.me.dm.empty(Game.DP_PARTS);
		mcPart.attachBitmap(bmp, 0);
		mcPart._x = Cs.MX;
		mcPart._y = Cs.MY + sy * Cs.SIZE;

		// Game.me.piece.checkState();

		mcSlash = Game.me.dm.empty(Game.DP_INTER);
		mcSlash.getGraphics().beginFill(0xFFFFFF, 0.2).drawRect(0, 0, Cs.mcw, Cs.mch).endFill();
		mcSlash.getGraphics()
			.beginFill(0xFFFFFF, 1)
			.drawRect(0, Cs.mch / 4, Cs.mcw, Cs.mch / 2)
			.endFill();
		mcSlash._totalframes = 6;
		mcSlash.removeOnFrame = 6;
		mcSlash.play();
		mcSlash.anchor.set(0, 0.5);
		mcSlash.onFrame.set(1, function() {
			mcSlash._yscale = 1;
		});
		mcSlash.onFrame.set(2, function() {
			mcSlash._yscale = 0.56;
		});
		mcSlash.onFrame.set(3, function() {
			mcSlash._yscale = 0.25;
		});
		mcSlash.onFrame.set(4, function() {
			mcSlash._yscale = 0.06;
		});
		mcSlash.onFrame.set(5, function() {
			mcSlash._yscale = 0.006;
		});
		mcSlash.onFrame.set(6, function() {
			mcSlash._yscale = 0;
		});
		mcSlash._x = 0;
		mcSlash._y = Cs.MY + ey * Cs.SIZE;

		var max = 16;
		for (i in 0...max) {
			var p = new Part(Game.me.dm.attach("partPix", Game.DP_PARTS));
			p.x = Cs.MX + Seed.randVfx() * Cs.XMAX * Cs.SIZE;
			p.y = Cs.MY + ey * Cs.SIZE;
			p.vx = Seed.randVfx() * KadoKadeoManager.I(15);
			p.bhl = [BhHoriLine];
			p.timer = 20 + p.vx / KadoKadeoManager.I(1);
			p.setScale(50);
		}
	}

	public override function update() {
		super.update();
		// mcSlash._x += 50;
		// if (mcSlash != null) {
		// 	return;
		// }

		mcPart._x += KadoKadeoManager.I(1) * mt.Timer.tmod;
		mcPart._y += KadoKadeoManager.S(0.2) * mt.Timer.tmod;
		mcPart._alpha -= KadoKadeoManager.S(2 * mt.Timer.tmod);

		/*
			trace("alpha:"+mcPart._alpha);
			trace(":"+(Game.me.step  == Play));
			trace("me:"+(Game.me.currentOption == this));
		 */

		if (mcPart._alpha < 50 && Game.me.currentOption == this) {
			Game.me.currentOption = null;
			Game.me.initPlay();
		}

		if (mcPart._alpha <= 0) {
			mcPart.removeMovieClip();
			bmp.destroy();
			kill();
		}
	}
}
