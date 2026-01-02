package loader;

import flash.display.MovieClip;
import flash.display.Stage;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import flash.utils.getQualifiedClassName;

public dynamic class Boot extends MovieClip {
	public static var tf:TextField;
	public static var lines:Array;
	public static var lastError:Error;
	public static var skip_constructor:Boolean;

	public static function init():void {
		Math.NaN = Number(Number.NaN);
		Math.NEGATIVE_INFINITY = Number(Number.NEGATIVE_INFINITY);
		Math.POSITIVE_INFINITY = Number(Number.POSITIVE_INFINITY);
		Math.isFinite = function(i:Number):Boolean {
			return isFinite(i);
		};
		Math.isNaN = function(i:Number):Boolean {
			return isNaN(i);
		};
		null;
		var d: * = Date;
		d.now = function(): * {
			return new Date();
		};
		d.fromTime = function(t: *):Date {
			var d1:Date = new Date();
			d1.setTime(t);
			return d1;
		};
		d.fromString = function(s:String):Date {
			var k: * = null
			as
			Array;
			var d1: * = null
			as
			Date;
			var y: * = null
			as
			Array;
			var t: * = null
			as
			Array;
			switch (s.length) {
				case 8:
					k = s.split(":");
					d1 = new Date();
					d1.setTime(0);
					d1.setUTCHours(k[0]);
					d1.setUTCMinutes(k[1]);
					d1.setUTCSeconds(k[2]);
					return d1;
				case 10:
					k = s.split("-");
					return new Date(int(k[0]), k[1] - 1, int(k[2]), 0, 0, 0);
				case 19:
					k = s.split(" ");
					y = k[0].split("-");
					t = k[1].split(":");
					return new Date(int(y[0]), y[1] - 1, int(y[2]), int(t[0]), int(t[1]), int(t[2]));
				default:
					Boot.lastError = new Error();
					throw "Invalid date format : " + s;
			}
		};
		d.prototype["toString"] = function():String {
			var date:Date = this;
			var m:int = int(date.getMonth()) + 1;
			var d1:int = int(date.getDate());
			var h:int = int(date.getHours());
			var mi:int = int(date.getMinutes());
			var s:int = int(date.getSeconds());
			return int(date.getFullYear()) + "-" + (m < 10 ? "0" + m : "" + m) + "-" + (d1 < 10 ? "0" + d1 : "" + d1) + " " + (h < 10 ? "0" + h : "" + h)
				+ ":" + (mi < 10 ? "0" + mi : "" + mi) + ":" + (s < 10 ? "0" + s : "" + s);
		};
		Timer.wantedFPS = 32;
		Timer.maxDeltaTime = 0.5;
		Timer.oldTime = getTimer();
		Timer.tmod_factor = 0.95;
		Timer.calc_tmod = 1;
		Timer.tmod = 1;
		Timer.deltaT = 1;
		Timer.frameCount = 0;
		Serializer.USE_CACHE = false;
		Serializer.USE_ENUM_INDEX = false;
		Serializer.BASE64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789%:";
		Init.SLIDE_SPEED = 40;
		Init.frames = 0;
		TextFr.LANG = "fr";
		TextFr.RLD = "Merci de relancer le jeu.";
		TextFr.ERR_DL = "Une erreur a eu lieu lors du téléchargement. " + TextFr.RLD;
		TextFr.ERR_DL_INIT = "Une erreur a eu lieu lors de l\'initialisation du téléchargement. " + TextFr.RLD;
		TextFr.ERR_MNG = "Erreur lors du chargement du jeu. Votre partie n\'est pas perdue. " + TextFr.RLD;
		TextFr.ERR_START = "Une erreur a eu lieu lors de l\'initialisation de la partie. " + TextFr.RLD;
		TextFr.LOADING = "CHARGEMENT";
		TextFr.CLICK_TO_START = "CLIQUER POUR COMMENCER";
		TextFr.CONTACTING_SERVER = "CONNEXION AU\nSERVEUR EN COURS...";
		TextFr.SCORE_LABEL = "SCORE À BATTRE";
		TextFr.TOKENS_LABEL = "POINTS";
		TextEn.LANG = "en";
		TextEn.RLD = "Please restart the game.";
		TextEn.ERR_DL = "Loading error. " + TextEn.RLD;
		TextEn.ERR_DL_INIT = "We have encountered an error during the starting process of loading. " + TextEn.RLD;
		TextEn.ERR_MNG = "We have encountered an error during the loading process. Your gem is not lost. " + TextEn.RLD;
		TextEn.ERR_START = "We have encountered an error during the starting process of the game. " + TextEn.RLD;
		TextEn.LOADING = "LOADING";
		TextEn.CLICK_TO_START = "CLICK HERE TO START";
		TextEn.CONTACTING_SERVER = "CONTACTING SERVER...";
		TextEn.SCORE_LABEL = "SCORE TO BEAT";
		TextEn.TOKENS_LABEL = "POINTS";
		TextEs.LANG = "es";
		TextEs.RLD = "Por favor, reinicia el juego.";
		TextEs.ERR_DL = "Ha ocurrido un error durante el proceso de carga. " + TextEs.RLD;
		TextEs.ERR_DL_INIT = "Ha ocurrido un error en el inicio del proceso de carga. " + TextEs.RLD;
		TextEs.ERR_MNG = "Error en el proceso de carga del juego. Tu partida no se ha perdido. " + TextEs.RLD;
		TextEs.ERR_START = "Error en la inicialización de la partida. " + TextEs.RLD;
		TextEs.LOADING = "CARGANDO";
		TextEs.CLICK_TO_START = "CLICK PARA EMPEZAR";
		TextEs.CONTACTING_SERVER = "CONTACTANDO...";
		TextEs.SCORE_LABEL = "OBJETIVO";
		TextEs.TOKENS_LABEL = "PTS";
		Loader.TEXT = TextFr;
		Loader.CHEAT_FLAGS = ["score", "slow", "size", "mark", "delta", "tmod"];
		Loader.DOMAINS_KEY = "8tleTrleno0diu7Ou1i96Riu7riEQLad";
		Loader.DOMAINS = ["xNDQ%27%0D%01"];
		Loader.loaded = 0;
		Loader.total = 0;
		Loader.fps = null;
		Unserializer.DEFAULT_RESOLVER = Type;
		Unserializer.BASE64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789%:";
		Unserializer.CODES = null;
		Md5.inst = new Md5();
		Boot.skip_constructor = false;
		___MAIN.init = Loader.main();
	}

	public function Boot(mc:MovieClip = undefined) {
		var cca:Object;
		var e: * = null;
		if (Boot.skip_constructor) {
			return;
		}
		super();
		e = Array.prototype;
		e.copy = function(): * {
			return this.slice();
		};
		e.insert = function(i: *, x: *):void {
			this.splice(i, 0, x);
		};
		e.remove = function(obj: *):Boolean {
			var idx:int = this.indexOf(obj);
			if (idx == -1) {
				return false;
			}
			this.splice(idx, 1);
			return true;
		};
		e.iterator = function():Object {
			var cur:int = 0;
			var arr:Array = this;
			return {
				"hasNext": function():Boolean {
					return cur < int(arr.length);
				},
				"next": function(): * {
					var _loc1_:int;
					cur = (_loc1_ = cur) + 1;
					return arr[_loc1_];
				}
			};
		};
		e.setPropertyIsEnumerable("copy", false);
		e.setPropertyIsEnumerable("insert", false);
		e.setPropertyIsEnumerable("remove", false);
		e.setPropertyIsEnumerable("iterator", false);
		cca = String.prototype.charCodeAt;
		String.prototype.charCodeAt = function(i: *): * {
			var x: * = cca.call(this, i);
			if (isNaN(x)) {
				return null;
			}
			return x;
		};
		Boot.lines = [];
		var c:MovieClip = mc == null ? this : mc;
		Lib.current = c;
		try {
			if (c.stage != null && c.stage.align == "") {
				c.stage.align = "TOP_LEFT";
			} else {
				null;
			}
		} catch (_loc_e_: *) {
			if (Boot.init != null) {
				Boot.init();
			}
			return;
		}
	}

	public static function enum_to_string(e:Object):String {
		if (e.params == null) {
			return e.tag;
		}
		return e.tag + "(" + e.params.join(",") + ")";
	}

	public static function __instanceof(v: *, t: *):Boolean {
		var e: * = null;
		try {
			if (t == Dynamic) {
				return true;
			}
			return v is t;
		} catch (_loc_e_: *) {}
	}

	public static function __clear_trace():void {
		if (Boot.tf == null) {
			return;
		}
		Lib.current.removeChild(Boot.tf);
		Boot.tf = null;
		Boot.lines = [];
	}

	public static function __set_trace_color(rgb:uint):void {
		Boot.getTrace().textColor = rgb;
	}

	public static function getTrace():TextField {
		var format: * = null
		as
		TextFormat;
		var mc:MovieClip = Lib.current;
		if (Boot.tf == null) {
			Boot.tf = new TextField();
			format = Boot.tf.getTextFormat();
			format.font = "_sans";
			Boot.tf.defaultTextFormat = format;
			Boot.tf.selectable = false;
			Boot.tf.width = mc.stage == null ? 800 : mc.stage.stageWidth;
			Boot.tf.autoSize = TextFieldAutoSize.LEFT;
			Boot.tf.mouseEnabled = false;
		}
		mc.addChild(Boot.tf);
		return Boot.tf;
	}

	public static function __trace(v: *, pos:Object):void {
		var tf:TextField = Boot.getTrace();
		var pstr:String = pos == null ? "(null)" : pos.fileName + ":" + int(pos.lineNumber);
		Boot.lines = Boot.lines.concat((pstr + ": " + Boot.__string_rec(v, "")).split("\n"));
		tf.text = Boot.lines.join("\n");
		var stage:Stage = Lib.current.stage;
		if (stage == null) {
			return;
		}
		while (int(Boot.lines.length) > 1 && tf.height > stage.stageHeight) {
			Boot.lines.shift();
			tf.text = Boot.lines.join("\n");
		}
	}

	public static function __string_rec(param1: *, param2:String):String {
		var _loc4_: * = null
		as
		String;
		var _loc5_: * = null
		as
		Array;
		var _loc6_: * = null
		as
		Array;
		var _loc7_: * = 0;
		var _loc8_: * = null;
		var _loc9_: * = null
		as
		String;
		var _loc10_:Boolean = false;
		var _loc11_:int = 0;
		var _loc12_:int = 0;
		var _loc13_: * = null
		as
		String;
		var _loc3_:String = getQualifiedClassName(param1);
		_loc4_ = _loc3_;
		if (_loc4_ == "Object") {
			_loc7_ = 0;
			_loc6_ = [];
			_loc8_ = param1;
			for (_loc7_ in _loc8_) {
				_loc6_.push(_loc7_);
			}
			_loc5_ = _loc6_;
			_loc9_ = "{";
			_loc10_ = true;
			for (_loc7_ = 0,
			_loc11_ = int(_loc5_.length);
			_loc7_ < _loc11_;
		)
			{
				_loc12_ = _loc7_++;
				_loc13_ = _loc5_[_loc12_];
				if (_loc10_) {
					_loc10_ = false;
				} else {
					_loc9_ += ",";
				}
				_loc9_ += " " + _loc13_ + " : " + Boot.__string_rec(param1[_loc13_], param2);
			}
			if (!_loc10_) {
				_loc9_ += " ";
			}
			return _loc9_ + "}";
		}
		if (_loc4_ == "Array") {
			_loc9_ = "[";
			_loc10_ = true;
			_loc5_ = param1;
			for (_loc7_ = 0,
			_loc11_ = int(_loc5_.length);
			_loc7_ < _loc11_;
		)
			{
				_loc12_ = _loc7_++;
				if (_loc10_) {
					_loc10_ = false;
				} else {
					_loc9_ += ",";
				}
				_loc9_ += Boot.__string_rec(_loc5_[_loc12_], param2);
			}
			return _loc9_ + "]";
		}
		_loc4_ = typeof
		param1;
		if (_loc4_ == "function") {
			return "<function>";
		}
		return new String(param1);
	}

	public static function __unprotect__(s:String):String {
		return s;
	}
}

import flash.text.TextField;
import flash.utils.ByteArray;
import flash.utils.getTimer;
import haxe.Md5;
import haxe.Serializer;
import haxe.Unserializer;
import loader.Init;
import loader.Loader;
import loader.TextEn;
import loader.TextEs;
import loader.TextFr;
import mt.Timer;
