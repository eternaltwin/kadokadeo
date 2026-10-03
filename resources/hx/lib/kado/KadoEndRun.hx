package kado;

import js.lib.Promise;

typedef KadoConfig = {
	var public_key:String;
}

class KadoEndRun {
	public function new() {}

	public static function buildRequest(runDetails:Dto.RunDTO, score:Int, timestamp:Int, replayData:String, data:Dynamic, ac:Dynamic):Null<Dto.EndRunPlainDTO> {
		if (runDetails == null || runDetails.run_id == null || runDetails.run_id == "") {
			return null;
		}
		return {
			run_id: runDetails.run_id,
			score: score,
			timestamp: timestamp,
			replay: replayData,
			data: data,
			ac: ac,
		};
	}

	// The RSA keys of the server change with each deployment: a page opened before it encrypts with an old key. When the
	// run is refused, the key is asked again and, if it changed, the run is sent once more with the new one.
	// Rejected with a Dto.ApiError.
	public function submit(request:Dto.EndRunPlainDTO):Promise<Dto.EndRunResponseDTO> {
		var usedKey = getPublicKey();
		return send(request, usedKey).catchError((error:Dynamic) -> {
			return Api.getPublicKey().then((res:Dto.ApiResponse<Dto.PublicKeyDTO>) -> {
				var serverKey = res.data == null ? null : res.data.public_key;
				if (serverKey == null || serverKey == "" || sameKey(serverKey, usedKey)) {
					return cast Promise.reject(error);
				}
				trace("Server public key changed, sending the run again");
				setPublicKey(serverKey);
				return send(request, serverKey);
			}, (_) -> cast Promise.reject(error));
		});
	}

	function send(request:Dto.EndRunPlainDTO, publicKey:String):Promise<Dto.EndRunResponseDTO> {
		if (publicKey == null || publicKey == "") {
			return cast Promise.reject(Api.toError("Missing Kado public key"));
		}

		var jse = new externs.JSEncrypt();
		jse.setPublicKey(publicKey);

		var jsonReq = haxe.Json.stringify(request);
		#if debug
		trace('Prepared end run request: ' + jsonReq);
		#end

		// a new AES key for each request
		var crypto = new KadoCrypto();
		var payload = crypto.preparePayload(jsonReq);
		var keyB64 = haxe.crypto.Base64.encode(crypto.getKey());
		var encryptedKey:Dynamic = jse.encrypt(keyB64);
		if (!Std.isOfType(encryptedKey, String)) {
			return cast Promise.reject(Api.toError("Unable to encrypt request key"));
		}

		var encryptedKeyString:String = cast encryptedKey;
		if (encryptedKeyString.length == 0) {
			return cast Promise.reject(Api.toError("Encrypted request key is empty"));
		}

		var body:Dto.EndRunRequestDTO = {
			payload: haxe.crypto.Base64.encode(payload),
			key: encryptedKeyString,
			sign: haxe.crypto.Base64.encode(crypto.getHmacSha256(haxe.io.Bytes.ofString(jsonReq))),
		};

		return Api.endRun(request.run_id, body).then((data:Dto.ApiResponse<Dto.EndRunResponseDTO>) -> {
			return data.data;
		}).catchError((error:Dynamic) -> {
			var apiError = Api.toError(error);
			trace('Error ending run: ' + apiError.status + ' ' + apiError.message);
			return cast Promise.reject(apiError);
		});
	}

	static function getPublicKey():String {
		var kado:KadoConfig = cast untyped js.Browser.window.Kado;
		return kado == null ? null : kado.public_key;
	}

	static function setPublicKey(key:String):Void {
		var win:Dynamic = js.Browser.window;
		if (win.Kado == null) {
			win.Kado = {};
		}
		win.Kado.public_key = key;
	}

	static function sameKey(a:String, b:String):Bool {
		if (a == null || b == null) {
			return false;
		}
		return StringTools.trim(StringTools.replace(a, "\r", "")) == StringTools.trim(StringTools.replace(b, "\r", ""));
	}
}
