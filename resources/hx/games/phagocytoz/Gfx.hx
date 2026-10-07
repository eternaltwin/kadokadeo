package phagocytoz;

// the classes of gfx.swf bound to its symbols (SymbolClass): their timelines (Data) and named children. A class
// bound to a symbol placed by a timeline is created by MovieClip.create through `factories`.
class Gfx {
	public static var factories:Map<Int, Void->MovieClip> = [
		31 => () -> new McPhase(),
		14 => () -> new GfxScore(),
	];
}

class McCell extends MovieClip {
	public var env:MovieClip;
	public var noyau:MovieClip;

	public function new() {
		super(48);
	}
}

class McTitle extends MovieClip {
	public var phase:McPhase;

	public function new() {
		super(35);
	}
}

class McPhase extends MovieClip {
	public var field:MovieClip.TextField;

	public function new() {
		super(31);
	}
}

class McScore extends MovieClip {
	public var gfx:GfxScore;

	public function new() {
		super(15);
	}
}

class GfxScore extends MovieClip {
	public var field:MovieClip.TextField;

	public function new() {
		super(14);
	}
}

class McMicroCell extends MovieClip {
	public function new() {
		super(28);
	}
}

class McArrow extends MovieClip {
	public function new() {
		super(11);
	}
}
