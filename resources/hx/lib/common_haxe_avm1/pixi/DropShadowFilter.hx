package common_haxe_avm1.pixi;

import pixi.core.renderers.webgl.filters.Filter;

typedef DropShadowOptions = {
	@:optional var rotation:Float;
	@:optional var distance:Float;
	@:optional var color:Int;
	@:optional var alpha:Float;
	@:optional var shadowOnly:Bool;
	@:optional var blur:Float;
	@:optional var quality:Float;
	@:optional var kernels:Array<Float>;
	@:optional var pixelSize:Float;
	@:optional var resolution:Float;
}

@:native("PIXI.filters.DropShadowFilter")
extern class DropShadowFilter extends Filter {
	public function new(options:DropShadowOptions);
}
