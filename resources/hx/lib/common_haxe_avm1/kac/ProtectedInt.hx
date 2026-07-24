package common_haxe_avm1.kac;

private class ProtectedIntData {
	var encoded:Int;
	var key:Int;
	var mirror:Int;
	var checksum:Int;
	var salt:Int;

	public function new(v:Int) {
		salt = AntiCheat.nextKey();
		set(v);
	}

	public function get():Int {
		if (!valid()) {
			AntiCheat.flag(AntiCheat.PROTECTED_INT_CORRUPTED);
		}

		return encoded ^ key;
	}

	public function set(v:Int):Void {
		key = AntiCheat.nextKey();
		encoded = v ^ key;
		mirror = ~v;
		checksum = computeChecksum();
	}

	function valid():Bool {
		var v = encoded ^ key;
		return mirror == ~v && checksum == computeChecksum();
	}

	function computeChecksum():Int {
		return AntiCheat.mix(encoded, key, salt) ^ mirror;
	}
}

abstract ProtectedInt(ProtectedIntData) {
	public inline function new(v:Int = 0) {
		this = new ProtectedIntData(v);
	}

	@:from
	public static inline function fromInt(v:Int):ProtectedInt {
		return new ProtectedInt(v);
	}

	@:to
	public inline function toInt():Int {
		return this.get();
	}

	public inline function get():Int {
		return this.get();
	}

	public inline function set(v:Int):Void {
		this.set(v);
	}

	@:op(A + B)
	public static inline function add(a:ProtectedInt, b:ProtectedInt):ProtectedInt {
		return new ProtectedInt(a.toInt() + b.toInt());
	}

	@:op(A - B)
	public static inline function sub(a:ProtectedInt, b:ProtectedInt):ProtectedInt {
		return new ProtectedInt(a.toInt() - b.toInt());
	}

	@:op(A * B)
	public static inline function mul(a:ProtectedInt, b:ProtectedInt):ProtectedInt {
		return new ProtectedInt(a.toInt() * b.toInt());
	}

	@:op(A / B)
	public static inline function div(a:ProtectedInt, b:ProtectedInt):Float {
		return a.toInt() / b.toInt();
	}

	@:op(A % B)
	public static inline function mod(a:ProtectedInt, b:ProtectedInt):ProtectedInt {
		return new ProtectedInt(a.toInt() % b.toInt());
	}

	@:op(A & B)
	public static inline function and(a:ProtectedInt, b:ProtectedInt):ProtectedInt {
		return new ProtectedInt(a.toInt() & b.toInt());
	}

	@:op(A | B)
	public static inline function or(a:ProtectedInt, b:ProtectedInt):ProtectedInt {
		return new ProtectedInt(a.toInt() | b.toInt());
	}

	@:op(A ^ B)
	public static inline function xor(a:ProtectedInt, b:ProtectedInt):ProtectedInt {
		return new ProtectedInt(a.toInt() ^ b.toInt());
	}

	@:op(A << B)
	public static inline function shl(a:ProtectedInt, b:Int):ProtectedInt {
		return new ProtectedInt(a.toInt() << b);
	}

	@:op(A >> B)
	public static inline function shr(a:ProtectedInt, b:Int):ProtectedInt {
		return new ProtectedInt(a.toInt() >> b);
	}

	@:op(A >>> B)
	public static inline function ushr(a:ProtectedInt, b:Int):ProtectedInt {
		return new ProtectedInt(a.toInt() >>> b);
	}

	@:op(-A)
	public static inline function neg(a:ProtectedInt):ProtectedInt {
		return new ProtectedInt(-a.toInt());
	}

	@:op(~A)
	public static inline function bitNot(a:ProtectedInt):ProtectedInt {
		return new ProtectedInt(~a.toInt());
	}

	@:op(A == B)
	public static inline function eq(a:ProtectedInt, b:ProtectedInt):Bool {
		return a.toInt() == b.toInt();
	}

	@:op(A != B)
	public static inline function neq(a:ProtectedInt, b:ProtectedInt):Bool {
		return a.toInt() != b.toInt();
	}

	@:op(A > B)
	public static inline function gt(a:ProtectedInt, b:ProtectedInt):Bool {
		return a.toInt() > b.toInt();
	}

	@:op(A >= B)
	public static inline function gte(a:ProtectedInt, b:ProtectedInt):Bool {
		return a.toInt() >= b.toInt();
	}

	@:op(A < B)
	public static inline function lt(a:ProtectedInt, b:ProtectedInt):Bool {
		return a.toInt() < b.toInt();
	}

	@:op(A <= B)
	public static inline function lte(a:ProtectedInt, b:ProtectedInt):Bool {
		return a.toInt() <= b.toInt();
	}

	public inline function toString():String {
		return Std.string(toInt());
	}
}
