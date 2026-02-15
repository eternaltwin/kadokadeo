package kado;

import pixi.core.graphics.Graphics;
import pixi.core.display.Container;
import pixi.core.sprites.Sprite;

class BottomBar extends Container {
	var kkm:KadoKadeoManager;

	var contractText:pixi.core.text.Text;

	public function new(kkm:KadoKadeoManager) {
		super();
		this.kkm = kkm;

		this.makeBottomBar();
	}

	public function makeBottomBar():Void {
		var bb = new Sprite(kkm.loader.resources["bottom_bar"].texture);
		bb.x = 0;
		bb.y = kkm.renderer.height - 68;
		this.addChild(bb);

		contractText = new pixi.core.text.Text("20", {
			fill: 0x206c7f,
			fontFamily: 'Fredoka Bold',
			fontSize: 40,
			align: 'left',
		});
		contractText.anchor.set(0.5);
		contractText.x = 40;
		contractText.y = 38;
		bb.addChild(contractText);

		var kadoIcon = new Sprite(kkm.loader.resources["kado_icon"].texture);
		kadoIcon.anchor.set(0.5);
		kadoIcon.x = 100;
		kadoIcon.y = 40;
		kadoIcon.width = 40;
		kadoIcon.height = 40;
		bb.addChild(kadoIcon);

		var testscore = new Sprite(kkm.loader.resources["score_figure_2"].texture);
		testscore.anchor.set(0.5);
		testscore.x = 800;
		testscore.y = 40;
		testscore.scale.set(0.1);
		bb.addChild(testscore);
	}
}
