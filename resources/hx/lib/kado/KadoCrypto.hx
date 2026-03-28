package kado;

import haxe.io.Bytes;
import haxe.crypto.Aes;
import haxe.crypto.Hmac;
import js.lib.Uint8Array;

class KadoCrypto {
	var key:Bytes;
	var iv:Bytes;
	var aes:Aes;
	var hmacSha256 = new Hmac(SHA256);

	public function new() {
		key = generateRandomBytes(16);
		iv = generateRandomBytes(16);
		aes = new Aes();
		aes.init(key, iv);
	}

	public static function generateRandomBytes(cnt:Int):Bytes {
		var array = new Uint8Array(cnt);
		js.Syntax.code("crypto.getRandomValues({0})", array);

		var bytes = Bytes.ofData(array.buffer);
		return bytes;
	}

	public function getHmacSha256(payload:Bytes):Bytes {
		return hmacSha256.make(key, payload);
	}

	public function preparePayload(data:String):Bytes {
		var text = Bytes.ofString(data);

		// Encrypt
		var data = aes.encrypt(haxe.crypto.mode.Mode.CTR, text, haxe.crypto.padding.Padding.NoPadding);
		var out = Bytes.alloc(iv.length + data.length);

		out.blit(0, iv, 0, iv.length);
		out.blit(iv.length, data, 0, data.length);
		return out;
	}

	public function getKey():Bytes {
		return key;
	}
}
