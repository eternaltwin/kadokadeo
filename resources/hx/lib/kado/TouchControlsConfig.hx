package kado;

enum abstract TouchControlsMode(String) from String to String {
	var NONE = "none";
	var KEYBOARD = "keyboard";
	var JOYSTICK = "joystick";
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
}

typedef TouchJoystickConfig = {
	@:optional var x:Float;
	@:optional var y:Float;
	@:optional var radius:Float;
	@:optional var deadZone:Float;
	@:optional var dynamicCenter:Bool;
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
