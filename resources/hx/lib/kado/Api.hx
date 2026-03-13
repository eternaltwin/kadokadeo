package kado;

import js.lib.Promise;

class Api {
	public static var baseUrl:String = "http://kadokadeo.localhost";

	public static function buildClient(url:String = null) {
		var http = new haxe.Http(baseUrl + url);

		http.setHeader("Content-Type", "application/json");
		http.setHeader("Accept", "application/json");
		http.setHeader("Authorization", "Bearer " + js.Browser.window.localStorage.getItem("kado:token"));

		return http;
	}

	public static function askContract(onData:Dto.ApiResponse<Dto.RunDTO>->Void, onError:Dynamic->Void) {
		var req = {};
		var gameId = 4;
		var http = buildClient("/api/runs/games/" + gameId);
		// if (arguments.has('daily')):
		//     req.daily = true
		http.setPostData(haxe.Json.stringify(req));

		http.onData = function(data:String) {
			var result = haxe.Json.parse(data);

			onData(result);
		}

		http.onError = function(error) {
			onError(error);
		}

		http.request(true);
	}

	public static function endRun(runId:String, request:Dto.EndRunRequestDTO):Promise<Dto.ApiResponse<Dynamic>> {
		return new Promise((resolve, reject) -> {
			var http = buildClient("/api/runs/" + runId + "/finish");

			http.setPostData(haxe.Json.stringify(request));

			http.onData = function(data:String) {
				var result = haxe.Json.parse(data);

				resolve(result);
			}

			http.onError = function(error) {
				reject(error);
			}

			http.request(true);
		});
	}
}
