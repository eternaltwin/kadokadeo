package happyptitank;

// @:bind ColorSet (symbol 86): the original draws the symbol into a bitmap and reads the colour of its squares
// (getPixel(5 + 10 n, 5)): Data.PALETTE, read in the SWF by the exporter
class ColorSet {
	static var NBR = 9;

	public function new() {}

	// (the colours only change pictures: the tank, the ground: visual random)
	public function random():Int {
		return getColor(Seed.randomVfx(NBR));
	}

	public function getColor(index:Int):Int {
		var n = index % NBR;
		return Data.PALETTE[n];
	}

	// port: the index of a colour of the palette (the pictures baked per colour)
	public static function indexOf(c:Int):Int {
		return Data.PALETTE.indexOf(c);
	}

	public static function setColor(mc:DisplayObject, c:Int) {
		mc.setColor(c);
	}
}
