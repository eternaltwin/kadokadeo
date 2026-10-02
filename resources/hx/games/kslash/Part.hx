package kslash;

// particle of Game.pList (a clip with these fields in the original, moved by Game.updateParts)
class Part {
	public var root:ASprite;

	public var vx:Float;
	public var vy:Float;
	public var vs:Null<Float>;
	public var vr:Null<Float>;
	public var ft:Null<Int>;
	public var weight:Null<Float>;
	public var frict:Null<Float>;
	public var t:Null<Float>;
	public var scale:Float;
	public var wt:Null<Float>;

	public function new(mc:ASprite) {
		root = mc;
		vx = 0;
		vy = 0;
		frict = 0.95;
		scale = 100;
	}
}
