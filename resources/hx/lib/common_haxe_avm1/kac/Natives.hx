package common_haxe_avm1.kac;

// ANTI CHEAT: functions of the browser used to read the inputs. The page takes them when it loads, before a script
// pasted in the console can replace them (resources/js/anticheat/natives.js, given in the params of the game); without
// them (test harness, replay verifier) the ones of the page now.
// - the time of an input is read with the original getter of Event.timeStamp: it stirs the gameplay draws (see
//   kado.ReplayManager, phases), a script must not choose it. The getter throws for a fake event (a Proxy...).
// - the events made by a script (isTrusted false) are ignored and counted (AntiCheat bits, see Integrity).
class Natives {
	// events refused since the game began: made by a script (isTrusted false) / not a real event (a Proxy...)
	public static var untrustedCount:Int = 0;
	public static var forgedCount:Int = 0;
	// time (Event.timeStamp, ms) of the last input taken: the time of the inputs given by the touch controls
	public static var lastInputTime:Float = -1;

	static var fns:Dynamic = null;
	static var fromPage:Bool = false;

	// snapshot: params.natives of the game, null when the page doesn't give it
	public static function init(?snapshot:Dynamic):Void {
		if (snapshot != null && snapshot.timeStamp != null && snapshot.apply != null) {
			fns = snapshot;
			fromPage = true;
			return;
		}
		if (fns != null) {
			return;
		}
		// (globalThis: the bundle has its own Reflect, the class of Haxe)
		fns = js.Syntax.code("(function (g) {
			var d = g.Object.getOwnPropertyDescriptor;
			return {
				timeStamp: d(g.Event.prototype, 'timeStamp').get,
				addEventListener: g.EventTarget.prototype.addEventListener,
				removeEventListener: g.EventTarget.prototype.removeEventListener,
				fnToString: g.Function.prototype.toString,
				apply: g.Reflect.apply,
				getOwnPropertyDescriptor: d,
				getOwnPropertyNames: g.Object.getOwnPropertyNames,
				getPrototypeOf: g.Object.getPrototypeOf,
				isFrozen: g.Object.isFrozen,
				freeze: g.Object.freeze,
				defineProperty: g.Object.defineProperty,
				pixi: null
			};
		})(globalThis)");
	}

	public static function resetCounters():Void {
		untrustedCount = 0;
		forgedCount = 0;
	}

	// true when the functions come from the page (taken before any script of the console)
	public static inline function isFromPage():Bool {
		return fromPage;
	}

	// the functions (see resources/js/anticheat/natives.js): pixi, getPrototypeOf...
	public static function get():Dynamic {
		ensure();
		return fns;
	}

	// Event.timeStamp read with the original getter, NaN when it is not a real event
	public static function timeStampOf(event:Dynamic):Float {
		ensure();
		try {
			var t:Dynamic = fns.apply(fns.timeStamp, event, []);
			return js.Syntax.typeof(t) == "number" ? t : Math.NaN;
		} catch (_:Dynamic) {
			return Math.NaN;
		}
	}

	// time of an input event of the player, NaN when the event is refused (made by a script, or not a real event)
	public static function takeInput(event:Dynamic):Float {
		var t = timeStampOf(event);
		if (Math.isNaN(t)) {
			forgedCount++;
			return Math.NaN;
		}
		// isTrusted: own property of each event that a script cannot change
		if (event.isTrusted != true) {
			untrustedCount++;
			return Math.NaN;
		}
		lastInputTime = t;
		return t;
	}

	// a real event made by the browser (without counting it)
	public static function isTrustedEvent(event:Dynamic):Bool {
		return !Math.isNaN(timeStampOf(event)) && event.isTrusted == true;
	}

	public static function listen(target:Dynamic, type:String, listener:Dynamic):Void {
		ensure();
		fns.apply(fns.addEventListener, target, [type, listener]);
	}

	public static function unlisten(target:Dynamic, type:String, listener:Dynamic):Void {
		ensure();
		fns.apply(fns.removeEventListener, target, [type, listener]);
	}

	// a function of the browser (not replaced by a script)
	public static function isNative(fn:Dynamic):Bool {
		ensure();
		if (js.Syntax.typeof(fn) != "function") {
			return false;
		}
		try {
			var source:String = fns.apply(fns.fnToString, fn, []);
			return source.indexOf("[native code]") >= 0;
		} catch (_:Dynamic) {
			return false;
		}
	}

	static inline function ensure():Void {
		if (fns == null) {
			init();
		}
	}
}
