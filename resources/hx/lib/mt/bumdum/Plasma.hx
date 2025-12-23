package mt.bumdum;

import pixi.filters.colormatrix.ColorMatrixFilter;

class Plasma extends Bmp {
	static var list:Array<Plasma> = [];

	var timer:Float = null;
	var timerLife:Float = null;

	var filters:Array<Dynamic>;

	var ct:ColorMatrixFilter;

	public function new(arg0, arg1, arg2, arg3) {
		super(arg0, arg1, arg2, true, 0, arg3);
		list.push(this);
		this.filters = null;
	}

	static public function updateAll() {
		for (i in list)
			i.update();
	}

	override public function kill() {
		list.remove(this);
		destroy();
	}

	override public function update() {
		if (this.ct != null) {
			trace('FIXME CT NOT IMPLEMENTED');
			// this.colorTransform(this.rectangle, this.ct);
		}

		for (i in filters) {
			trace('FIXME PLASMA FILTERS NOT IMPLEMENTED');
			// this.applyFilter(this, this.rectangle, new flash.geom.Point(0, 0), i);
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
