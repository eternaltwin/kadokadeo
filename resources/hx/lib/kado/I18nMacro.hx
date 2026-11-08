package kado;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

// Generates the texts of a class from a JSON catalog, French compiled in the bundle:
// a field by text, a function when the text has variables. A key missing from the catalog does not compile.
class I18nMacro {
	public static function build(file:String):Array<Field> {
		var position = Context.currentPos();
		var fields = Context.getBuildFields();
		var catalog = readCatalog(file, position);
		for (key in Reflect.fields(catalog)) {
			fields.push(textField(key, Reflect.field(catalog, key), file, position));
		}
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

	static function textField(key:String, text:Dynamic, file:String, position:Position):Field {
		if (!~/^[A-Za-z_][A-Za-z0-9_]*$/.match(key)) {
			Context.fatalError('${file}: the key ${key} cannot be a field', position);
		}
		if (!Std.isOfType(text, String)) {
			Context.fatalError('${file}: the key ${key} is not a text', position);
		}
		var variables = I18n.variablesOf(text);
		return {
			name: key,
			pos: position,
			access: [APublic, AStatic],
			kind: variables.length == 0 ? FVar(macro :String, macro $v{(text : String)}) : FFun({
				args: [{name: "values", type: TAnonymous(variables.map(variable -> variableField(variable, position)))}],
				ret: macro :String,
				expr: macro return kado.I18n.format($v{(text : String)}, values),
			}),
		};
	}

	static function variableField(name:String, position:Position):Field {
		return {name: name, pos: position, kind: FVar(macro :Dynamic)};
	}
}
#end
