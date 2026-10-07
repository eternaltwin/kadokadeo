package phagocytoz;

// mt.DepthManager (libs-haxe2, flash9): each plan is an invisible marker in the root's children, an object added to a
// plan goes just under its marker (over the objects already in the plan)
class DepthManager {
	var root:Sprite;
	var plans:Array<DisplayObject>;
	var baseChildren:Int;

	public function new(r:Sprite) {
		root = r;
		baseChildren = root.numChildren;
		plans = [];
	}

	public function getPlan(n:Int):DisplayObject {
		var pmc = plans[n];
		if (pmc != null)
			return pmc;
		pmc = new Marker("Plan#" + n);
		root.addChildAt(pmc, getBottom(n));
		plans[n] = pmc;
		return pmc;
	}

	function getBottom(plan:Int):Int {
		var n = plan;
		while (--n >= 0) {
			var mc = plans[n];
			if (mc != null)
				return root.getChildIndex(mc) + 1;
		}
		return baseChildren;
	}

	// an empty MovieClip in this plan
	public function empty(plan:Int):MovieClip {
		var mc = new MovieClip(-1);
		root.addChildAt(mc, root.getChildIndex(getPlan(plan)));
		return mc;
	}

	public function add<T:DisplayObject>(mc:T, plan:Int):T {
		if (mc.parent != null)
			mc.parent.removeChild(mc);
		root.addChildAt(mc, root.getChildIndex(getPlan(plan)));
		return mc;
	}
}
