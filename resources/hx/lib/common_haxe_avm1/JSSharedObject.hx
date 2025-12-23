package common_haxe_avm1;

import haxe.Json;
import js.Browser;
import haxe.ds.StringMap;

class JSSharedObject {
	static var sharedObjects:StringMap<JSSharedObject> = new StringMap();

	public var data:Dynamic;
	public var name:String;

	public function new(name:String) {
		this.name = name;

		var existing = Browser.window.localStorage.getItem(name);
		if (existing != null) {
			this.data = Json.parse(existing);
		} else {
			this.data = {};
		}
	}

	public function flush() {
		Browser.window.localStorage.setItem(name, Json.stringify(data));
	}

	static public function getLocal(name:String):Dynamic {
		if (sharedObjects.exists(name))
			return sharedObjects.get(name);

		var o = new JSSharedObject(name);
		sharedObjects.set(name, o);
		return o;
	}
}
