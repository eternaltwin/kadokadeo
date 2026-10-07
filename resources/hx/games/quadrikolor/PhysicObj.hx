package quadrikolor;

// PhysicObj.mt
class PhysicObj {
	// user/sim vars
	public var x:Float;
	public var y:Float;
	public var r:Float;
	public var dx:Float;
	public var dy:Float;
	public var mass:Float;

	// for computation
	public var col:Float;
	public var target:PhysicObj;
	public var sx:Float;
	public var sy:Float;

	public function new() {}

	// (the original declared a field `onCollide : PhysicObj -> void`, which Ball defines)
	public function onCollide(trg:PhysicObj):Void {}
}
