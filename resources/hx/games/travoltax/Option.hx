package travoltax;

import common_haxe_avm1.display.ASprite;
import travoltax.Common.Cs;

class Option {
	public function new() {
		Game.me.options.push(this);
		Game.me.currentOption = this;
	}

	public function update() {}

	function destroyPiece() {
		Game.me.piece.explode();
	}

	// ON
	public function onLine() {}

	// FX
	public function whiteFlash(?flForeground:Bool) {
		var d = Game.DP_BG;
		if (flForeground)
			d = Game.DP_INTER;
		var mc = Game.me.dm.empty(d);
		mc._totalframes = 5;
		mc.play();
		mc.removeOnFrame = 5;
		var g = mc.getGraphics().beginFill(0xFFFFFF, 1).drawRect(0, 0, Cs.mcw, Cs.mch).endFill();
		mc.onFrame.set(1, function() {
			mc._alpha = 1 * 255;
		});
		mc.onFrame.set(2, function() {
			mc._alpha = 0.8 * 255;
		});
		mc.onFrame.set(3, function() {
			mc._alpha = 0.6 * 255;
		});
		mc.onFrame.set(4, function() {
			mc._alpha = 0.4 * 255;
		});
		mc.onFrame.set(5, function() {
			mc._alpha = 0.0 * 255;
		});
	}

	//
	public function kill() {
		Game.me.options.remove(this);
		if (Game.me.currentOption == this)
			Game.me.currentOption = null;
	}

	// {
}
