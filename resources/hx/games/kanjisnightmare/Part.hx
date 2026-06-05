package kanjisnightmare;

import common_haxe_avm1.KKApi;
import kado.KadoKadeoManager;
import pixi.core.textures.RenderTexture;

class Part extends Phys {
	public var outMargin:Float;

	public var flPlatCol:Bool;

	public var deathScore:Int;

	public var bmp:RenderTexture;

	public function new(mc) {
		super(mc);
		fadeLimit = 10;
		scale = 100;
	}

	public override function setScale(sc) {
		scale = sc;
	}

	public override function update() {
		super.update();
		if (outMargin != null && isOut2(outMargin)) {
			kill();
		}

		if (flPlatCol)
			checkPlatCol();
	}

	public override function land(pl) {
		vy *= -1;
		vr *= -Seed.randVfx() * 1.5;
	}

	public override function kill() {
		if (bmp != null)
			bmp.destroy(true);
		if (deathScore != null)
			KadoKadeoManager.kkm.addScore(deathScore);
		super.kill();
	}
}
