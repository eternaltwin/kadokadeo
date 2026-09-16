package alchimie2;

import alchimie2.GameData.ArtefactId;

class McQuantitySprite extends ASprite {
	public var _field:Text;
}

class ObjectMc {
	public var id:ArtefactId;
	public var infos:Array<Dynamic>;
	public var pdm:mt.DepthManager;
	public var dp:Int;

	var gTimer:Float;

	public var mc:ASprite;
	public var mcQty:McQuantitySprite;

	var q:Int;

	var loaded:Int;

	public var f:Void->Void;

	public function new(o:ArtefactId, d:mt.DepthManager, dp:Int, ?fPost:Void->Void, ?qty:Int) {
		this.infos = getInfos(o);
		id = o;

		this.pdm = d;
		this.dp = dp;
		this.f = fPost;
		this.q = qty;

		loadData();
	}

	public function setQuantity(q:Int) {
		if (mcQty == null)
			initMcQty();
		mcQty._field.text = Std.string(q);
	}

	function initMcQty() {
		mcQty = cast this.mc.attachMovie("mcQty", "mcQty_", 2);
		mcQty._x = KadoKadeoManager.I(-17);
		mcQty._y = KadoKadeoManager.I(13);
	}

	function loadData() {
		mc = pdm.attach(infos[0], dp);
		// mc.getGraphics()
		// 	.beginFill(0x009933, 0.4)
		// 	.drawRect(0, 0, Cs.ELEMENT_SIZE, Cs.ELEMENT_SIZE)
		// 	.endFill();
		mc._x = 0;
		mc._y = KadoKadeoManager.I(-60);

		if (infos.length > 1) {
			mc.gotoAndStop(infos[1]);
		}

		if (q != null)
			setQuantity(q);

		if (f != null)
			f();
	}

	public function set(ids:Array<Dynamic>) {
		this.infos = ids;
		var oldX = mc._x;
		var oldY = mc._y;
		mc.destroy();
		mc = pdm.attach(infos[0], Cs.DP_STAGE);
		mc._x = oldX;
		mc._y = oldY;
		if (infos.length > 1) {
			mc.gotoAndStop(infos[1]);
		}
	}

	public function update() {
		if (gTimer == null)
			return;

		gTimer += 0.06;
		var f = Math.sin(gTimer);

		if (f < -0.9) {
			gTimer = 0.0;
			f = 0.0;
		}

		// mc.smc.smc.smc.smc._alpha = Math.max(0.0, f * 100);
		mc._alpha = Math.max(0.0, f * 100);
	}

	public function kill() {
		if (mc != null)
			mc.removeMovieClip();
	}

	static public function getInfos(o:ArtefactId):Array<Dynamic> {
		switch (o) {
			case Elt(e):
				return ["element", e + 1];
			// artefacts
			case Alchimoth:
				return ["art_alchimoth"];
			case Dynamit(v):
				return ["art_dynamit", v + 1];
			case PearGrain(level):
				return ["art_pear", level + 1];
			case Grenade(level):
				return ["art_grenade", level + 1];
			// auto falls
			case Block(level):
				return ["art_enforced", level];
			case Neutral:
				return ["art_neutral", 1];

			// #################UNUSED FOR OBJECTMC (ONLY HERE FOR COMPILATION CHECK)
			case Elts(e, p):
				return null;
		}
	}
}
