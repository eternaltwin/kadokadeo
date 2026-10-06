package klinkersurprise;

// mcGenerator (scale size %): frame 1 unlit, frame 2 lit; its smc is coloured by Col.setColor(smc, COLOR[type]) and
// drawn "add". The pictures are rendered at the size of the zone (gen<size>, and gsm<size>_<frame> with one frame per
// colour: setColor is an offset, not a tint, see klinkersurprise_assets.py): the clip is a container at scale 1 whose
// _xscale is the size of the original
class GeneratorMC extends MC {
	var size:Int;
	var base:MC;
	var smc:MC;
	var color:Int = 0;

	public function new(size:Int) {
		// (_xscale = size shows the container at scale 1: its pictures already have the size)
		super(null, size / 100);
		this.size = size;
		base = attach(new MC("gen" + size));
		smc = attach(new MC("gsm" + size + "_1"));
		_totalframes = 2;
		show();
	}

	// Col.setColor(smc, COLOR[type]) + smc.blendMode = "add" (the smc of the frame shown)
	public function setColor(type:Int):Void {
		color = type;
		smc.setAdd();
		show();
	}

	override public function gotoAndStop(f:Int):Void {
		super.gotoAndStop(f);
		show();
	}

	function show():Void {
		base.gotoAndStop(_currentframe);
		smc.setFrames("gsm" + size + "_" + _currentframe);
		smc.gotoAndStop(color + 1);
	}
}

class Generator extends Rel {
	public var px:Int;
	public var py:Int;
	public var type:Int;

	public function new(mc:GeneratorMC, t:Int) {
		super(mc);
		Game.me.generators.push(this);
		type = t;
		setScale(Game.me.size);
		relPoint = Game.me.selector;
		mc.setColor(type);
		mc.stop();
	}

	override public function update():Void {
		super.update();
	}

	public function light():Void {
		root.gotoAndStop(2);
		(cast root : GeneratorMC).setColor(type);
	}

	public function unlight():Void {
		root.gotoAndStop(1);
		(cast root : GeneratorMC).setColor(type);
	}

	public function setPos(nx:Int, ny:Int):Void {
		px = nx;
		py = ny;
		x = px * Game.me.size;
		y = py * Game.me.size;
	}

	override public function kill():Void {
		Game.me.generators.remove(this);
		super.kill();
	}
}
