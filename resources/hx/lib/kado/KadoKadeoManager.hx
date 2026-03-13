package kado;

import mt.DepthManager;
import common_haxe_avm1.display.ASprite;
import pixi.loaders.Loader;
import js.lib.Promise;
import js.Browser;
import js.html.CanvasElement;
import pixi.core.Application;
import pixi.core.ticker.Ticker;

typedef KadoConfig = {
	var public_key:String;
}

typedef GameParams = {
	var replayData:String;
	var isDaily:Bool;
	var name:String;
}

@:expose("KadoKadeo")
class KadoKadeoManager extends Application {
	public var canvas:CanvasElement;

	var gameClass:Class<GameInterface>;
	var game:GameInterface = null;
	var ff:FixedFramerate;

	public var lang = "fr";

	public var replay:ReplayManager;

	var root:ASprite;
	var gameRoot:ASprite;
	var dm:DepthManager;

	var startScene:StartScene;
	var gameOverScreen:GameOver = null;
	var bottomBar:BottomBar = null;

	var runDetails:Dto.RunDTO;
	var endRunDetails:Dto.EndRunResponseDTO;
	var crypto:KadoCrypto = new KadoCrypto();
	var params:GameParams;

	public var sheet:pixi.core.textures.Spritesheet;

	public var score:Int = 0;

	public var seed:mt.Rand;

	public function new(canvas:CanvasElement, gameClass:Class<GameInterface>, params:GameParams) {
		super({
			view: canvas,
			width: 900,
			height: 960,
			backgroundColor: 0x80c0e6e9
		});

		this.canvas = canvas;
		this.gameClass = gameClass;
		this.params = params;
		canvas.width = 900;
		canvas.height = 960;
		this.root = new ASprite();
		this.dm = new DepthManager(root);
		this.stage.addChild(root);

		// Pixi intro

		// this.loader = new Loader();
		loader.add('kkm', "/assets/img/content/default/kkm-0.json");
		loader.load(() -> {
			this.sheet = loader.resources["kkm"].spritesheet;
			Browser.window.document.fonts.ready.then((fontFaceSet) -> {
				trace("KadoKadeoManager initialized");
				this.showIntroScreen();
				// score = 31300;
				// this.gameOver({});
			});
		});
		common_haxe_avm1.KeyboardManager.init();

		ff = new FixedFramerate(updatePhysics);

		untyped Ticker.system.add((delta:Float) -> {
			ff.onTick(untyped Ticker.system.elapsedMS);
		});
		this.ticker.add(() -> {
			updateGraphics(ff.alpha);
			pixi.core.Pixi.tweenManager.update();
		});
		this.replay = new ReplayManager(params?.replayData);
	}

	public function updateGraphics(a:Float) {
		if (gameRoot != null) {
			gameRoot.updateGraphics(a);
		}
		if (gameOverScreen != null) {
			gameOverScreen.updateGraphics(a);
		}
	}

	public function updatePhysics(dt:Float) {
		mt.Timer.update(js.Browser.window.performance.now());
		replay.update();
		if (game != null) {
			game.update(dt);
		}
		if (gameOverScreen != null) {
			gameOverScreen.update();
		}
	}

	inline function hashFNV1a(s:String):Int {
		var hash = 0x811C9DC5;
		for (i in 0...s.length) {
			hash ^= s.charCodeAt(i);
			hash *= 0x01000193;
		}
		return hash;
	}

	public function showIntroScreen() {
		#if debug
		seed = new mt.Rand(hashFNV1a("123"));
		startGame();
		return;
		#end
		startScene = new StartScene(this);
		startScene.interactive = true;
		startScene.once("pointerdown", e -> {
			Api.askContract((data:Dto.ApiResponse<Dto.RunDTO>) -> {
				seed = new mt.Rand(hashFNV1a(data.data.seed));
				startScene.showContract(data.data);
				runDetails = data.data;
				startScene.interactive = true;
				startScene.once("pointerdown", startGame);
			}, error -> {
				trace('Contract failed: ' + error.message);
			});
			startScene.disable();
		});
		this.stage.addChild(startScene);
	}

	function startGame() {
		this.stage.removeChild(startScene);
		this.replay.start();
		var loader:Loader = untyped PIXI.Loader.shared;

		var b = dm.empty(2);
		this.bottomBar = new BottomBar(this);
		b.addChild(this.bottomBar);
		var assetName = '/assets/img/content/' + this.params.name + '/' + this.params.name + '-0.json';
		loader.add(assetName).load(() -> {
			beginGame();
		});
	}

	private function beginGame() {
		ASprite.app = this;
		this.gameRoot = dm.empty(1);
		this.game = Type.createInstance(gameClass, [this, gameRoot]);
	}

	public function gameOver(params:Dynamic):Void {
		this.replay.stop();
		// this.stage.removeChildren();
		gameOverScreen = new GameOver(() -> {
			// TODO: show loading screen
			makeEndRunHttpRequest().then((endRunDetails:Dto.EndRunResponseDTO) -> {
				gameOverScreen.destroy();
				this.stage.addChild(new EndScene(this, endRunDetails));
			}).catchError((_) -> {
				// TODO: show error
				trace(_);
			});
		});
		this.stage.addChild(gameOverScreen);
		trace('Game finished, showing end screen');
		trace('Replay data: ' + replay.encodeReplayString());
	}

	override public function destroy(?removeView:Bool):Void {
		this.stop();
		this.replay.stop();
		this.ticker.stop();
		untyped Ticker.system.stop();
		super.destroy(removeView);
	}

	public function addScore(points:Int):Void {
		score += points;
		if (bottomBar != null) {
			bottomBar.updateScore(score);
		}
	}

	private function makeEndRunHttpRequest():Promise<Dto.EndRunResponseDTO> {
		#if !debug
		var win:Dynamic = js.Browser.window;
		var kado:KadoConfig = cast win.Kado;

		var jse = new externs.JSEncrypt();
		jse.setPublicKey(kado.public_key);
		var req = {
			run_id: runDetails.run_id,
			score: score + 1,
			timestamp: Std.int(Date.now().getTime() / 1000),
			replay: replay.encodeReplayString(),
		};
		var jsonReq = haxe.Json.stringify(req);
		trace('Prepared end run request: ' + jsonReq);
		var payload = crypto.preparePayload(jsonReq);
		var request:Dto.EndRunRequestDTO = {
			payload: haxe.crypto.Base64.encode(payload),
			key: jse.encrypt(crypto.getKey().toHex()),
			sign: haxe.crypto.Base64.encode(crypto.getHmacSha256(haxe.io.Bytes.ofString(jsonReq))),
		}
		return Api.endRun(runDetails.run_id, request).then((data:Dto.ApiResponse<Dto.EndRunResponseDTO>) -> {
			trace('Run ended successfully: ' + haxe.Json.stringify(data));
			endRunDetails = data.data;
			return endRunDetails;
		}).catchError((error) -> {
			trace('Error ending run: ' + error.message);
		});
		#else
		return Promise.resolve({
			is_best: true,
			previous_star: -1,
			current_star: 0,
			people_to_beat: 0,
		});
		#end
	}
}
