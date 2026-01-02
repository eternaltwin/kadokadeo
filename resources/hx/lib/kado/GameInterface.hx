package kado;

interface GameInterface {
	public function start():Void;
	public function stop():Void;
	public function update(delta:Float):Void;
	public function updateGraphics(alpha:Float):Void;
}
