package loader;

import flash.Boot;

public final class Step {
	public static var __isenum:Boolean = true;
	public static var __constructs__ :Array<String> = ["Load","Slide","Play"];

	public static var Slide:Step;

	public static var Play:Step;

	public static var Load:Step;

	public var tag:String;

	public var index:int;

	public var params:Array;

	public var __enum__:Boolean = true;
	public function new(tag:String, index:int, params: *) {
		tag = tag;
		index = index;
		params = params;
	}

	final public function toString():String {
		return Boot.enum_to_string(this);
	}
}
Step.Load = new Step("Load",0,null);
Step.Play = new Step("Play",2,null);
Step.Slide = new Step("Slide",1,null);
Step.__constructs__ = ["Load","Slide","Play"];
