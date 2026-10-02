package drakhan;

class Part extends mt.bumdum.Part {
	public var deathScore:Int;

	public function new(mc:ASprite) {
		super(mc);
	}

	public override function kill():Void {
		if (deathScore != null)
			KadoKadeoManager.kkm.addScore(deathScore);
		super.kill();
	}
}
