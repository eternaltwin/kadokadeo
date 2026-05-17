package travoltax;

import common_haxe_avm1.display.ASprite;
import mt.bumdum.Lib;

class Square {
	public var type:Int;
	public var color:Int;
	public var root:ASprite;

	public function new(mc:ASprite, ?type:Int, ?color:Int) {
		// if(color == 0)color = Std.random(0xFFFFFF);
		root = mc;
		this.type = type;
		this.color = color;

		initSkin(root);
	}

	public function update() {}

	public function initSkin(mc:ASprite) {
		mc.gotoAndStop(type + 1);
		// mc.smc.gotoAndStop(color+1);
		Col.setPercentColor(mc, 30, color);
	}

	public function kill() {
		root.removeMovieClip();
	}
}
// COL
// REVOIR LES LUCIOLES
