package kado;

import mt.DepthManager;
import common_haxe_avm1.display.ASprite;
import pixi.loaders.Loader;
import js.lib.Promise;
import js.Browser;
import js.html.CanvasElement;
import js.html.CustomEvent;
import haxe.CallStack;
import kado.KadoRunFlow.RunStartContext;
import kado.Seed;
import kado.TouchControlsOverlay.TouchJoystickState;
import kado.TouchControlsConfig.TouchControlsConfig;
import kado.TouchControlsConfig.TouchControlsMode;
import pixi.core.Application;
import pixi.core.ticker.Ticker;

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
	var touchOverlay:TouchControlsOverlay = null;

	var runDetails:Dto.RunDTO;
	var endRunDetails:Dto.EndRunResponseDTO;
	var crypto:KadoCrypto = new KadoCrypto();
	var endRunClient:KadoEndRun;
	var runFlow:KadoRunFlow;
	var params:GameParams;
	var hasPhysicsCrashReported:Bool = false;
	var simulationTimeMs:Float = mt.Timer.oldTime;
	var replayElapsedMs:Float = 0;
	var replaySpeed:Float = 1;
	var replayPaused:Bool = false;

	var fpsText:pixi.core.text.Text;
	var fpsFrames:Int = 0;
	var fpsSampleStartMs:Float = 0;

	public var sheet:pixi.core.textures.Spritesheet;

	public var score:Int = 0;

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
		this.endRunClient = new KadoEndRun(crypto);
		this.runFlow = new KadoRunFlow(params);
		canvas.width = 900;
		canvas.height = 960;
		this.root = new ASprite();
		this.dm = new DepthManager(root);
		this.stage.addChild(root);
		KadoKadeoManager.kkm = this;
		Api.baseUrl = Browser.window.location.origin;

		// Pixi intro

		// this.loader = new Loader();
		loader.add('kkm', "/assets/img/content/default/kkm-0.json");
		loader.load(() -> {
			this.sheet = loader.resources["kkm"].spritesheet;
			loadFonts().then((e:Dynamic) -> {
				trace("KadoKadeoManager initialized");
				runFlow.transition(Intro, "assets-loaded");
				this.showIntroScreen();
				// score = 31300;
				// this.gameOver({});
			});
		});
		common_haxe_avm1.KeyboardManager.init();
		common_haxe_avm1.MouseManager.init(this);

		ff = new FixedFramerate(updatePhysics);
		initDebugFpsDisplay();

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
			updateDebugFpsDisplay();
			pixi.core.Pixi.tweenManager.update();
		});
		this.replay = new ReplayManager(params?.replayData);
	}

	function initDebugFpsDisplay():Void {
		fpsSampleStartMs = Browser.window.performance.now();
		fpsText = new pixi.core.text.Text("FPS: --", {
			fill: 0xFFFFFF,
			fontFamily: "Arial",
			fontSize: 24,
			align: "right"
		});
		fpsText.x = 790;
		fpsText.y = 12;
		#if !debug
		fpsText.visible = false;
		#end
		this.stage.addChild(fpsText);
	}

	function updateDebugFpsDisplay():Void {
		if (fpsText == null || !fpsText.visible) {
			return;
		}
		fpsFrames++;
		var now = Browser.window.performance.now();
		var elapsed = now - fpsSampleStartMs;
		if (elapsed >= 250) {
			var fps = fpsFrames * 1000 / elapsed;
			fpsText.text = "FPS: " + Std.int(fps + 0.5);
			fpsFrames = 0;
			fpsSampleStartMs = now;
		}
	}

	function destroyDebugFpsDisplay():Void {
		if (fpsText != null) {
			if (fpsText.parent != null) {
				fpsText.parent.removeChild(fpsText);
			}
			fpsText.destroy();
			fpsText = null;
		}
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
		if (hasPhysicsCrashReported) {
			return;
		}
		if (common_haxe_avm1.KeyboardManager.isJustDown(common_haxe_avm1.KeyboardManager.F8)) {
			fpsText.visible = !fpsText.visible;
		}
		try {
			simulationTimeMs += dt;
			mt.Timer.update(simulationTimeMs);
			mt.Timer.deltaT = dt / 1000;
			mt.Timer.calc_tmod = 1;
			mt.Timer.tmod = 1;
			if (runFlow.state == Playing && game != null) {
				pollGameTouchControls();
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
		} catch (e:Dynamic) {
			reportPhysicsCrash(e);
			throw e;
		}
	}

	function reportPhysicsCrash(error:Dynamic):Void {
		if (hasPhysicsCrashReported) {
			return;
		}
		hasPhysicsCrashReported = true;

		var message:String = Std.string(error);
		if (Reflect.hasField(error, "message")) {
			var rawMessage:Dynamic = Reflect.field(error, "message");
			if (rawMessage != null) {
				message = Std.string(rawMessage);
			}
		}

		var stack = CallStack.toString(CallStack.exceptionStack());
		if (stack == null || stack.length == 0) {
			stack = CallStack.toString(CallStack.callStack());
		}

		trace('Physics crash: ' + message);
		if (stack != null && stack.length > 0) {
			trace(stack);
		}

		emitWindowEvent("gameCrash", {
			message: message,
			stack: stack,
			name: params.name,
			gameId: params.gameId,
			runState: Std.string(runFlow.state),
			score: score,
			timestamp: Date.now().toString()
		});
	}

	public function showIntroScreen() {
		runFlow.transition(Intro, "show-intro");

		var replayContext = runFlow.createReplayContext();
		if (replayContext != null) {
			applyRunContext(replayContext);
			startGame();
			return;
		}

		#if debug
		applyRunContext(runFlow.createDebugContext());
		startGame();
		return;
		#end
		startScene = new StartScene(this, params.name);
		startScene.interactive = true;
		startScene.once("pointerdown", e -> {
			runFlow.transition(ContractLoading, "request-contract");
			runFlow.requestContract((context) -> {
				applyRunContext(context);
				startScene.showContract(context.runDetails);
				runFlow.transition(ReadyToStart, "contract-received");
				startScene.interactive = true;
				startScene.once("pointerdown", startGame);
			}, (message) -> {
				runFlow.transition(Intro, "contract-failed");
				trace('Contract failed: ' + message);
			});
			startScene.disable();
		});
		this.stage.addChild(startScene);
	}

	inline function applyRunContext(context:RunStartContext):Void {
		runDetails = context.runDetails;
		Seed.init(context.seedHash);
	}

	function startGame() {
		runFlow.transition(Playing, "start-game");
		if (startScene != null) {
			if (startScene.parent != null) {
				startScene.parent.removeChild(startScene);
			}
			startScene.destroy({children: true});
			startScene = null;
		}
		var loader:Loader = untyped PIXI.Loader.shared;

		var b = dm.empty(2);
		this.bottomBar = new BottomBar(this, runDetails);
		b.addChild(this.bottomBar);
		var assetName = '/assets/img/content/' + this.params.name + '/' + this.params.name + '-0.json';
		if (loader.resources[assetName] != null) {
			beginGame();
		} else {
			loader.add(assetName).load(() -> {
				beginGame();
			});
		}
	}

	private function loadFonts() {
		var fonts = [
			"Fredoka Bold",
			"Chubby Cheeks",
			"GAU",
			"Orbitron",
			"Junegull-Regular",
			"Jost-Medium",
			"LCD",
			"IronMan",
		];
		return Promise.all(fonts.map(font -> Browser.window.document.fonts.load("16px " + font)));
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

		this.score = 0;
		this.game = Type.createInstance(gameClass, [gameRoot, isReplay]);
		setupTouchOverlay();
	}

	function displayEndScene(endRunDetails:Dto.EndRunResponseDTO) {
		runFlow.transition(EndScreen, "display-end-scene");
		reset(true);
		this.endScene = new EndScene(this, endRunDetails);
		this.stage.addChild(this.endScene);
		this.endScene.once('replay', () -> {
			runFlow.transition(ReplayTransition, "replay-clicked");
			reset();
			this.showIntroScreen();
		});
	}

	public function reset(?preserveScore:Bool = false):Void {
		replay.stop();
		destroyTouchOverlay();
		replayElapsedMs = 0;
		replayPaused = false;
		replaySpeed = 1;
		if (!preserveScore) {
			score = 0;
		}
		common_haxe_avm1.KeyboardManager.clearState();
		common_haxe_avm1.MouseManager.clearState();

		if (game != null) {
			game.destroy();
			game = null;
		}

		if (startScene != null) {
			if (startScene.parent != null) {
				startScene.parent.removeChild(startScene);
			}
			startScene.destroy({children: true});
			startScene = null;
		}

		if (gameOverScreen != null) {
			if (gameOverScreen.parent != null) {
				gameOverScreen.parent.removeChild(gameOverScreen);
			}
			gameOverScreen.destroy({children: true});
			gameOverScreen = null;
		}

		if (endScene != null) {
			if (endScene.parent != null) {
				endScene.parent.removeChild(endScene);
			}
			endScene.dispose();
			endScene.destroy({children: true});
			endScene = null;
		}

		if (bottomBar != null) {
			if (bottomBar.parent != null) {
				bottomBar.parent.removeChild(bottomBar);
			}
			bottomBar.destroy({children: true});
			bottomBar = null;
		}

		if (replayOverlay != null) {
			if (replayOverlay.parent != null) {
				replayOverlay.parent.removeChild(replayOverlay);
			}
			replayOverlay.destroy({children: true});
			replayOverlay = null;
		}

		if (gameRoot != null) {
			if (gameRoot.parent != null) {
				gameRoot.parent.removeChild(gameRoot);
			}
			gameRoot.destroy({children: true});
			gameRoot = null;
		}

		mt.bumdum.Sprite.clearAll();
	}

	public function gameOver(params:Dynamic):Void {
		var wasInReplay = this.replay.isPlayingReplay();
		this.replay.stop();
		destroyTouchOverlay();
		if (this.replayOverlay != null && this.replayOverlay.parent != null) {
			this.replayOverlay.parent.removeChild(this.replayOverlay);
		}
		// this.stage.removeChildren();
		gameOverScreen = new GameOver(() -> {
			if (wasInReplay) {
				runFlow.transition(EndScreen, "replay-ended");
				this.displayEndScene({
					is_best: false,
					previous_star: -1,
					current_star: -1,
					people_to_beat: -1,
				});
			} else {
				// TODO: show loading screen
				runFlow.transition(SubmittingRun, "submit-end-run");
				makeEndRunHttpRequest().then((endRunDetails:Dto.EndRunResponseDTO) -> {
					this.displayEndScene(endRunDetails);
					emitWindowEvent("gameFinished", endRunDetails);
				}).catchError((_) -> {
					// TODO: show error
					trace(_);
				});
			}
		});
		this.stage.addChild(gameOverScreen);
		// trace('Game finished, showing end screen');
		#if debug
		trace('Replay data: ' + replay.encodeReplayString());
		#end
	}

	override public function destroy(?removeView:Bool):Void {
		this.stop();
		reset();
		destroyDebugFpsDisplay();
		this.ticker.stop();
		untyped Ticker.system.stop();
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
		emitWindowEvent("score", {score: score});
	}

	private function emitWindowEvent(eventName:String, ?detail:Dynamic):Void {
		var win:Dynamic = Browser.window;
		if (win == null || !Reflect.hasField(win, "evts")) {
			return;
		}
		var evts:Dynamic = Reflect.field(win, "evts");
		untyped evts.dispatchEvent(new CustomEvent(eventName, {detail: detail}));
	}

	private function makeEndRunHttpRequest():Promise<Dto.EndRunResponseDTO> {
		#if !debug
		return endRunClient.submit(runFlow.getRunDetails(), score, runFlow.currentTimestamp(), replay.encodeReplayString()).then((data) -> {
			endRunDetails = data;
			return endRunDetails;
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

	function setupTouchOverlay():Void {
		if (this.replay.isPlayingReplay() || !isTouchEnvironment()) {
			return;
		}

		var config:TouchControlsConfig = getTouchControlsConfig();
		if (config == null || config.mode == TouchControlsMode.NONE) {
			return;
		}

		destroyTouchOverlay();
		touchOverlay = new TouchControlsOverlay(canvas, config, {
			onKeyDown: (keyCode:Int) -> {
				common_haxe_avm1.KeyboardManager.queueVirtualKeyDown(keyCode);
			},
			onKeyUp: (keyCode:Int) -> {
				common_haxe_avm1.KeyboardManager.queueVirtualKeyUp(keyCode);
			},
			onJoystick: (nx:Float, ny:Float, active:Bool) -> {
				common_haxe_avm1.MouseManager.queueInputCallback(() -> dispatchTouchJoystick(nx, ny, active));
			},
			onAction: (action:String) -> {
				common_haxe_avm1.MouseManager.queueInputCallback(() -> dispatchTouchAction(action));
			}
		});
	}

	function destroyTouchOverlay():Void {
		if (touchOverlay != null) {
			touchOverlay.destroy();
			touchOverlay = null;
		}
	}

	function getTouchControlsConfig():TouchControlsConfig {
		var raw = Reflect.field(gameClass, "TOUCH_CONTROLS");
		if (raw == null) {
			return null;
		}
		return cast raw;
	}

	function dispatchTouchJoystick(nx:Float, ny:Float, active:Bool):Void {
		if (game == null) {
			return;
		}
		var fn = Reflect.field(game, "onTouchJoystick");
		if (fn != null) {
			Reflect.callMethod(game, fn, [nx, ny, active]);
		}
	}

	function dispatchTouchAction(action:String):Void {
		if (game == null) {
			return;
		}
		var fn = Reflect.field(game, "onTouchAction");
		if (fn != null) {
			Reflect.callMethod(game, fn, [action]);
		}
	}

	public function getTouchJoystickState():Null<TouchJoystickState> {
		if (touchOverlay == null) {
			return null;
		}
		return touchOverlay.getJoystickState();
	}

	function pollGameTouchControls():Void {
		if (game == null) {
			return;
		}
		var fn = Reflect.field(game, "pollTouchControls");
		if (fn != null) {
			Reflect.callMethod(game, fn, []);
		}
	}

	function isTouchEnvironment():Bool {
		var nav:Dynamic = Browser.navigator;
		if (nav != null && Reflect.hasField(nav, "maxTouchPoints")) {
			var points:Dynamic = Reflect.field(nav, "maxTouchPoints");
			if (points != null && points > 0) {
				return true;
			}
		}

		var hasTouchEvent = Reflect.hasField(Browser.window, "ontouchstart");
		if (hasTouchEvent) {
			return true;
		}

		var matchMedia = Browser.window.matchMedia;
		if (matchMedia != null) {
			return matchMedia("(pointer: coarse)").matches;
		}
		return false;
	}
}
