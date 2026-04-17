package starfang;

import mt.DepthManager;

class IcoSprite extends ASprite {
	public var wheel:ASprite;
}

class Inter {
	var dm:DepthManager;
	var root:ASprite;

	public var h:Hero;

	var ico:IcoSprite;

	public function new(mc) {
		root = mc;
		dm = new DepthManager(root);
		root._x = Cs.mcw;
	}

	public function update() {
		if (h.secSelected != null) {
			if (ico == null) {
				ico = cast dm.attach("mcIcon", 1);
				ico.wheel = ico.attachMovie("wheel", "wheel", 1);
			}

			ico._alpha = (h.secAmmo == 0) ? 50 : 100;

			ico.gotoAndStop(h.secSelected + 1);
			var frame = 1 + Std.int((h.secAmmo / 100) * 40);

			ico.wheel.gotoAndStop(frame);
		}
	}
}
