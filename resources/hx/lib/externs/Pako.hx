package externs;

import js.lib.Uint8Array;

@:js.import("pako", "default")
extern class Pako {
	public static function deflate(data:Uint8Array, ?options:Dynamic):Uint8Array;
	public static function inflate(data:Uint8Array):Uint8Array;
}
