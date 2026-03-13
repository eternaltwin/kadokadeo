package mt;

import pixi.core.textures.Texture;
import common_haxe_avm1.display.ASprite;

class DepthManager {
	static var INST_COUNTER = 0;

	public var root_mc:ASprite;

	var plans:Array<{tbl:Array<ASprite>, cur:Int}>;

	public function new(mc:ASprite) {
		root_mc = mc;
		plans = new Array();
	}

	public function getMC() {
		return root_mc;
	}

	function getPlan(pnb) {
		var plan_data = plans[pnb];
		if (plan_data == null) {
			plan_data = {tbl: new Array(), cur: 0};
			plans[pnb] = plan_data;
		}
		return plan_data;
	}

	public function compact(plan:Int) {
		var plan_data = plans[plan];
		if (plan_data == null)
			return;

		var p = plan_data.tbl;
		var cur = 0;
		var base = plan * 1000;
		for (i in 0...plan_data.cur)
			if (p[i] != null && p[i]._name != null) {
				p[i].swapDepths(base + cur);
				p[cur] = p[i];
				cur++;
			}
		plan_data.cur = cur;
	}

	public function attach(inst:String, plan:Int):ASprite {
		var plan_data = getPlan(plan);
		var p = plan_data.tbl;
		var d = plan_data.cur;
		if (d == 1000) {
			compact(plan);
			return attach(inst, plan);
		}
		var iname = inst + "@" + (INST_COUNTER++);
		var mc = root_mc.attachMovie(inst, iname, d + plan * 1000);
		p[d] = mc;
		plan_data.cur = d + 1;
		return mc;
	}

	public function attachBitmap(bmp:Texture, plan:Int) {
		var plan_data = getPlan(plan);
		var p = plan_data.tbl;
		var d = plan_data.cur;
		if (d == 1000) {
			compact(plan);
			attachBitmap(bmp, plan);
			return;
		}
		root_mc.attachBitmap(bmp, d + plan * 1000);
		p[d] = null;
		plan_data.cur = d + 1;
	}

	public function empty(plan:Int):ASprite {
		var plan_data = getPlan(plan);
		var p = plan_data.tbl;
		var d = plan_data.cur;
		if (d == 1000) {
			compact(plan);
			return empty(plan);
		}
		var iname = "empty@" + (INST_COUNTER++);
		var mc = root_mc.createEmptyMovieClip(iname, d + plan * 1000);
		p[d] = mc;
		plan_data.cur = d + 1;
		return mc;
	}

	public function reserve(mc:ASprite, plan:Int):Int {
		var plan_data = getPlan(plan);
		var p = plan_data.tbl;
		var d = plan_data.cur;
		if (d == 1000) {
			compact(plan);
			return reserve(mc, plan);
		}
		p[d] = mc;
		plan_data.cur = d + 1;
		return d + plan * 1000;
	}

	public function swap(mc:ASprite, plan:Int) {
		var src_plan = Math.floor(mc.getDepth() / 1000);
		if (src_plan == plan)
			return;
		var plan_data = getPlan(src_plan);
		var p = plan_data.tbl;
		for (i in 0...plan_data.cur)
			if (p[i] == mc) {
				p[i] = null;
				break;
			}
		mc.swapDepths(reserve(mc, plan));
	}

	public function under(mc:ASprite) {
		var d = mc.getDepth();
		var plan = Math.floor(d / 1000);
		var plan_data = getPlan(plan);
		var p = plan_data.tbl;
		var pd = d % 1000;
		if (p[pd] == mc) {
			p[pd] = null;
			p.unshift(mc);
			plan_data.cur++;
			compact(plan);
		}
	}

	public function over(mc:ASprite) {
		var d = mc.getDepth();
		var plan = Math.floor(d / 1000);
		var plan_data = getPlan(plan);
		var p = plan_data.tbl;
		var pd = d % 1000;
		if (p[pd] == mc) {
			p[pd] = null;
			if (plan_data.cur == 1000)
				compact(plan);
			d = plan_data.cur;
			plan_data.cur++;
			mc.swapDepths(d + plan * 1000);
			p[d] = mc;
		}
	}

	public function clear(plan:Int) {
		var plan_data = getPlan(plan);
		var p = plan_data.tbl;
		for (i in 0...plan_data.cur)
			p[i].removeMovieClip();
		plan_data.cur = 0;
	}

	public function ysort(plan:Int) {
		var plan_data = getPlan(plan);
		var p = plan_data.tbl;
		var len = plan_data.cur;
		var y:Float = -99999999;
		for (i in 0...len) {
			var mc = p[i];
			var mcy = mc._y;
			if (mcy >= y)
				y = mcy;
			else {
				var j = i;
				while (j > 0) {
					var mc2 = p[j - 1];
					if (mc2._y > mcy) {
						p[j] = mc2;
						mc.swapDepths(cast mc2);
					} else {
						p[j] = mc;
						break;
					}
					j--;
				}
				if (j == 0)
					p[0] = mc;
			}
		}
	}

	public function destroy() {
		for (i in 0...plans.length)
			clear(i);
	}
}
