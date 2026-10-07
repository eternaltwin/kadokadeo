package happyptitank;

// @:bind ArmorBit (symbol 93)
class ArmorBit extends MovieClip {
	public function new() {
		super(93, true);
	}
}

// tank_fla.OptTimer_54 (symbol 97): the ticks around the option of the interface
class OptTimer extends MovieClip {
	public var _t1:DisplayObject;
	public var _t2:DisplayObject;
	public var _t3:DisplayObject;
	public var _t4:DisplayObject;
	public var _t5:DisplayObject;
	public var _t6:DisplayObject;
	public var _t7:DisplayObject;
	public var _t8:DisplayObject;
	public var _t9:DisplayObject;
	public var _t10:DisplayObject;
	public var _t11:DisplayObject;

	public function new() {
		super(97);
	}
}

// @:bind UserInterface (symbol 110)
class UserInterface extends MovieClip {
	var warningBorder:DisplayObject;

	public var level:TextField;
	public var timebg:DisplayObject;
	public var time:TextField;
	public var score:TextField;
	public var optTimer:OptTimer;

	var option:Option;
	var ticks:Array<DisplayObject>;
	var armorBits:Array<ArmorBit>;

	public function new() {
		super(110, true);
		score.text = "";
		optTimer.visible = false;
		option = null;
		ticks = [
			optTimer._t1, optTimer._t2, optTimer._t3, optTimer._t4, optTimer._t5, optTimer._t6, optTimer._t7, optTimer._t8, optTimer._t9,
			optTimer._t10, optTimer._t11
		];
		armorBits = new Array();
		for (i in 0...KKApi.val(Game.instance.armor)) {
			var bit = new ArmorBit();
			bit.y = 2;
			bit.x = Game.W - (bit.width + 2) * (i + 1);
			armorBits.push(bit);
			addChild(bit);
		}
		warningBorder.visible = false;
		timebg.visible = false;
		time.visible = false;
	}

	public function enableTime() {
		timebg.visible = true;
		time.visible = true;
	}

	public function updateArmorBits() {
		var i = 0;
		for (b in armorBits)
			b.visible = ++i <= KKApi.val(Game.instance.armor);
	}

	public function gotOption(opt:Option) {
		if (option != null) {
			optTimer.removeChild(option);
		}
		optTimer.visible = true;
		for (t in ticks)
			t.visible = true;
		optTimer.addChild(opt);
		opt.x = 0;
		opt.y = -2;
		option = opt;
	}

	public function update(now:Float) {
		warningBorder.visible = Game.instance.warZone.visible;
		if (option != null && Game.instance.activeOption == null) {
			optTimer.removeChild(option);
			option = null;
			optTimer.visible = false;
		} else if (option != null) {
			var duration = option.time;
			var done = now - option.start;
			var perTick = duration / (ticks.length + 1);
			var nticks = Math.floor((duration - done) / perTick);
			for (i in 0...ticks.length)
				ticks[i].visible = i < nticks;
		}
	}
}
