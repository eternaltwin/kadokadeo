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
}

typedef TouchJoystickConfig = {
	@:optional var x:Float;
	@:optional var y:Float;
	@:optional var radius:Float;
	@:optional var deadZone:Float;
	@:optional var dynamicCenter:Bool;
}

typedef TouchControlsConfig = {
	var mode:TouchControlsMode;
	@:optional var buttons:Array<TouchButtonConfig>;
	@:optional var joystick:TouchJoystickConfig;
}
