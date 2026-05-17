package mt.bumdum;

import common_haxe_avm1.display.ASprite;
import pixi.filters.colormatrix.ColorMatrixFilter;

class Plasma extends Bmp {
	static var list:Array<Plasma> = [];

	public var timer:Float = null;
	public var timerLife:Float = null;

	public var filters:Array<Dynamic>;

	public var ct:ColorMatrixFilter;

	public function new(mc:ASprite, ?w:Int, ?h:Int, ?q:Float) {
		super(mc, w, h, true, 0, q);
		list.push(this);
		this.filters = [];
	}

	static public function updateAll() {
		for (i in list)
			i.update();
	}

	override public function kill() {
		list.remove(this);
		super.kill();
	}

	override public function update() {
		if (this.ct != null) {
			this.applyFilterToSelf(this.ct);
		}

		if (filters != null) {
			for (i in filters) {
				this.applyFilterToSelf(i);
			}
		}

		if (this.timer != null) {
			this.timer -= mt.Timer.tmod;
			if (this.timer < this.timerLife) {
				var progress = this.timer / this.timerLife;
				this.root._alpha = progress * 100;
				if (this.timer <= 0) {
					this.kill();
				}
			}
		}

		if (this.root._visible == null) {
			this.kill();
		}
	}
}
