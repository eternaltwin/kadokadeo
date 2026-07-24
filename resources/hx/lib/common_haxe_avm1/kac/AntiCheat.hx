package common_haxe_avm1.kac;

class AntiCheat {
	public static inline var PROTECTED_INT_CORRUPTED:Int = 0x1;

	static var mask:Int = 0;
	static var seed:Int = 0x6D2B79F5;
	static var counter:Int = 0;

	public static function reset():Void {
		mask = 0;
	}

	public static function flag(code:Int):Void {
		mask |= code;
	}

	public static inline function getMask():Int {
		return mask;
	}

	public static function getPayload():Dynamic {
		return mask;
	}

	public static function nextKey():Int {
		counter++;
		seed ^= seed << 13;
		seed ^= seed >>> 17;
		seed ^= seed << 5;
		return mix(seed, counter, 0x45D9F3B);
	}

	public static inline function mix(a:Int, b:Int, c:Int):Int {
		var h = a;
		h ^= b + 0x9E3779B9 + (h << 6) + (h >>> 2);
		h ^= c + 0x85EBCA6B + (h << 6) + (h >>> 2);
		return h;
	}
}
