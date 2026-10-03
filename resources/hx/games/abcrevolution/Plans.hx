package abcrevolution;

// DepthManager of the original (a clip attached on a plan goes over the others of its plan): one container per plan,
// in the order of the plans.
class Plans {
	var root:ASprite;
	var plans:Array<ASprite>;

	public function new(root:ASprite) {
		this.root = root;
		plans = [];
	}

	public function plan(p:Int):ASprite {
		var mc = plans[p];
		if (mc == null) {
			mc = root.createEmptyMovieClip("plan" + p, p);
			plans[p] = mc;
		}
		return mc;
	}

	public function add<T:ASprite>(mc:T, p:Int):T {
		plan(p).addChild(mc);
		return mc;
	}

	public function empty(p:Int):ASprite {
		return add(new ASprite(), p);
	}

	// a clip of the game's sheet, playing
	public function attach(anim:String, p:Int):Mc {
		return add(new Mc(anim), p);
	}

	// DepthManager.under: to the bottom of its plan
	public function under(mc:ASprite) {
		var par = mc.parent;
		if (par != null)
			par.setChildIndex(mc, 0);
	}

	public function clear(p:Int) {
		var mc = plans[p];
		if (mc == null)
			return;
		for (c in mc.children.copy())
			if (Std.isOfType(c, ASprite))
				(cast c : ASprite).removeMovieClip();
			else
				mc.removeChild(c);
	}
}
