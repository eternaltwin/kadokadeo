package kado;

// The texts of the games, from resources/lang (kado.I18nMacro): a {name} shows a value
class I18n {
	public static function format(text:String, values:Dynamic):String {
		return variable().map(text, function(found) {
			var name = found.matched(1);
			return Reflect.hasField(values, name) ? Std.string(Reflect.field(values, name)) : found.matched(0);
		});
	}

	public static function variablesOf(text:String):Array<String> {
		var names = [];
		variable().map(text, function(found) {
			var name = found.matched(1);
			if (names.indexOf(name) < 0) {
				names.push(name);
			}
			return "";
		});
		return names;
	}

	static function variable():EReg {
		return ~/\{([A-Za-z_][A-Za-z0-9_]*)\}/g;
	}
}
