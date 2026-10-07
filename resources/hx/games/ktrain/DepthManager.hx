package ktrain;

import ktrain.MC.Holder;

typedef Plan = {tbl:Array<MC>, cur:Int};

/**
 * mt.DepthManager of Flash 8 (libs-haxe2, as compiled in the released game.swf): plan n holds the depths n * 1000 to
 * n * 1000 + 999, given in attach order; a clip removed keeps its slot until the plan is compacted (at 1000 slots, or
 * by `under`). ysort sorts the slots by _y with swapDepths, and a removed clip in the way keeps Flash's behaviour: its
 * _y is undefined (every comparison fails), and swapDepths with it does nothing, so the slots and the depths stop
 * matching (the objects pasted into the ground and removed at once leave such slots in the plan of the obstacles).
 */
class DepthManager {
	var root:Holder;
	var plans:Array<Plan>;

	public function new(root:Holder) {
		this.root = root;
		plans = [];
	}

	function getPlan(pnb:Int):Plan {
		var p = plans[pnb];
		if (p == null) {
			p = {tbl: [], cur: 0};
			plans[pnb] = p;
		}
		return p;
	}

	static inline function alive(mc:MC):Bool {
		return mc != null && !mc.removed;
	}

	public function compact(plan:Int) {
		var pd = plans[plan];
		var p = pd.tbl;
		var cur = 0;
		var base = plan * 1000;
		for (i in 0...pd.cur)
			if (alive(p[i])) {
				p[i].swapDepths(base + cur);
				p[cur] = p[i];
				cur++;
			}
		pd.cur = cur;
	}

	public function attach(inst:String, plan:Int):MC {
		var pd = getPlan(plan);
		var p = pd.tbl;
		var d = pd.cur;
		if (d == 1000) {
			compact(plan);
			return attach(inst, plan);
		}
		var mc = root.attachMovie(inst, d + plan * 1000);
		p[d] = mc;
		pd.cur = d + 1;
		return mc;
	}

	public function empty(plan:Int):MC {
		var pd = getPlan(plan);
		var p = pd.tbl;
		var d = pd.cur;
		if (d == 1000) {
			compact(plan);
			return empty(plan);
		}
		var mc = root.createEmptyMovieClip(d + plan * 1000);
		p[d] = mc;
		pd.cur = d + 1;
		return mc;
	}

	public function under(mc:MC) {
		var d = mc.getDepth();
		if (d == null)
			return;
		var plan = Math.floor(d / 1000);
		var pd = getPlan(plan);
		var p = pd.tbl;
		var i = d % 1000;
		if (p[i] == mc) {
			p[i] = null;
			p.unshift(mc);
			pd.cur++;
			compact(plan);
		}
	}

	public function over(mc:MC) {
		var d = mc.getDepth();
		if (d == null)
			return;
		var plan = Math.floor(d / 1000);
		var pd = getPlan(plan);
		var p = pd.tbl;
		var i = d % 1000;
		if (p[i] == mc) {
			p[i] = null;
			if (pd.cur == 1000)
				compact(plan);
			d = pd.cur;
			pd.cur++;
			mc.swapDepths(d + plan * 1000);
			p[d] = mc;
		}
	}

	// (compiled form: `if (mcy < y)` insert, else y = mcy: an undefined _y takes the else branch, NaN, and every
	// comparison with it fails)
	public function ysort(plan:Int) {
		var pd = getPlan(plan);
		var p = pd.tbl;
		var len = pd.cur;
		var y:Float = -99999999;
		for (i in 0...len) {
			var mc = p[i];
			var mcy = alive(mc) ? mc._y : Math.NaN;
			if (mcy < y) {
				var j = i;
				while (j > 0) {
					var mc2 = p[j - 1];
					var y2 = alive(mc2) ? mc2._y : Math.NaN;
					if (y2 <= mcy) {
						p[j] = mc;
						break;
					}
					p[j] = mc2;
					if (mc != null)
						mc.swapWith(mc2);
					j--;
				}
				if (j == 0)
					p[0] = mc;
			} else {
				y = mcy;
			}
		}
	}
}
