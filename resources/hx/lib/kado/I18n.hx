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

	#if js
	// window.Kado.i18n is filled before the bundle is imported: a text read by a static is translated too
	public static function translated(catalogName:String, key:String, french:Null<String>):Null<String> {
		var translation:Dynamic = js.Syntax.code("globalThis.Kado?.i18n?.[{0}]?.[{1}]", catalogName, key);
		return Std.isOfType(translation, String) && translation != "" ? translation : french;
	}

	public static function plural(catalogName:String, key:String, count:Int, frenchOne:Null<String>, frenchOther:String):String {
		var singular = isSingular(count) ? translated(catalogName, '${key}.one', frenchOne) : null;
		var text = singular != null ? singular : translated(catalogName, '${key}.other', frenchOther);
		return format(text, {count: count});
	}

	static function isSingular(count:Int):Bool {
		return js.Syntax.code("new Intl.PluralRules(globalThis.Kado?.locale ?? 'fr').select({0}) === 'one'", count);
	}
	#end
}
