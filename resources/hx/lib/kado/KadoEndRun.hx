package kado;

import js.lib.Promise;

typedef KadoConfig = {
	var public_key:String;
}

class KadoEndRun {
	var crypto:KadoCrypto;

	public function new(crypto:KadoCrypto) {
		this.crypto = crypto;
	}

	public function submit(runDetails:Dto.RunDTO, score:Int, timestamp:Int, replayData:String):Promise<Dto.EndRunResponseDTO> {
		if (runDetails == null || runDetails.run_id == null || runDetails.run_id == "") {
			return cast Promise.reject("Missing run details");
		}

		var win:Dynamic = js.Browser.window;
		var kado:KadoConfig = cast win.Kado;
		if (kado == null || kado.public_key == null || kado.public_key == "") {
			return cast Promise.reject("Missing Kado public key");
		}

		var jse = new externs.JSEncrypt();
		jse.setPublicKey(kado.public_key);

		var req = {
			run_id: runDetails.run_id,
			score: score,
			timestamp: timestamp,
			replay: replayData,
		};
		var jsonReq = haxe.Json.stringify(req);
		trace('Prepared end run request: ' + jsonReq);

		var payload = crypto.preparePayload(jsonReq);
		var keyHex = crypto.getKey().toHex();
		if ((keyHex.length & 1) == 1) {
			return cast Promise.reject("Invalid symmetric key hex length");
		}

		var encryptedKey:Dynamic = jse.encrypt(keyHex);
		if (!Std.isOfType(encryptedKey, String)) {
			return cast Promise.reject("Unable to encrypt request key");
		}

		var encryptedKeyString:String = cast encryptedKey;
		if (encryptedKeyString.length == 0) {
			return cast Promise.reject("Encrypted request key is empty");
		}

		var request:Dto.EndRunRequestDTO = {
			payload: haxe.crypto.Base64.encode(payload),
			key: encryptedKeyString,
			sign: haxe.crypto.Base64.encode(crypto.getHmacSha256(haxe.io.Bytes.ofString(jsonReq))),
		};

		return Api.endRun(runDetails.run_id, request).then((data:Dto.ApiResponse<Dto.EndRunResponseDTO>) -> {
			return data.data;
		}).catchError((error) -> {
			var message:String = Reflect.hasField(error, "message") ? Std.string(Reflect.field(error, "message")) : Std.string(error);
			trace('Error ending run: ' + message);
			return Promise.reject(error);
		});
	}
}
