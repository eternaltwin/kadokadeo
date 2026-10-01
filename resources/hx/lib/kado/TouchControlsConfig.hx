package kado;

enum abstract TouchControlsMode(String) from String to String {
	var NONE = "none";
	var KEYBOARD = "keyboard";
	var JOYSTICK = "joystick";
}

enum abstract TouchButtonShape(String) from String to String {
	var CIRCLE = "circle";
	var SQUARE = "square";
}

typedef TouchButtonConfig = {
	var id:String;
	var label:String;
	@:optional var leftPx:Float;
	@:optional var rightPx:Float;
	@:optional var topPx:Float;
	@:optional var bottomPx:Float;
	@:optional var size:Float;
	@:optional var keyCode:Int;
	@:optional var action:String;
	@:optional var invisible:Bool;
	@:optional var shape:TouchButtonShape;
}

typedef TouchJoystickConfig = {
	// rest position (fraction of the screen)
	@:optional var x:Float;
	@:optional var y:Float;
	@:optional var radius:Float;
	@:optional var deadZone:Float;
	// the joystick appears under the finger, anywhere on the left half of the screen
	@:optional var dynamicCenter:Bool;
	// the joystick follows the finger when it goes past the edge (default: true with dynamicCenter)
	@:optional var follow:Bool;
	// digital directions given in TouchJoystickState.dirX / dirY: 8 (default) or 4
	@:optional var directions:Int;
}

typedef TouchSwipeConfig = {
	@:optional var leftAction:String;
	@:optional var rightAction:String;
	@:optional var upAction:String;
	@:optional var downAction:String;
	@:optional var minDistance:Float;
	@:optional var maxDurationMs:Float;
}

typedef TouchControlsConfig = {
	var mode:TouchControlsMode;
	@:optional var buttons:Array<TouchButtonConfig>;
	@:optional var joystick:TouchJoystickConfig;
	@:optional var swipe:TouchSwipeConfig;
}
