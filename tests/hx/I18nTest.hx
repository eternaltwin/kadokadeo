// haxe tests/hx/i18n.hxml
import kado.I18n;

@:build(kado.I18nMacro.fromTexts("test", {
	combo: "Combo +1",
	unicombo: "UniCombo +{_c}",
	duel: "{winner} bat {loser}",
	"lvl_1&dbl": "Double saut",
	"players.one": "Un joueur",
	"players.other": "{count} joueurs",
	"stars.other": "{count} etoiles",
}))
class CompiledTexts {}

class I18nTest {
	static var failures = 0;

	static function check(name:String, actual:String, expected:String) {
		if (actual == expected) {
			return;
		}
		failures++;
		js.Syntax.code("console.error({0})", 'FAIL ${name}: expected "${expected}", got "${actual}"');
	}

	static function givenCatalogs(catalogs:Dynamic, ?locale:String) {
		js.Syntax.code("globalThis.Kado = { i18n: {0}, locale: {1} }", catalogs, locale);
	}

	static function givenEnglish(texts:Dynamic) {
		givenCatalogs({test: texts}, "en");
	}

	static function givenNoPageData() {
		js.Syntax.code("delete globalThis.Kado");
	}

	static function main() {
		check("a variable shows its value", I18n.format("UniCombo +{_c}", {_c: 3}), "UniCombo +3");
		check("zero is a value", I18n.format("Score {points}", {points: 0}), "Score 0");
		check("a repeated variable shows each time", I18n.format("{n} / {n}", {n: 2}), "2 / 2");
		check("a missing variable stays visible", I18n.format("Score {points}", {}), "Score {points}");
		check("list separators stay", I18n.format("a|b,c {n}", {n: 1}), "a|b,c 1");
		check("an empty text stays empty", I18n.format("", {n: 1}), "");
		check("a value is not read again", I18n.format("{a} {b}", {a: "{b}", b: "x"}), "{b} x");

		givenNoPageData();
		check("without page data, a text is French", CompiledTexts.combo, "Combo +1");
		check("a text with a variable is a function", CompiledTexts.unicombo({_c: 3}), "UniCombo +3");
		check("a text can have several variables", CompiledTexts.duel({winner: "A", loser: "B"}), "A bat B");
		check("without page data, a plural is French", CompiledTexts.players(2), "2 joueurs");

		givenCatalogs(null);
		check("without catalogs, a text is French", CompiledTexts.combo, "Combo +1");

		givenEnglish({combo: "Combo up"});
		check("a translation is read", CompiledTexts.combo, "Combo up");
		check("a text without a translation is French", CompiledTexts.unicombo({_c: 3}), "UniCombo +3");

		givenEnglish({unicombo: "Same colour +{_c}"});
		check("a translation shows its variables", CompiledTexts.unicombo({_c: 3}), "Same colour +3");

		givenEnglish({combo: ""});
		check("an empty translation is French", CompiledTexts.combo, "Combo +1");
		givenEnglish({combo: 42});
		check("a number is not a translation", CompiledTexts.combo, "Combo +1");
		givenEnglish({combo: null});
		check("null is not a translation", CompiledTexts.combo, "Combo +1");

		givenCatalogs({kado: {combo: "From the shared catalog"}}, "en");
		check("a catalog does not read another one", CompiledTexts.combo, "Combo +1");

		givenNoPageData();
		check("a key that cannot be a field is resolved", CompiledTexts.resolve("lvl_1&dbl"), "Double saut");
		check("a known key is resolved", CompiledTexts.resolve("combo"), "Combo +1");
		check("an unknown key stays visible", CompiledTexts.resolve("absent"), "#absent#");
		givenEnglish({"lvl_1&dbl": "Double jump"});
		check("a resolved key is translated", CompiledTexts.resolve("lvl_1&dbl"), "Double jump");

		givenNoPageData();
		check("French: 0 is a singular", CompiledTexts.players(0), "Un joueur");
		check("French: 1 is a singular", CompiledTexts.players(1), "Un joueur");
		check("French: 2 is a plural", CompiledTexts.players(2), "2 joueurs");
		check("a plural without .one uses .other", CompiledTexts.stars(1), "1 etoiles");

		var english = {"players.one": "One player", "players.other": "{count} players"};
		givenEnglish(english);
		check("English: 0 is a plural", CompiledTexts.players(0), "0 players");
		check("English: 1 is a singular", CompiledTexts.players(1), "One player");
		check("English: 2 is a plural", CompiledTexts.players(2), "2 players");

		givenEnglish({"players.other": "{count} players"});
		check("a missing .one is French", CompiledTexts.players(1), "Un joueur");
		check("the .other is still translated", CompiledTexts.players(2), "2 players");

		givenCatalogs({test: english}, "ru");
		check("another category of plural uses .other", CompiledTexts.players(3), "3 players");

		if (failures > 0) {
			js.Syntax.code("process.exit(1)");
		}
		js.Syntax.code("console.log('I18n: OK')");
	}
}
