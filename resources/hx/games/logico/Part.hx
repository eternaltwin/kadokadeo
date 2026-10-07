package logico;

// mt.bumdum.Part of the original (as compiled): a Phys with behaviours (none used by Logico) and an optional bitmap
// it draws itself into (never set by Logico)
class Part extends Phys {
	public var coef:Float;

	public function new(mc:MC) {
		super(mc);
		coef = 1;
	}
}
