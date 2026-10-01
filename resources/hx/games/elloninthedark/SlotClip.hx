package elloninthedark;

typedef SlotDef = {name:String, anim:Bool, ?frames:Array<Array<Float>>};
typedef SlotClipDef = {total:Int, slots:Array<SlotDef>};

// Flash clip whose frame is set by the code (or by its own timeline) while its nested clips keep playing.
// The clip is split in layers by the asset pipeline (see Data):
//  - static layers: one texture for each frame of the clip
//  - animated layers: independent looping animations placed on each frame of the clip by a table
//    ([x, y, scaleX, scaleY, rotation, skewX, skewY, alpha], null when the nested clip is not on that frame).
//    Like in Flash, a nested clip restarts from its first frame when it appears again.
class SlotClip extends ASprite {
	var def:SlotClipDef;
	var slots:Array<ASprite>;
	var present:Array<Bool>;
	var age:Array<Int>;
	var scaleAnims:Array<Array<Array<Float>>>;

	// rename: animation to use for some layers (variants chosen by the code, like the speed broom)
	public function new(def:SlotClipDef, ?rename:Map<String, String>) {
		super();
		this.def = def;
		_totalframes = def.total;
		loop = true;
		slots = [];
		present = [];
		age = [];
		scaleAnims = [];
		for (i in 0...def.slots.length) {
			var sd = def.slots[i];
			var name = sd.name;
			if (rename != null && rename.exists(name))
				name = rename.get(name);
			var mc = attachMovie(name, sd.name, i);
			mc.stop();
			if (sd.anim) {
				mc.loop = true;
				mc._visible = false;
			}
			slots.push(mc);
			present.push(false);
			age.push(0);
			scaleAnims.push(null);
		}
		gotoAndStop(1);
	}

	public function attachTo(parent:ASprite, depth:Int) {
		parent.addChild(this);
		_zIndex = depth;
		zsort();
		return this;
	}

	// nested scale timeline of an animated layer (a tween that is not baked in its textures): [scaleX, scaleY] per frame
	public function setScaleAnim(name:String, table:Array<Array<Float>>) {
		for (i in 0...slots.length)
			if (def.slots[i].name == name) {
				scaleAnims[i] = table;
				if (present[i])
					placeSlot(i);
			}
	}

	public function getSlot(name:String):ASprite {
		for (i in 0...slots.length)
			if (def.slots[i].name == name)
				return slots[i];
		return null;
	}

	override public function update() {
		for (i in 0...slots.length)
			if (present[i])
				age[i]++;
		super.update();
		for (i in 0...slots.length)
			if (present[i] && scaleAnims[i] != null)
				placeSlot(i);
	}

	override function showFrame() {
		showLayers();

		// timeline actions
		if (stopOnFrame.contains(_currentframe))
			stop();
		if (removeOnFrame == _currentframe) {
			stop();
			removeMovieClip();
		}
		if (onFrame.exists(_currentframe))
			onFrame.get(_currentframe)();
	}

	function showLayers() {
		for (i in 0...slots.length) {
			var sd = def.slots[i];
			var mc = slots[i];
			if (!sd.anim) {
				mc.gotoAndStop(_currentframe);
				continue;
			}
			if (sd.frames[_currentframe - 1] == null) {
				present[i] = false;
				mc._visible = false;
				mc.stop();
				continue;
			}
			var appear = !present[i];
			if (appear) {
				present[i] = true;
				age[i] = 0;
				mc._visible = true;
				mc.gotoAndPlay(1);
			}
			placeSlot(i);
			if (appear)
				mc.updateState();
		}
	}

	function placeSlot(i:Int) {
		var r = def.slots[i].frames[_currentframe - 1];
		var mc = slots[i];
		var sx = r[2];
		var sy = r[3];
		var sa = scaleAnims[i];
		if (sa != null) {
			var s = sa[age[i] % sa.length];
			sx *= s[0];
			sy *= s[1];
		}
		mc._x = r[0];
		mc._y = r[1];
		mc._xscale = sx * 100;
		mc._yscale = sy * 100;
		mc._rotation = r[4];
		mc.skew.set(r[5], r[6]);
		mc._alpha = r[7] * 100;
	}
}
