package paradice;

// ScoreBubble.mt of the original: the points of a group, in a wobbling bubble
class ScoreBubble extends Part {
	static var TEXTCOLOR = [0x81E842, 0xBAAAF0, 0xF7BA91, 0x96C6F3, 0xF1F081];

	var field:Txt;
	var bubble:Clip;
	var cx:Float;

	var sc:Float;
	var dec:Float;
	var ec:Float;
	var decSpeed:Float;

	public function new(mc:MC) {
		Cs.game.sbList.push(this);
		super(mc);
		// the text field "field" of mcScoreBubble, drawn with the glyphs of its font (Impact, embedded)
		field = new Txt(Data.BUBBLE_FIELD, Clip.K * root.clip.def.r);
		root.clip.addChild(field);
		bubble = root.sub("bubble");
		cx = 1;

		sc = 10;
		dec = Seed.randVfx() * 628;
		decSpeed = 81;

		ec = 30;
	}

	override public function update() {
		super.update();

		sc = Math.min(Math.pow(sc * 2, Timer.tmod), 100);
		dec = (dec + decSpeed * Timer.tmod) % 628;

		decSpeed *= Math.pow(0.9, Timer.tmod);
		ec *= Math.pow(0.95, Timer.tmod);

		bubble._xscale = (100 + Math.cos(dec * 0.01) * ec) * cx;
		bubble._yscale = 100 + Math.sin(dec * 0.01) * ec;
	}

	public function setScore(sc:Int, col:Int) {
		field.setColor(TEXTCOLOR[col]);
		field.setText(Std.string(sc));
		var w = field.textWidth + 24;
		cx = w / 32;
		// bubble._width = w
		bubble._xscale = w / Data.BUBBLE_W * 100;
	}

	override public function kill() {
		Cs.game.sbList.remove(this);
		super.kill();
	}
}
