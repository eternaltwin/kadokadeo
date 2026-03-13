package kado;

import common_haxe_avm1.display.ASprite;
import pixi.core.textures.Texture;
import pixi.core.sprites.Sprite;

class BottomBar extends ASprite {
	var kkm:KadoKadeoManager;
	var bb:Sprite;

	var contractText:pixi.core.text.Text;
	var digitSprites:Array<Sprite> = [];

	public function new(kkm:KadoKadeoManager) {
		super();
		this.kkm = kkm;

		this.makeBottomBar();
		this.initDigitSprites();
		this.updateScore(0);
	}

	public function makeBottomBar():Void {
		bb = Sprite.from("bottom_bar.png");
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

		var kadoIcon = Sprite.from("kado_icon.png");
		kadoIcon.anchor.set(0.5);
		kadoIcon.x = 100;
		kadoIcon.y = 40;
		kadoIcon.width = 40;
		kadoIcon.height = 40;
		bb.addChild(kadoIcon);
	}

	public function updateScore(score:Int):Void {
		var paddedScore = Std.string(score);
		// pad with zeros to ensure it has at least 7 digits
		while (paddedScore.length < 7) {
			paddedScore = "0" + paddedScore;
		}

		for (i in 0...paddedScore.length) {
			var sprite = digitSprites[i];
			sprite.texture = this.textures[Std.parseInt(paddedScore.charAt(i))];
		}
	}

	private function initDigitSprites():Void {
		for (i in 0...10) {
			textures.push(Texture.from("score/figure_" + i + ".svg"));
		}
		for (i in 0...7) {
			var digitSprite = Sprite.from("score/figure_0.svg");
			digitSprite.x = 550 + i * 43;
			digitSprite.y = 65;
			digitSprites.push(digitSprite);
			bb.addChild(digitSprite);
		}
	}
}
