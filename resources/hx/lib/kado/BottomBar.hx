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
		var bb = new Sprite(kkm.loader.resources["/assets/img/content/default/bottom_bar.png"].texture);
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

        var kadoIcon = new Sprite(kkm.loader.resources["/assets/img/content/default/kado_icon.png"].texture);
        kadoIcon.anchor.set(0.5);
        kadoIcon.x = 100;
        kadoIcon.y = 40;
        kadoIcon.width = 40;
        kadoIcon.height = 40;
        bb.addChild(kadoIcon);
	}
}
