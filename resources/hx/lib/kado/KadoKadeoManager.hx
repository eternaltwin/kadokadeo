package kado;

import js.html.CanvasElement;
import pixi.core.Application;
import pixi.core.text.Text;
import pixi.core.ticker.Ticker;

typedef KadoConfig = {
	var public_key:String;
}

typedef GameParams = {
	var replayData:String;
	var isDaily:Bool;
}

@:expose("KadoKadeo")
class KadoKadeoManager extends Application {
	public var canvas:CanvasElement;

	var gameClass:Class<GameInterface>;
	var game:GameInterface = null;
	var ff:FixedFramerate;

	public var replay:ReplayManager;

	var startScene:StartScene;
	var gameOverScreen:GameOver = null;
	var isGameStarted:Bool;

	var runDetails:Dto.RunDTO;
	var crypto:KadoCrypto = new KadoCrypto();

	var score:Int = 0;

	public var seed:mt.Rand;

	public function new(canvas:CanvasElement, gameClass:Class<GameInterface>, ?params:GameParams = null) {
		super({
			view: canvas,
			width: 900,
			height: 960,
			backgroundColor: 0x80c0e6e9
		});

		this.canvas = canvas;
		this.gameClass = gameClass;
		canvas.width = 900;
		canvas.height = 960;
		isGameStarted = false;

		// Pixi intro

		// this.loader = new Loader();
		loader.add('window_back', "/assets/img/content/default/window_back.png")
			.add('bottom_bar', "/assets/img/content/default/bottom_bar.png")
			.add('kado_icon', "/assets/img/content/default/kado_icon.png")
			.add('game_image', "/assets/img/content/default/default_artwork.jpg");
		for (i in 0...10) {
			loader.add('score_figure_' + i, "/assets/img/content/default/score_figure_" + i + ".svg");
		}
		loader.load(() -> {
			trace("KadoKadeoManager initialized");
			this.showIntroScreen();
		});
		common_haxe_avm1.KeyboardManager.init();

		ff = new FixedFramerate(updatePhysics);

		untyped Ticker.system.add((delta:Float) -> {
			ff.onTick(untyped Ticker.system.elapsedMS);
		});
		this.ticker.add(() -> {
			updateGraphics(ff.alpha);
		});
		this.replay = new ReplayManager(params?.replayData);
	}

	public function updateGraphics(a:Float) {
		if (game != null && isGameStarted) {
			game.updateGraphics(a);
		}
		if (gameOverScreen != null) {
			gameOverScreen.updateGraphics(a);
		}
	}

	public function updatePhysics(dt:Float) {
		mt.Timer.update(js.Browser.window.performance.now());
		replay.update();
		if (game != null && isGameStarted) {
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
		this.stage.addChild(new BottomBar(this));
		replay.start();

		game = Type.createInstance(gameClass, [this]);
		var imageKeys = [for (k in common_haxe_avm1.display.ASprite.spriteData.keys()) k];
		// trace('Preloading images: ' + imageKeys);
		common_haxe_avm1.BmpTextureHelper.preload(imageKeys).then((_) -> {
			try {
				game.start();
			} catch (e:Dynamic) {
				trace(e);
			}
			isGameStarted = true;
		}).catchError(error -> {
			trace('Error while preloading images: ' + error.message);
		});
	}

	public function gameOver(params:Dynamic):Void {
		replay.stop();
		// this.stage.removeChildren();
		gameOverScreen = new GameOver(() -> {
			var txt = new Text("FIN DU JEU", {fill: 0xFF0000});
			txt.x = renderer.width / 2 - txt.width / 2;
			txt.y = renderer.height / 2 - txt.height / 2;
			this.stage.addChild(txt);
		});
		this.stage.addChild(gameOverScreen);
		trace('Game finished, showing end screen');
		trace('Replay data: ' + replay.encodeReplayString());

		var win:Dynamic = js.Browser.window;
		var kado:KadoConfig = cast win.Kado;

		#if !debug
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
			sign: haxe.crypto.Base64.encode(crypto.getHmacSha256(Bytes.ofString(jsonReq))),
		}
		Api.endRun(runDetails.run_id, request, (data:Dto.ApiResponse<Dynamic>) -> {
			trace('Run ended successfully: ' + haxe.Json.stringify(data));
		}, error -> {
			trace('Error ending run: ' + error.message);
		});
		#end
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
		trace('Score updated: ' + score);
	}
}
