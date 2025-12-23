package kado;

typedef ApiResponse<T> = {
	data:T,
};

typedef ContractResponse = {
	run_id:String,
	server_time:Int,
	contract_score:Int,
	contract_points:Int,
	seed:String,
};

class Api {
	public static var baseUrl:String = "http://kadokadeo.localhost";

	public static function buildClient(url:String = null) {
		var http = new haxe.Http(baseUrl + url);

		http.setHeader("Content-Type", "application/json");
		http.setHeader("Accept", "application/json");
		http.setHeader("Authorization", "Bearer " + js.Browser.window.localStorage.getItem("kado:token"));

		return http;
	}

	public static function askContract(onData:Dynamic->Void, onError:Dynamic->Void) {
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
}
