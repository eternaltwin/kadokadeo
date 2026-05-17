package travoltax.opt;

import travoltax.Game;
import travoltax.Option;
import mt.bumdum.Lib;
import mt.bumdum.Phys;

class Maxi extends Option {
	public function new() {
		super();
		destroyPiece();
		var matrix = [
			[
				1, 1, 1, 1,
				1, 1, 1, 1,
				1, 1, 1, 1,
				1, 1, 1, 1
			],
			[3, 3],
			[0]
		];
		Game.me.pieceList.unshift(matrix);
		kill();
	}

	public override function update() {
		super.update();
	}

	public override function kill() {
		Game.me.initPlay();
		super.kill();
	}
}
