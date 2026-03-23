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
	public static var kkm:KadoKadeoManager;

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
	var endScene:EndScene = null;
	var bottomBar:BottomBar = null;
	var replayOverlay:ReplayOverlay = null;

	var runDetails:Dto.RunDTO;
	var endRunDetails:Dto.EndRunResponseDTO;
	var crypto:KadoCrypto = new KadoCrypto();
	var params:GameParams;
	var simulationTimeMs:Float = mt.Timer.oldTime;
	var replayElapsedMs:Float = 0;
	var replaySpeed:Float = 1;
	var replayPaused:Bool = false;

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
		KadoKadeoManager.kkm = this;

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
		common_haxe_avm1.MouseManager.init(this);

		ff = new FixedFramerate(updatePhysics);

		untyped Ticker.system.add((delta:Float) -> {
			var speed = replayPaused ? 0 : replaySpeed;
			if (replayPaused) {
				common_haxe_avm1.KeyboardManager.beginFrame();
				common_haxe_avm1.MouseManager.beginFrame();
			}
			ff.onTick(untyped Ticker.system.elapsedMS * speed);
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
		simulationTimeMs += dt;
		mt.Timer.update(simulationTimeMs);
		mt.Timer.deltaT = dt / 1000;
		mt.Timer.calc_tmod = 1;
		mt.Timer.tmod = 1;
		if (game != null) {
			replay.beginFrame();
			gameRoot.update();
			game.update(dt);
			replay.endFrame();
			if (replayOverlay != null && replay.isPlayingReplay() && !replayPaused) {
				replayElapsedMs += dt;
				replayOverlay.updateElapsed(replayElapsedMs);
			}
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
		this.replay.start();
		this.gameRoot = dm.empty(1);
		replayElapsedMs = 0;
		replayPaused = false;
		setReplaySpeed(1);
		var isReplay = this.replay.isPlayingReplay();
		if (isReplay) {
			this.gameRoot.interactive = false;
			this.gameRoot.interactiveChildren = false;
			if (this.replayOverlay == null) {
				this.replayOverlay = new ReplayOverlay(setReplaySpeed, setReplayPaused, replaySpeed, replayPaused);
				this.replayOverlay.x = 12;
				this.replayOverlay.y = 12;
			}
			this.replayOverlay.setSpeed(replaySpeed);
			this.replayOverlay.setPaused(replayPaused);
			this.replayOverlay.updateElapsed(replayElapsedMs);
			this.stage.addChild(this.replayOverlay);
		} else {
			if (this.replayOverlay != null && this.replayOverlay.parent != null) {
				this.replayOverlay.parent.removeChild(this.replayOverlay);
			}
		}

		this.game = Type.createInstance(gameClass, [gameRoot, isReplay]);
	}

	public function gameOver(params:Dynamic):Void {
		this.replay.stop();
		if (this.replayOverlay != null && this.replayOverlay.parent != null) {
			this.replayOverlay.parent.removeChild(this.replayOverlay);
		}
		// this.stage.removeChildren();
		gameOverScreen = new GameOver(() -> {
			// TODO: show loading screen
			makeEndRunHttpRequest().then((endRunDetails:Dto.EndRunResponseDTO) -> {
				gameOverScreen.destroy();
				if (this.endScene != null) {
					this.endScene.dispose();
					if (this.endScene.parent != null) {
						this.endScene.parent.removeChild(this.endScene);
					}
				}
				this.endScene = new EndScene(this, endRunDetails);
				this.stage.addChild(this.endScene);
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
		if (this.endScene != null) {
			this.endScene.dispose();
			this.endScene = null;
		}
		if (this.replayOverlay != null && this.replayOverlay.parent != null) {
			this.replayOverlay.parent.removeChild(this.replayOverlay);
		}
		this.ticker.stop();
		untyped Ticker.system.stop();
		this.game = null;
		this.gameOverScreen = null;
		this.gameRoot = null;
		this.root = null;
		super.destroy(removeView);
	}

	public function setReplaySpeed(speed:Float):Void {
		replaySpeed = Math.max(0.1, speed);
		if (replayOverlay != null) {
			replayOverlay.setSpeed(replaySpeed);
		}
	}

	public function setReplayPaused(paused:Bool):Void {
		replayPaused = paused;
		if (replayOverlay != null) {
			replayOverlay.setPaused(replayPaused);
		}
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
