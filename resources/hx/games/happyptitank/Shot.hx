package happyptitank;

// @:bind Shot (symbol 158): a shot of the tank
class Shot extends MovieClip {
	public static var TOTAL_FRAMES = 9;
	public static var COLOR = 0;

	public var dx:Float;
	public var dy:Float;
	public var speed:Float;
	public var power:Int;
	public var col1:DisplayObject;

	public function new(vec:Geom._Ptx, color:Int) {
		super(158);
		this.speed = 4.0 * (60 / Timer.wantedFPS);
		this.power = 10;
		this.dx = vec.x;
		this.dy = vec.y;
		ColorSet.setColor(col1, Game.color.getColor(color));
		// port: col1 ('hardlight') is drawn in the pictures of the shot, one per colour
		variant = color % 9;
	}

	public static function nextColor() {
		COLOR = ++COLOR % TOTAL_FRAMES;
	}

	public function update() {
		x += dx * speed * Timer.tmod;
		y += dy * speed * Timer.tmod;
	}
}
