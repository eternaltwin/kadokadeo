// haxe tests/hx/i18n.hxml
import kado.I18n;

@:build(kado.I18nMacro.build("tests/hx/fixtures/texts.json"))
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

	static function main() {
		check("a variable shows its value", I18n.format("UniCombo +{_c}", {_c: 3}), "UniCombo +3");
		check("zero is a value", I18n.format("Score {points}", {points: 0}), "Score 0");
		check("a repeated variable shows each time", I18n.format("{n} / {n}", {n: 2}), "2 / 2");
		check("a missing variable stays visible", I18n.format("Score {points}", {}), "Score {points}");
		check("list separators stay", I18n.format("a|b,c {n}", {n: 1}), "a|b,c 1");
		check("an empty text stays empty", I18n.format("", {n: 1}), "");
		check("a value is not read again", I18n.format("{a} {b}", {a: "{b}", b: "x"}), "{b} x");

		check("a text without a variable is a field", CompiledTexts.combo, "Combo +1");
		check("a text with a variable is a function", CompiledTexts.unicombo({_c: 3}), "UniCombo +3");
		check("a text can have several variables", CompiledTexts.duel({winner: "A", loser: "B"}), "A bat B");

		if (failures > 0) {
			js.Syntax.code("process.exit(1)");
		}
		js.Syntax.code("console.log('I18n: OK')");
	}
}
