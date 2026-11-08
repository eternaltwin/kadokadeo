package kado;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;

// Generates the texts of a class from its catalog, French compiled in the bundle:
// a field by text, a function when the text has variables or a plural. A key missing from the catalog does not compile.
// A game only names its catalog: where the catalogs are and their format stay here.
class I18nMacro {
	// the other languages are not compiled: they are read at run time, French being what a missing text falls back to
	static inline var FRENCH_CATALOGS = "resources/lang/fr";

	public static function build(catalogName:String):Array<Field> {
		var file = '${FRENCH_CATALOGS}/${catalogName}.json';
		return withTexts(catalogName, readCatalog(file, Context.currentPos()), file);
	}

	// texts written in the class itself: what a test needs
	public static function fromTexts(catalogName:String, texts:Expr):Array<Field> {
		return withTexts(catalogName, ExprTools.getValue(texts), "the texts of the class");
	}

	static function withTexts(catalogName:String, texts:Dynamic, source:String):Array<Field> {
		var position = Context.currentPos();
		var fields = Context.getBuildFields();
		var plurals = new Map<String, {one:Null<String>, other:Null<String>}>();
		var cases:Array<Case> = [];

		for (key in Reflect.fields(texts)) {
			var text:Dynamic = Reflect.field(texts, key);
			if (!Std.isOfType(text, String)) {
				Context.fatalError('${source}: the key ${key} is not a text', position);
			}
			var plural = ~/^(.+)\.(one|other)$/;
			if (plural.match(key)) {
				var forms = plurals.exists(plural.matched(1)) ? plurals.get(plural.matched(1)) : {one: null, other: null};
				Reflect.setField(forms, plural.matched(2), text);
				plurals.set(plural.matched(1), forms);
				continue;
			}
			cases.push({values: [macro $v{key}], expr: translatedExpr(catalogName, key, text)});
			if (~/^[A-Za-z_][A-Za-z0-9_]*$/.match(key)) {
				for (field in textFields(catalogName, key, text, position)) {
					fields.push(field);
				}
			}
		}
		for (name => forms in plurals) {
			fields.push(pluralField(catalogName, name, forms, source, position));
		}
		fields.push(resolveField(cases, position));
		return fields;
	}

	static function readCatalog(file:String, position:Position):Dynamic {
		if (!sys.FileSystem.exists(file)) {
			Context.fatalError('The catalog ${file} does not exist', position);
		}
		Context.registerModuleDependency(Context.getLocalModule(), file);
		try {
			return haxe.Json.parse(sys.io.File.getContent(file));
		} catch (error:Dynamic) {
			return Context.fatalError('The catalog ${file} is not valid JSON: ${error}', position);
		}
	}

	static function translatedExpr(catalogName:String, key:String, french:String):Expr {
		return macro kado.I18n.translated($v{catalogName}, $v{key}, $v{french});
	}

	static function textFields(catalogName:String, key:String, french:String, position:Position):Array<Field> {
		var translated = translatedExpr(catalogName, key, french);
		var variables = I18n.variablesOf(french);
		if (variables.length > 0) {
			return [{
				name: key,
				pos: position,
				access: [APublic, AStatic],
				kind: FFun({
					args: [{name: "values", type: TAnonymous(variables.map(variable -> variableField(variable, position)))}],
					ret: macro :String,
					expr: macro return kado.I18n.format($translated, values),
				}),
			}];
		}
		return [
			{
				name: key,
				pos: position,
				access: [APublic, AStatic],
				kind: FProp("get", "never", macro :String),
			},
			{
				name: 'get_${key}',
				pos: position,
				access: [AStatic],
				kind: FFun({args: [], ret: macro :String, expr: macro return $translated}),
			},
		];
	}

	static function pluralField(catalogName:String, name:String, forms:{one:Null<String>, other:Null<String>}, source:String, position:Position):Field {
		if (forms.other == null) {
			Context.fatalError('${source}: ${name}.one has no ${name}.other', position);
		}
		return {
			name: name,
			pos: position,
			access: [APublic, AStatic],
			kind: FFun({
				args: [{name: "count", type: macro :Int}],
				ret: macro :String,
				expr: macro return kado.I18n.plural($v{catalogName}, $v{name}, count, $v{forms.one}, $v{forms.other}),
			}),
		};
	}

	// a key known at run time only; a key that cannot be a field, like lvl_1&dbl, is read this way
	static function resolveField(cases:Array<Case>, position:Position):Field {
		var unknownKey = macro "#" + key + "#";
		return {
			name: "resolve",
			pos: position,
			access: [APublic, AStatic],
			kind: FFun({
				args: [{name: "key", type: macro :String}],
				ret: macro :String,
				expr: macro return ${{expr: ESwitch(macro key, cases, unknownKey), pos: position}},
			}),
		};
	}

	static function variableField(name:String, position:Position):Field {
		return {name: name, pos: position, kind: FVar(macro :Dynamic)};
	}
}
#end
