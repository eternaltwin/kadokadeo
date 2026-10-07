// Host of the original game.swf in Ruffle: what the KadoKado AS3 loader (api/loader9.swf) does for a game, minus the
// server. game.swf (Haxe 2 -swf9 + obfu9) has no main: the loader loads it in its own ApplicationDomain, gives it the
// KKApi object, resets mt.Timer, calls Manager.init() then Manager.main() at each ENTER_FRAME.
// The names are the obfuscated ones of game.swf (FFDec shows them as §..§ with \x escapes, same strings here).
// flashvars: fixed=1 -> fixed step (mt.Timer: deltaT 1/30 s, tmod 1 at every frame) instead of the real time.
// JS (ExternalInterface): player.hptState() -> { frame, tmod, deltaT, score, over, quality }.
import flash.display.Loader;
import flash.events.Event;
import flash.external.ExternalInterface;
import flash.net.URLRequest;
import flash.system.ApplicationDomain;
import flash.system.LoaderContext;

class Host {
	static inline var MANAGER = "]\x15g\x10\x03"; // Manager: init QhvU, main \x1a9&K
	static inline var KKAPI = "\x0eBK_\x03"; // KKApi: setApi Zeo;
	static inline var TIMER = "|g\x01.6Zyr\x03"; // mt.Timer
	// mt.Timer statics: inited flag, oldTime, maxDeltaTime, calc_tmod, tmod, deltaT
	static inline var T_INIT = "\x02y\x02";
	static inline var T_OLD = "IG=!\x03";
	static inline var T_MAXDT = "ZhZ\x05\x02";
	static inline var T_CALC = "\x073\x02}";
	static inline var T_TMOD = "$Pk'";
	static inline var T_DT = "5ie=\x03";

	static var dom:ApplicationDomain;
	static var manager:Dynamic;
	static var timer:Dynamic;
	static var fixed = false;
	static var started = false;
	static var frame = 0;
	static var score = 0;
	static var over:Dynamic = null;

	static function main() {
		var root = flash.Lib.current;
		fixed = root.loaderInfo.parameters.fixed == "1";
		var url:String = root.loaderInfo.parameters.game;
		dom = new ApplicationDomain(); // like loader9: the game's classes apart from the host's
		var ld = new Loader();
		root.addChild(ld); // on the stage before loading: Game.root (the game's root MovieClip) has a stage
		ld.contentLoaderInfo.addEventListener(Event.COMPLETE, function(_) root.addEventListener(Event.ENTER_FRAME, onFrame));
		ld.load(new URLRequest(url == null ? "game.swf" : url), new LoaderContext(false, dom));
		if (ExternalInterface.available)
			ExternalInterface.addCallback("hptState", function() return {
				frame: frame,
				tmod: timer == null ? 0.0 : get(timer, T_TMOD),
				deltaT: timer == null ? 0.0 : get(timer, T_DT),
				score: score,
				over: over != null,
				quality: Std.string(root.stage.quality)
			});
	}

	static function call(o:Dynamic, f:String, args:Array<Dynamic>):Dynamic
		return Reflect.callMethod(o, get(o, f), args);

	static function get(o:Dynamic, f:String):Dynamic
		return untyped o[f];

	static function onFrame(_) {
		if (!started) {
			timer = dom.getDefinition(TIMER);
			// the game's static init (flash.Boot of game.swf) may wait for ADDED_TO_STAGE / a timeout
			if (get(timer, T_INIT) != true)
				return;
			manager = dom.getDefinition(MANAGER);
			call(dom.getDefinition(KKAPI), "Zeo;", [api()]);
			Reflect.setField(timer, T_MAXDT, fixed ? -1.0 : Math.POSITIVE_INFINITY); // < 0: always deltaT = 1 / wantedFPS
			Reflect.setField(timer, T_OLD, flash.Lib.getTimer());
			call(manager, "QhvU", []);
			Reflect.setField(timer, T_OLD, flash.Lib.getTimer());
			Reflect.setField(timer, T_TMOD, 1.0);
			Reflect.setField(timer, T_CALC, 1.0);
			Reflect.setField(timer, T_DT, 1.0);
			started = true;
		}
		frame++;
		call(manager, "\x1a9&K", []);
	}

	// KKApi object (loader9 class y\x19`\x01): KKConst values are plain ints here
	static function api():Dynamic {
		var a:Dynamic = {};
		var set = function(n:String, f:Dynamic) Reflect.setField(a, n, f);
		set("\x18PH)\x01", function() return true); // available
		set("/p\x06\x0e", function() return false); // isLocal
		set("Te\x036\x03", function(p:Dynamic) {}); // saveScore
		set("7wed\x02", function(s:Dynamic) score = s); // setScore
		set(" z\x1bG\x02", function(s:Dynamic) return score += s); // addScore
		set("`d\x1fx", function() return score); // getScore
		set("0+X\x10\x02", function(p:Dynamic) { over = p; if (ExternalInterface.available) ExternalInterface.call("console.log", "gameOver score " + score); }); // gameOver
		set("|}C\x1f\x01", function(v:Int) return v); // const
		set("]\x1ed&\x03", function(v:Array<Int>) return v.copy()); // aconst
		set("/1Yt", function(x:Dynamic, y:Dynamic) return x + y); // cadd
		set("\x1fm@2\x01", function(x:Dynamic, y:Dynamic) return x * y); // cmult
		set("L{_\x01", function(c:Dynamic) return c); // val
		set("!]8u\x03", function() {}); // flagCheater
		set("RHMl", function(b:Dynamic) {}); // registerButton: no proxy, the mouse events reach the game's root directly
		set("V%'t", function() return 0); // getPeriod
		return a;
	}
}
