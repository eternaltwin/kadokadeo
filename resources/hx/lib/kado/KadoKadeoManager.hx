package kado;

import pixi.loaders.Loader;
import js.html.CanvasElement;
import pixi.core.Application;
import pixi.core.text.Text;

@:expose("KadoKadeo")
class KadoKadeoManager extends Application {
	public static var BASE_URL(default, null):String = "https://kadokadeo.eternaltwin.org/";

	public static function setBaseUrl(url:String) {
		BASE_URL = url;
	}

	// public var loader:Loader;
	public var canvas:CanvasElement;

	var gameClass:Class<GameInterface>;
	var game:GameInterface = null;
    var ff:FixedFramerate;

	var startScene:StartScene;

	public function new(canvas:CanvasElement, gameClass:Class<GameInterface>) {
		super({
			view: canvas,
			width: 900,
			height: 960,
			backgroundColor: 0xCDCDCD
		});

		this.canvas = canvas;
		this.gameClass = gameClass;
		canvas.width = 900;
		canvas.height = 960;

		// Pixi intro
		// this.loader = new Loader();
		loader.add("/assets/img/content/default/window_back.png")
			.add("/assets/img/content/default/bottom_bar.png")
			.add("/assets/img/content/default/default_artwork.jpg")
			.load(() -> {
				trace("KadoKadeoManager initialized");
				this.showIntroScreen();
			});
		common_haxe_avm1.KeyboardManager.init();

		ff = new FixedFramerate((delta) -> {
            if (game != null) {
                game.update(delta);
            }
		});

		this.ticker.add(ff.onTick);
	}

	public function showIntroScreen() {
		startScene = new StartScene(this);
		startScene.interactive = true;
		startScene.once("pointerdown", e -> {
			Api.askContract(data -> {
				startScene.showContract(data.data);
				startScene.interactive = true;
				startScene.once("pointerdown", e -> {
					this.stage.removeChild(startScene);
					game = Type.createInstance(gameClass, [this]);
					game.start();
				});
			}, error -> {});
			startScene.disable();
		});
		this.stage.addChild(startScene);
	}

	public function finish() {
		this.stage.removeChildren();
		var txt = new Text("FIN DU JEU", {fill: 0x00FF00});
		txt.x = 250;
		txt.y = 250;
		this.stage.addChild(txt);
		trace('Game finished, showing end screen');
	}

	override public function destroy(?removeView:Bool):Void {
        super.destroy(removeView);
		this.ticker.remove(ff.onTick);
	}
}
