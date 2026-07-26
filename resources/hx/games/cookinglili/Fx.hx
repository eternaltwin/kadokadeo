package cookinglili;

class Fx {
	var game:Game;

	public var mc:ASprite;

	public function new(g) {
		game = g;
	}

	public function destroy() {
		mc.removeMovieClip();
		mc = null;
	}

	public function update() {}
}
