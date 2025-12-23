package mt;

import haxe.Json;
import js.lib.Function;
import haxe.ds.StringMap;

@:expose("MtCodec")
class PersistCodec {
	/*
		TYPE-BITS =

		- number
			Int 	00
			float	010
			NaN		0110
			+Inf	01110
			-Inf	01111

		- array		100
		- object	101
		- Boolean
			true	1101
			false	1100

		- String	1110

		- undefined 1111

		DATA =

		- Int
			normal	NN [XX|XX|XX]  : 2 bits + 2-6 bits
			medium	1100 + 16 bits
			big		1101 + 32 bits
			negatif 111 + Int

		- float
			as a String with :
			String length	5
			character		4
				number 0-9
				dot     10
				plus    11
				minus   12
				exp     13

		- array
			element	0
			jump	10 + Int
			end		11

		- object
			key
				0 + index
				10 + String
			end
				11

		- String
			extended	11
			ASCII		10
			B64			0
			len			Int
			chars		 7/8


	 */
	public var obfu_mode:Bool;
	public var bc:BitCodec;
	public var fields:haxe.ds.StringMap<Int>;
	public var fieldtbl:Array<String>;
	public var nfields:Int;
	public var next_field_bits:Int;
	public var nfields_bits:Int;
	public var cache:Array<Dynamic>;
	public var result:Dynamic;
	public var fast:Bool;
	public var crc:Bool;

	public function new() {
		obfu_mode = false;
		crc = false;
	}

	public function encode_array(a) {
		var i;
		var njumps = 0;
		for (i in 0...a.length) {
			if (a[i] == null)
				njumps++;
			else {
				if (njumps > 0) {
					bc.write(2, 2);
					encode_Int(njumps);
					njumps = 0;
				}
				bc.write(1, 0);
				do_encode(a[i]);
			}
		}
		bc.write(2, 3);
	}

	public function decode_array() {
		var a = [];
		cache.unshift(a);
		return a;
	}

	public function decode_array_item(a) {
		var elt = (bc.read(1) == 0);
		if (elt)
			a.push(do_decode());
		else {
			var exit = (bc.read(1) == 1);
			if (exit)
				return false;

			for (i in 0...decode_Int()) {
				a.push(null);
			}
		}
		return true;
	}

	public function decode_array_fast() {
		var a = [];
		var pos = 0;
		while (true) {
			var elt = (bc.read(1) == 0);
			if (elt)
				a.push(do_decode());
			else {
				var exit = (bc.read(1) == 1);
				if (exit)
					break;
				for (i in 0...decode_Int()) {
					a.push(null);
				}
			}
			if (bc.error_flag)
				break;
		}
		return a;
	}

	public function encode_String(s:String) {
		var is_b64 = true;
		var is_ascii = true;
		var i;
		for (i in 0...s.length) {
			if (s.charCodeAt(i) > 127) {
				is_b64 = false;
				is_ascii = false;
				break;
			} else if (is_b64) {
				var c = s.charCodeAt(i);
				if (BitCodec.d64(c) == null)
					is_b64 = false;
			}
		}
		encode_Int(s.length);
		if (is_b64) {
			bc.write(1, 0);
			for (i in 0...s.length)
				bc.write(6, BitCodec.d64(s.charCodeAt(i)));
		} else {
			bc.write(2, is_ascii ? 2 : 3);
			for (i in 0...s.length)
				bc.write(is_ascii ? 7 : 8, s.charCodeAt(i));
		}
	}

	public function decode_String() {
		var len = decode_Int();
		var is_b64 = (bc.read(1) == 0);
		var s = "";
		var i;
		if (is_b64) {
			for (i in 0...len)
				s += BitCodec.c64(bc.read(6));
		} else {
			var is_ascii = (bc.read(1) == 0);
			for (i in 0...len)
				s += BitCodec.chr(bc.read(is_ascii ? 7 : 8));
		}
		return s;
	}

	public function encode_object(o:Dynamic) {
		for (k in Reflect.fields(o)) {
			encode_object_field(k, Reflect.field(o, k));
		}
		bc.write(2, 3);
	}

	public function encode_object_field(k:String, d:Dynamic) {
		if (!Std.isOfType(d, Function) && d != null) {
			if (obfu_mode && k.charAt(0) == "$")
				k = k.substr(1);
			if (fields.get(k) != null) {
				bc.write(1, 0);
				bc.write(nfields_bits, fields.get(k));
			} else {
				fields.set(k, nfields++);
				if (nfields >= next_field_bits) {
					nfields_bits++;
					next_field_bits *= 2;
				}
				bc.write(2, 2);
				encode_String(k);
			}
			do_encode(d);
		}
	}

	public function decode_object_fast() {
		var o:Dynamic = {};
		while (true) {
			var k;
			var is_field_index = (bc.read(1) == 0);
			if (is_field_index)
				k = fieldtbl[bc.read(nfields_bits)];
			else {
				var is_end = (bc.read(1) == 1);
				if (is_end)
					break;
				k = decode_String();
				if (obfu_mode && k.charAt(0) != "$")
					k = "$" + k;
				fieldtbl[nfields++] = k;
				if (nfields >= next_field_bits) {
					nfields_bits++;
					next_field_bits *= 2;
				}
			}
			Reflect.setField(o, k, do_decode());
			if (bc.error_flag)
				break;
		}
		return o;
	}

	public function decode_object() {
		var o = {};
		cache.unshift(o);
		return o;
	}

	public function decode_object_field(o) {
		var k;
		var is_field_index = (bc.read(1) == 0);

		if (is_field_index)
			k = fieldtbl[bc.read(nfields_bits)];
		else {
			var is_end = (bc.read(1) == 1);
			if (is_end)
				return false;
			k = decode_String();
			if (obfu_mode && k.charAt(0) != "$")
				k = "$" + k;
			fieldtbl[nfields++] = k;
			if (nfields >= next_field_bits) {
				nfields_bits++;
				next_field_bits *= 2;
			}
		}
		Reflect.setField(o, k, do_decode());
		return true;
	}

	public function encode_Int(o:Int) {
		if (o < 0) {
			bc.write(3, 7);
			encode_Int(-o);
		} else if (o < 4) {
			bc.write(2, 0);
			bc.write(2, o);
		} else if (o < 16) {
			bc.write(2, 1);
			bc.write(4, o);
		} else if (o < 64) {
			bc.write(2, 2);
			bc.write(6, o);
		} else if (o < 65536) {
			bc.write(4, 12);
			bc.write(16, o);
		} else {
			bc.write(4, 13);
			bc.write(16, o & 0xFFFF);
			bc.write(16, (o >> 16) & 0xFFFF);
		}
	}

	public function decode_Int() {
		var nbits = bc.read(2);
		if (nbits == 3) {
			var is_neg = (bc.read(1) == 1);
			if (is_neg)
				return -decode_Int();
			var is_big = (bc.read(1) == 1);
			if (is_big) {
				var n = bc.read(16);
				var n2 = bc.read(16);
				return n | (n2 << 16);
			} else
				return bc.read(16);
		}
		var i = bc.read((nbits + 1) * 2);
		return i;
	}

	public function encode_float(o) {
		var s = Std.string(o);
		var l = s.length;
		var i;
		bc.write(5, l);
		for (i in 0...l) {
			var c = s.charCodeAt(i);
			if (c >= 48 && c <= 58) // 0 - 9
				bc.write(4, c - 48);
			else if (c == 46) // '.'
				bc.write(4, 10);
			else if (c == 43) // '+'
				bc.write(4, 11);
			else if (c == 45) // '-'
				bc.write(4, 12);
			else // 'e'
				bc.write(4, 13);
		}
	}

	public function decode_float() {
		var l = bc.read(5);
		var i;
		var s = "";
		for (i in 0...l) {
			var k = bc.read(4);
			if (k < 10)
				k += 48;
			else
				switch (k) {
					case 10:
						k = 46;
					case 11:
						k = 43;
					case 12:
						k = 45;
					default:
						k = 101;
				}
			s += String.fromCharCode(k);
		}
		return Std.parseFloat(s);
	}

	public function do_encode(o:Dynamic):Bool {
		if (o == null)
			bc.write(4, 15);
		else if (Std.isOfType(o, Array)) {
			bc.write(3, 4);
			encode_array(o);
		} else
			switch (js.Lib.typeof(o)) {
				case "string":
					bc.write(4, 14);
					encode_String(o);
				case "number":
					var n:Dynamic = o;
					if (Math.isNaN(n))
						bc.write(4, 6);
					else if (Std.parseInt(n) == n) {
						bc.write(2, 0);
						encode_Int(n);
					} else {
						bc.write(3, 2);
						encode_float(n);
					}
				case "boolean":
					if (o == true)
						bc.write(4, 13);
					else
						bc.write(4, 12);
				default:
					bc.write(3, 5);
					encode_object(o);
			}
		return true;
	}

	public function do_decode():Dynamic {
		var is_number = (bc.read(1) == 0);
		if (is_number) {
			var is_float = (bc.read(1) == 1);
			if (is_float) {
				var is_special = (bc.read(1) == 1);
				if (is_special) {
					var is_infinity = (bc.read(1) == 1);
					if (is_infinity) {
						var is_negative = (bc.read(1) == 1);
						if (is_negative)
							return 0;
						else
							return 0;
					} else
						return 0 * null; // NaN
				} else
					return decode_float();
			} else
				return decode_Int();
		}
		var is_array_obj = (bc.read(1) == 0);
		if (is_array_obj) {
			var is_obj = (bc.read(1) == 1);
			if (is_obj)
				return (fast ? decode_object_fast() : decode_object());
			else
				return (fast ? decode_array_fast() : decode_array());
		}
		var tflag = bc.read(2);
		if (tflag == 0)
			return false;
		else if (tflag == 1)
			return true;
		else if (tflag == 2)
			return decode_String();
		else
			return null;
	}

	public function encodeInit(o) {
		fast = false;
		bc = new BitCodec();
		fields = new StringMap();
		nfields = 0;
		next_field_bits = 1;
		nfields_bits = 0;
		cache = [];
		cache.push(o);
	}

	public function encodeLoop() {
		if (cache.length == 0)
			return true;
		do_encode(cache.shift());
		return false;
	}

	public function encodeEnd() {
		var s = bc.toString();
		if (crc)
			s += bc.crcStr();
		return s;
	}

	public function encode(o:Dynamic) {
		encodeInit(o);
		fast = true;
		while (encodeLoop()) {}
		return encodeEnd();
	}

	public function progress() {
		return bc.in_pos * 100 / bc.data.length;
	}

	public function decodeInit(data) {
		fast = false;
		bc = new BitCodec();
		bc.setData(data);
		fieldtbl = [];
		nfields = 0;
		next_field_bits = 1;
		nfields_bits = 0;
		cache = [];
		result = null;
	}

	public function decodeLoop() {
		if (cache.length == 0)
			result = do_decode();
		else {
			var o = cache[0];
			if (Std.isOfType(o, Array)) {
				if (!decode_array_item(o))
					cache.shift();
			} else {
				if (!decode_object_field(o)) {
					Reflect.deleteField(o, "pos");
					cache.shift();
				}
			}
		}
		if (bc.error_flag) {
			result = null;
			return false;
		}
		return (cache.length != 0);
	}

	public function decodeEnd() {
		if (crc) {
			var s = bc.crcStr();
			var s2 = bc.data.substr(bc.in_pos, 4);
			if (s != s2)
				return null;
		}
		return result;
	}

	public function decode(data) {
		decodeInit(data);
		// fast = true;
		while (decodeLoop()) {}
		return decodeEnd();
	}
}

class BitCodec {
	public var error_flag:Bool;
	public var nbits:Int;
	public var bits:Int;
	public var data:String;
	public var in_pos:Int;
	public var crc:Int;

	public function new() {
		setData("");
	}

	public function crcStr() {
		return c64(crc & 63) + c64((crc >> 6) & 63) + c64((crc >> 12) & 63) + c64((crc >> 18) & 63);
	}

	public function setData(d) {
		error_flag = false;
		data = d;
		in_pos = 0;
		nbits = 0;
		bits = 0;
		crc = 0;
	}

	public function read(n) {
		while (nbits < n) {
			var c:Int = d64(data.charCodeAt(in_pos++));
			if (in_pos > data.length || c == null) {
				error_flag = true;
				return -1;
			}
			crc ^= c;
			crc &= 0xFFFFFF;
			crc *= c;
			nbits += 6;
			bits <<= 6;
			bits |= c;
		}
		nbits -= n;
		return (bits >> nbits) & ((1 << n) - 1);
	}

	public function nextPart() {
		nbits = 0;
	}

	public function hasError() {
		return error_flag;
	}

	public function toString() {
		if (nbits > 0)
			write(6 - nbits, 0);
		return data;
	}

	public function write(n, b) {
		nbits += n;
		bits <<= n;
		bits |= b;
		var k;
		while (nbits >= 6) {
			nbits -= 6;
			k = (bits >> nbits) & 63;
			crc ^= k;
			crc &= 0xFFFFFF;
			crc *= k;
			data += c64(k);
		}
	}

	public static function ord(code:String) {
		return code.charCodeAt(0);
	}

	public static function chr(code:Int) {
		return String.fromCharCode(code);
	}

	public static function d64(code:Int):Int {
		var chars = "$azAZ_"; // anti obfu
		if (code >= chars.charCodeAt(1) && code <= chars.charCodeAt(2))
			return code - ord(chars.charAt(1));
		if (code >= chars.charCodeAt(3) && code <= chars.charCodeAt(4))
			return code - ord(chars.charAt(3)) + 26;
		if (code >= "0".code && code <= "9".code)
			return code - ord("0") + 52;
		if (code == "-".code)
			return 62;
		if (code == chars.charCodeAt(5))
			return 63;
		return null;
	}

	public static function c64(code) {
		var chars = "$aA_"; // anti obfu
		if (code < 0)
			return "?";
		if (code < 26)
			return chr(code + ord(chars.charAt(1)));
		if (code < 52)
			return chr((code - 26) + ord(chars.charAt(2)));
		if (code < 62)
			return chr((code - 52) + ord("0"));
		if (code == 62)
			return "-";
		if (code == 63)
			return chars.charAt(3);
		return "?";
	}
}
