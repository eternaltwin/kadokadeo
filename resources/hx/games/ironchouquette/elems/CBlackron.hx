package ironchouquette.elems;

// frame 2
class CBlackron extends Bads {
	public var react1:ASprite;
	public var react2:ASprite;

	public function new() {
		var root = Cs.game.dm.attach("blackronBody", Game.DP_BADS);
		super(root);
		react1 = root.attachMovie("badReact");
		react2 = root.attachMovie("badReact");
		react1.loop = true;
		react1.play();
		react2.loop = true;
		react2.play();

		react1._x = -16 * Cs.NEW_GEN_SCALE;
		react1._y = 2 * Cs.NEW_GEN_SCALE;
		react2._x = 12 * Cs.NEW_GEN_SCALE;
		react2._y = 2 * Cs.NEW_GEN_SCALE;

		setLevel(2.5);
		setScore(Cs.C_BLACKRON);

		hp = 2;
		setSkin(2);
	}
}
