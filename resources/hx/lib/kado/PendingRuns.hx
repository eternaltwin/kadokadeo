package kado;

// Runs that could not be sent to the server, kept in the local storage (to see why, and to send them again later from
// the site: resources/js/stores/pendingRuns.js reads the same key).
class PendingRuns {
	public static inline var STORAGE_KEY = "kado:pendingRuns";

	// false when the browser refused to store it (storage full or disabled)
	public static function save(run:Dto.PendingRunDTO):Bool {
		try {
			var storage = js.Browser.window.localStorage;
			var runs = load().filter(r -> r.run_id != run.run_id);
			runs.push(run);
			storage.setItem(STORAGE_KEY, haxe.Json.stringify(runs));
			return true;
		} catch (e:Dynamic) {
			trace('Unable to store the run: ' + Std.string(e));
			return false;
		}
	}

	static function load():Array<Dto.PendingRunDTO> {
		try {
			var raw = js.Browser.window.localStorage.getItem(STORAGE_KEY);
			var runs:Dynamic = raw == null ? null : haxe.Json.parse(raw);
			return Std.isOfType(runs, Array) ? cast runs : [];
		} catch (_:Dynamic) {
			return [];
		}
	}
}
