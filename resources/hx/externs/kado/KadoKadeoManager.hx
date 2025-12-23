package kado;

import pixi.core.Application;

extern class KadoKadeoManager extends Application {
	public static var BASE_URL(default, null):String;

	public static function setBaseUrl(url:String):Void;

	public var canvas:CanvasElement;

	var gameClass:Class<GameInterface>;
	var game:GameInterface;

	var startScene:StartScene;

	public function new(canvas:CanvasElement, gameClass:Class<GameInterface>):KadoKadeoManager;

	public function showIntroScreen() :Void;

	public function finish(): Void;
}
