package ironchouquette;

import mt.DepthManager;

class Inter {
	public var dm:DepthManager;
	public var root:ASprite;
	public var h:Hero;

	public var ico:{ > ASprite, wheel:ASprite}

	public function new(mc) {
		root = mc;
		dm = new DepthManager(root);
		root._x = Cs.mcw;
	}

	public function update() {
		if (h.secondary.selected != null) {
			if (ico == null)
				ico = downcast(dm.attach("mcIcon", 1));

			ico._alpha = (h.secondary.ammo == 0) ? 50 : 100;

			ico.gotoAndStop(Std.string(h.secondary.selected + 1));
			var frame = 1 + Std.int((h.secondary.ammo / 100) * 40);

			ico.wheel.gotoAndStop(Std.string(frame));
		}
	}
}
