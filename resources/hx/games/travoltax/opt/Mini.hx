package travoltax.opt;

import travoltax.Game;
import travoltax.Option;
import mt.bumdum.Lib;
import mt.bumdum.Phys;

class Mini extends Option {
	public function new() {
		super();
		destroyPiece();
		var matrix = [
			[
				0, 0, 0, 0,
				0, 0, 1, 0,
				0, 0, 0, 0,
				0, 0, 0, 0
			],
			[4, 4],
			[0xFFFFFF]
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
