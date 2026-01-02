package loader;

import flash.Boot;
import flash.Lib;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.DisplayObjectContainer;
import flash.display.Loader;
import flash.display.MovieClip;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.MouseEvent;
import flash.events.ProgressEvent;
import flash.external.ExternalInterface;
import flash.geom.Matrix;
import flash.geom.Rectangle;
import flash.net.URLLoader;
import flash.net.URLLoaderDataFormat;
import flash.net.URLRequest;
import flash.system.ApplicationDomain;
import flash.system.LoaderContext;
import flash.system.Security;
import flash.text.TextField;
import flash.utils.getTimer;
import haxe.Log;
import haxe.Md5;
import haxe.Serializer;
import haxe.Stack;
import haxe.Timer;
import haxe.Unserializer;
import mt.flash.VarSecure;
import mt.net.Codec;

public class Loader {
	public static var TEXT: *;
	public static var inst:loader.Loader;
	public static var CHEAT_FLAGS:Array;
	public static var DOMAINS_KEY:String;
	public static var DOMAINS:Array;
	public static var loaded:int;
	public static var total:int;
	public static var fps:TextField;
	public var urlLoader:URLLoader;
	public var tmp:Array;
	public var timer: *;
	public var swf:Sprite;
	public var start:Object;
	public var serverAnswerTime:Number;
	public var scoreBar:Score;
	public var run:Object;
	public var root:MovieClip;
	public var rcode:int;
	public var manager:Object;
	public var initSequence:Init;
	public var init:Object;
	public var gameOverSequence:GameOver;
	public var gameDomain:ApplicationDomain;
	public var digits:Array;
	public var codec:Codec;
	public var buttonsMC:Sprite;
	public var buttons:Array;
	public var bmp:Bitmap;
	public var base:Sprite;
	public var api:Api;

	public function new(root:MovieClip = undefined) {
		if (Boot.skip_constructor) {
			return;
		}
		root = root;
		base = new Sprite();
		root.addChild(base);
		swf = new Sprite();
		base.addChild(swf);
		api = new Api(this);
		var key:String = root.loaderInfo.parameters.lang;
		loader.Loader.TEXT = key == "fr" ? TextFr : (key == "en" ? TextEn : (key == "es" ? TextEs : TextEn));
		key = root.loaderInfo.parameters.key;
		if (key == null) {
			key = "";
		}
		codec = new Codec(Md5.encode(key));
		checkDomain();
		init = {
			"_swfUrl": root.loaderInfo.parameters.swf,
			"_startUrl": null,
			"_images": [],
			"_artwork": null,
			"_useMouse": false,
			"_periodId": Std.random(1000)
		};
		start = {
			"_playId": 0,
			"_tokens": 10,
			"_jackpot": false,
			"_error": null,
			"_contract": 10000,
			"_saveUrl": null,
			"_decrementJsCall": null,
			"_scoreJsCall": null,
			"_rcheck": 0
		};
		initTmpMemory();
		initSequence = new Init(this);
		root.addEventListener(Event.ENTER_FRAME, initMain);
		buttons = [];
		buttonsMC = new Sprite();
		buttonsMC.visible = false;
		root.addChild(buttonsMC);
		initLoading();
	}

	public static function main():void {
		loader.Loader.inst = new loader.Loader(Lib.current);
		Security.allowDomain("kkworld");
		Security.allowDomain("www.kadokado.com");
		Security.allowDomain("dat.kadokado.com");
		ExternalInterface.addCallback("setDouble", loader.Loader.inst.setDouble);
	}

	public function updateScore(s:int):void {
		var me:loader.Loader;
		var score:int;
		var d: * = null
		as
		ScoreNumber;
		var skin: * = null
		as
		Skinner;
		score = s;
		for (var _g:int = 0,
		var _g1:Array = digits;
		_g < int(_g1.length);
	)
		{
			d = _g1[_g];
			_g++;
			d.gotoAndStop(int(s % 10) + 1);
			s /= 10;
		}
		if (start._contract == null) {
			scoreBar.gotoAndStop(1);
		} else {
			scoreBar.gotoAndStop(score >= start._contract ? 3 : 2);
			me = this;
			skin = new Skinner(scoreBar, function(mc:MovieClip):Boolean {
				if (me.scoreBar.bar == null || (me.scoreBar.maskXXXX == null || me.scoreBar.tokens == null)) {
					return false;
				}
				me.scoreBar.maskXXXX.scaleX = Math.min(score / me.start._contract, 1);
				me.scoreBar.bar.mask = me.scoreBar.maskXXXX;
				me.scoreBar.tokens.visible = true;
				me.scoreBar.tokens.text = Std.string(me.start._tokens);
				return true;
			});
		}
	}

	public function startGame():void {
		var me:loader.Loader;
		var i:int = 0;
		var d: * = null
		as
		ScoreNumber;
		initSequence.cleanup();
		serverAnswerTime = Number(Date.now().getTime());
		digits = [];
		for (var _g:int = 0;
		_g < 7;
	)
		{
			i = _g++;
			d = new ScoreNumber();
			scoreBar.addChild(d);
			d.x = (6 - i) * 17 + 185;
			d.y = 309;
			digits.push(d);
		}
		updateScore(0);
		timer = gameDomain.getDefinition(Boot.__unprotect__("mt") + "." + Boot.__unprotect__("Timer"));
		timer.maxDeltaTime = 1 / 0;
		timer.oldTime = getTimer();
		var v: * = manager;
		v.init();
		timer.oldTime = getTimer();
		run = {
			"time": getTimer(),
			"date": Number(Date.now().getTime()),
			"slow": 1,
			"tmod": 1,
			"slowFlag": false,
			"scaleFlag": false,
			"cheatFlag": false,
			"retry": null,
			"lastScore": 0,
			"lastScoreTimer": 0,
			"maxDelta": 0,
			"deltaFlag": false,
			"tmodFlag": false
		};
		root.addEventListener(Event.ENTER_FRAME, main_);
		me = this;
		new Timer(1000).run = function():void {
			me.checkCheating();
			me.regularCleanup();
		};
		main_(null);
	}

	public function setDouble(on:Boolean):void {
		if (bmp != null && bmp.parent != null) {
			bmp.parent.removeChild(bmp);
			bmp.bitmapData.dispose();
		}
		if (on) {
			bmp = new Bitmap(new BitmapData(300, 320, false, 16777215));
			root.scaleX = 2;
			root.scaleY = 2;
			root.addChild(bmp);
			base.visible = Boolean(init._useMouse);
			buttonsMC.visible = true;
		} else {
			bmp = null;
			root.scaleX = 1;
			root.scaleY = 1;
			base.visible = true;
			buttonsMC.visible = false;
		}
	}

	public function saveScore(score:VarSecure, params: *):void {
		var me:loader.Loader;
		var lv:URLLoader;
		var str:String;
		var points:int = score.get();
		var deltaDate:Number = checkCheating();
		var cheat:String = loader.Loader.CHEAT_FLAGS[
			score.bug ? 0 : (Boolean(run.cheatFlag) ? 3 : (Boolean(run.slowFlag) ? 1 : (Boolean(run.scaleFlag) ? 2 : (Boolean(run.deltaFlag) ? 4 : (Boolean(run.tmodFlag) ? 5 : 100)))))
		];
		var data: * = {
			"_playId": start._playId,
			"_score": points,
			"_flag": cheat,
			"_slow": int(Number(run.slow) * 100),
			"_delta": int(run.maxDelta),
			"_gtime": null,
			"_ptime": int(deltaDate / 1000),
			"_params": params,
			"_tmod": int(Number(run.tmod) * 100),
			"_retry": -1
		};
		str = encode(data);
		var t:int = int((Number(Date.now().getTime()) - serverAnswerTime) / 1000);
		var s:String = Std.string(int(t % 60));
		if (s.length == 1) {
			s = "0" + s;
		}
		var cheat1:String = Boolean(run.cheatFlag) ? " !CHEAT!" : "";
		error("Score = "
			+ points
			+ cheat1
			+ "\nTime = "
			+ int(t / 60)
			+ ":"
			+ s
			+ "\n("
			+ StringTools.urlEncode(str).length
			+ " bytes)");
	}

	public function regularCleanup():void {
		var b: * = null
		as
		Sprite;
		for (var _g:int = 0,
		var _g1:Array = buttons;
		_g < int(_g1.length);
	)
		{
			b = _g1[_g];
			_g++;
			if (b.hitArea.parent == null) {
				buttonsMC.removeChild(b);
				buttons.remove(b);
			}
		}
	}

	public function registerButton(:Sprite):void {
		var mc:Sprite;
		var bt: * = null
		as
		Sprite;
		mc = param1;
		var b:Sprite = null;
		for (var _g:int = 0,
		var _g1:Array = buttons;
		_g < int(_g1.length);
	)
		{
			bt = _g1[_g];
			_g++;
			if (bt.hitArea == mc || bt.hitArea == mc.hitArea) {
				b = bt;
				break;
			}
		}
		if (b == null) {
			b = new Sprite();
			buttonsMC.addChild(b);
			buttons.push(b);
		}
		if (mc.hitArea != null) {
			b.hitArea = mc.hitArea;
		} else {
			b.hitArea = mc;
		}
		b.addEventListener(MouseEvent.CLICK, function(e:Event):void {
			mc.dispatchEvent(e);
		});
		b.addEventListener(MouseEvent.MOUSE_DOWN, function(e:Event):void {
			mc.dispatchEvent(e);
		});
		b.addEventListener(MouseEvent.MOUSE_UP, function(e:Event):void {
			mc.dispatchEvent(e);
		});
		b.addEventListener(MouseEvent.MOUSE_OVER, function(e:Event):void {
			mc.dispatchEvent(e);
		});
		b.addEventListener(MouseEvent.MOUSE_OUT, function(e:Event):void {
			mc.dispatchEvent(e);
		});
		b.buttonMode = mc.buttonMode;
		b.useHandCursor = mc.useHandCursor;
	}

	public function redirect(url:String):void {
		Lib.getURL(new URLRequest(url), "_self");
	}

	public function onServerData(e:Event):void {
		var o: * = e.target;
		var data:String = o == null ? null : o["data"];
		if (data == null) {
			error(loader.Loader.TEXT.ERR_START);
			return;
		}
		start = decode(data);
		if (start._error != null) {
			redirect(start._error);
			return;
		}
		if (start == null || (start._playId == null || int(start._rcheck) != (rcode ^ 0xAD0AD0))) {
			return;
		}
		if (start._decrementJsCall != null) {
			Lib.getURL(new URLRequest("javascript:" + start._decrementJsCall), "_self");
		}
		serverAnswerTime = Number(Date.now().getTime());
		initSequence.displayContract();
	}

	public function onSaveScoreData(data:String):void {
		if (data == null) {
			return;
		}
		var end: * = decode(data);
		if (end._endUrl != null) {
			run.retry.stop();
			redirect(end._endUrl);
		}
	}

	public function main_(_: *):void {
		var s:int = 0;
		var e: * = null;
		try {
			manager.main();
			if (loader.Loader.fps == null) {
				loader.Loader.fps = new TextField();
				loader.Loader.fps.background = true;
				loader.Loader.fps.backgroundColor = 238;
				loader.Loader.fps.textColor = 16777215;
				loader.Loader.fps.x = 150;
				loader.Loader.fps.y = 300;
				loader.Loader.fps.width = 16;
				loader.Loader.fps.text = "00";
				Lib.current.addChild(loader.Loader.fps);
			}
			loader.Loader.fps.text = Std.string(int(Math.round(timer.fps())));
			if (gameOverSequence != null) {
				gameOverSequence.update();
			}
			run.lastScoreTimer = Number(run.lastScoreTimer) + timer.deltaT;
			if (gameOverSequence == null) {
				run.tmod = Number(run.tmod) * 0.99 + 0.01 * timer.tmod;
			}
			if (Number(run.lastScoreTimer) > 1) {
				run.lastScoreTimer = 0;
				s = api.score.get();
				if (s != int(run.lastScore)) {
					run.lastScore = s;
					if (start._scoreJsCall != null) {
						ExternalInterface.call(start._scoreJsCall, s);
					}
				}
			}
			drawDouble();
		} catch (_loc_e_: *) {
			ExternalInterface.call("traceError", Std.string(e));
			return;
		}
	}

	public function loadStart(e:Event):void {}

	public function loadProgress(e:ProgressEvent):void {
		initSequence.loadProgress(e.bytesLoaded / e.bytesTotal);
		if (loader.Loader.total == 0) {
			loader.Loader.total = e.bytesTotal;
		}
		loader.Loader.loaded = e.bytesLoaded;
	}

	public function loadError(e:Event):void {
		error(loader.Loader.TEXT.ERR_DL + " (" + Std.string(e) + ")");
	}

	public function loadComplete(e:Event):void {
		var context: * = null
		as
		LoaderContext;
		var gameLoader: * = null
		as
		flash.display.Loader;
		var mask: * = null
		as
		Sprite;
		var err: * = null;
		try {
			if (loader.Loader.loaded != loader.Loader.total) {
				error(loader.Loader.TEXT.ERR_DL + " (bytes " + loader.Loader.loaded + " != " + loader.Loader.total + ")");
				return;
			}
			initSequence.loadComplete();
			gameDomain = new ApplicationDomain();
			context = new LoaderContext(false, gameDomain);
			gameLoader = new flash.display.Loader();
			gameLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e1: *):void {
				var err: * = null;
				var apiClass: * = null;
				var v: * = null;
				try {
					err = loader.Loader.inst.gameDomain.getDefinition(Boot.__unprotect__("Manager"));
					loader.Loader.inst.manager = err;
					apiClass = loader.Loader.inst.gameDomain.getDefinition(Boot.__unprotect__("KKApi"));
					v = apiClass;
					v.setApi(loader.Loader.inst.api);
				} catch (_loc_e_: *) {
					Log.trace(Std.string(err), {
						"fileName": "Loader.hx",
						"lineNumber": 620,
						"className": "loader.Loader",
						"methodName": "loadComplete"
					});
					return;
				}
			});
			swf.addChild(gameLoader);
			gameLoader.loadBytes(urlLoader.data, context);
			mask = new Sprite();
			mask.graphics.beginFill(16777215);
			mask.graphics.drawRect(0, 0, 300, 320);
			mask.graphics.endFill();
			gameLoader.mask = mask;
		} catch (_loc_e_: *) {
			Log.trace(Std.string(err), {
				"fileName": "Loader.hx",
				"lineNumber": 632,
				"className": "loader.Loader",
				"methodName": "loadComplete"
			});
			Log.trace(Stack.exceptionStack().join("\n"), {
				"fileName": "Loader.hx",
				"lineNumber": 633,
				"className": "loader.Loader",
				"methodName": "loadComplete"
			});
			return;
		}
	}

	public function isGameOver():Boolean {
		return gameOverSequence != null;
	}

	public function initTmpMemory():void {
		var i:int = 0;
		tmp = [];
		for (var _g1:int = 0,
		var _g:int = Std.random(1000);
		_g1 < _g;
	)
		{
			i = _g1++;
			tmp.push([]);
		}
	}

	public function initMain(_: *):void {
		initSequence.update();
		drawDouble();
	}

	public function initLoading():void {
		initSequence.loadProgress(0);
		var url:String = init._swfUrl;
		var urlRequest:URLRequest = new URLRequest(url);
		urlLoader = new URLLoader();
		urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
		urlLoader.addEventListener(Event.OPEN, loadStart);
		urlLoader.addEventListener(Event.COMPLETE, loadComplete);
		urlLoader.addEventListener(IOErrorEvent.IO_ERROR, loadError);
		urlLoader.addEventListener(ProgressEvent.PROGRESS, loadProgress);
		urlLoader.load(urlRequest);
	}

	public function gameOver(score:VarSecure, params: *, skip:Object = undefined):void {
		if (gameOverSequence != null) {
			return;
		}
		gameOverSequence = new GameOver(this);
		gameOverSequence.done = (function(param1:Function, param2:VarSecure, param3: *):Function {
			var f:Function = param1;
			var a1:VarSecure = param2;
			var a2: * = param3;
			return function():void {
				return f(a1, a2);
			};
		})(saveScore, score, params);
		if (skip) {
			gameOverSequence.done();
		}
	}

	public function error(msg:String):void {
		if (swf != null && swf.parent != null) {
			swf.parent.removeChild(swf);
		}
		if (scoreBar != null && scoreBar.parent != null) {
			scoreBar.parent.removeChild(scoreBar);
		}
		if (initSequence != null) {
			initSequence.displayError(msg);
		} else {
			Log.trace("ERROR: " + msg, {
				"fileName": "Loader.hx",
				"lineNumber": 390,
				"className": "loader.Loader",
				"methodName": "error"
			});
		}
	}

	public function encode(data: *):String {
		return codec.run(Serializer.run(data));
	}

	public function drawDouble():void {
		if (bmp != null) {
			base.visible = true;
			bmp.bitmapData.fillRect(new Rectangle(0, 0, 300, 320), 16777215);
			bmp.bitmapData.draw(base, new Matrix(1, 0, 0, 1, 0, 0));
			base.visible = false;
		}
	}

	public function decode(data:String): * {
		var e: * = null;
		try {
			return Unserializer.run(codec.run(data));
		} catch (_loc_e_: *) {
			error(Std.string(e) + " in " + data);
			return null;
		}
	}

	public function checkDomain():Boolean {
		var d: * = null
		as
		String;
		var d1: * = null
		as
		String;
		var c:Codec = new Codec(loader.Loader.DOMAINS_KEY);
		for (var _g:int = 0,
		var _g1:Array = loader.Loader.DOMAINS;
		_g < int(_g1.length);
	)
		{
			d = _g1[_g];
			_g++;
			d1 = StringTools.urlDecode(d);
			if (c.run(root.loaderInfo.loaderURL.substr(0, d1.length)) == d1) {
				return true;
			}
		}
		return false;
	}

	public function checkCheating():Number {
		var deltaT:int = getTimer() - int(run.time);
		var deltaDate:Number = Number(Date.now().getTime()) - Number(run.date);
		var factor:Number = deltaT / deltaDate;
		if (deltaT < 3000 || deltaDate < 3000) {
			return deltaDate;
		}
		run.slow = Number(run.slow) * 0.9 + factor * 0.1;
		run.maxDelta = int(Math.max(Math.abs(deltaT - deltaDate), int(run.maxDelta)));
		if (factor < 0.7 || factor > 1.3) {
			run.slowFlag = true;
		}
		if (int(run.maxDelta) > 10000) {
			run.deltaFlag = true;
		}
		var double:int = bmp == null ? 1 : 2;
		return deltaDate;
	}

	public function callServer():void {
		var v: * = null;
		var data: * = null
		as
		String;
		var url: * = null
		as
		String;
		var request: * = null
		as
		URLRequest;
		var lv: * = null
		as
		URLLoader;
		Timer.delay(initSequence.displayContract, 500);
	}
}
