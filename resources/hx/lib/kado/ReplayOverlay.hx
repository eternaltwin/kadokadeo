package kado;

import common_haxe_avm1.display.ASprite;
import pixi.core.text.Text;
import js.Browser;
import js.html.KeyboardEvent;

class ReplayOverlay extends ASprite {
	static inline var WIDTH = 332;
	static inline var HEIGHT = 88;
	static inline var MINI_WIDTH = 118;
	static inline var MINI_HEIGHT = 34;
	static inline var BUTTON_W = 56;
	static inline var BUTTON_H = 24;

	var onSpeedSelected:Float->Void;
	var onPauseToggled:Bool->Void;
	var speedText:Text;
	var timeText:Text;
	var buttons:Array<{speed:Float, button:ASprite, label:Text}>;
	var pauseButton:ASprite;
	var pauseLabel:Text;
	var minimizeButton:ASprite;
	var minimizeLabel:Text;
	var titleText:Text;
	var selectedSpeed:Float;
	var paused:Bool;
	var minimized:Bool;

	public function new(onSpeedSelected:Float->Void, onPauseToggled:Bool->Void, initialSpeed:Float, initialPaused:Bool = false) {
		super();
		this.onSpeedSelected = onSpeedSelected;
		this.onPauseToggled = onPauseToggled;
		this.buttons = [];
		this.selectedSpeed = initialSpeed;
		this.paused = initialPaused;
		this.minimized = true;

		drawBackground();
		initTexts();
		initButtons();
		initHeaderButtons();
		setSpeed(initialSpeed);
		setPaused(initialPaused);
		updateElapsed(0);
		applyMinimizedState();
		Browser.window.addEventListener("keydown", onKeyDown);
	}

	public function setSpeed(speed:Float):Void {
		selectedSpeed = speed;
		speedText.text = "Vitesse: " + speedLabel(speed);
		for (entry in buttons) {
			redrawButton(entry.button, entry.speed == selectedSpeed);
			entry.button.setChildIndex(entry.label, entry.button.children.length - 1);
		}
	}

	public function updateElapsed(elapsedMs:Float):Void {
		timeText.text = "Temps: " + formatElapsed(elapsedMs);
	}

	public function setPaused(value:Bool):Void {
		paused = value;
		pauseLabel.text = paused ? "PLAY" : "PAUSE";
		redrawSmallButton(pauseButton, paused ? 0x2F6F3D : 0x5B3A16, paused ? 0xDAFFD8 : 0xFFEFCB);
		pauseButton.setChildIndex(pauseLabel, pauseButton.children.length - 1);
	}

	function drawBackground():Void {
		var g = getGraphics();
		g.clear();
		g.beginFill(0x0D2130, 0.82);
		g.drawRect(0, 0, minimized ? MINI_WIDTH : WIDTH, minimized ? MINI_HEIGHT : HEIGHT);
		g.endFill();
		g.lineStyle(2, 0x6AB5CF, 0.9);
		g.drawRect(0, 0, minimized ? MINI_WIDTH : WIDTH, minimized ? MINI_HEIGHT : HEIGHT);
	}

	function initTexts():Void {
		titleText = new Text("REPLAY", {
			fill: 0xE8FBFF,
			fontFamily: "Fredoka Bold",
			fontSize: 20,
			align: "left"
		});
		titleText.x = 12;
		titleText.y = 8;
		addChild(titleText);

		speedText = new Text("Vitesse: 1x", {
			fill: 0xD7F3FF,
			fontFamily: "Arial",
			fontSize: 14,
			align: "left"
		});
		speedText.x = 12;
		speedText.y = 36;
		addChild(speedText);

		timeText = new Text("Temps: 00:00", {
			fill: 0xD7F3FF,
			fontFamily: "Arial",
			fontSize: 14,
			align: "left"
		});
		timeText.x = 160;
		timeText.y = 36;
		addChild(timeText);
	}

	function initHeaderButtons():Void {
		pauseButton = new ASprite();
		pauseButton.x = WIDTH - 128;
		pauseButton.y = 6;
		pauseButton.useHandCursor = true;
		addChild(pauseButton);

		pauseLabel = new Text("PAUSE", {
			fill: 0xFFEFCB,
			fontFamily: "Arial",
			fontSize: 12,
			align: "center"
		});
		pauseLabel.anchor.set(0.5);
		pauseLabel.x = 38;
		pauseLabel.y = 10;
		pauseButton.addChild(pauseLabel);
		pauseButton.onPress = function() {
			setPaused(!paused);
			if (onPauseToggled != null) {
				onPauseToggled(paused);
			}
		};

		minimizeButton = new ASprite();
		minimizeButton.x = WIDTH - 44;
		minimizeButton.y = 6;
		minimizeButton.useHandCursor = true;
		addChild(minimizeButton);

		minimizeLabel = new Text("-", {
			fill: 0xDDF7FF,
			fontFamily: "Arial",
			fontSize: 16,
			align: "center"
		});
		minimizeLabel.anchor.set(0.5);
		minimizeLabel.x = 16;
		minimizeLabel.y = 10;
		minimizeButton.addChild(minimizeLabel);
		minimizeButton.onPress = function() {
			minimized = !minimized;
			applyMinimizedState();
		};

		redrawSmallButton(minimizeButton, 0x194F62, 0xDDF7FF, 32, 20);
		minimizeButton.setChildIndex(minimizeLabel, minimizeButton.children.length - 1);
	}

	function initButtons():Void {
		var values = [0.25, 0.5, 1.0, 2.0, 4.0];
		for (i in 0...values.length) {
			var value = values[i];
			var btn = new ASprite();
			btn.x = 12 + i * (BUTTON_W + 8);
			btn.y = 56;
			btn.useHandCursor = true;
			addChild(btn);

			var label = new Text(speedLabel(value), {
				fill: 0xEAF9FF,
				fontFamily: "Arial",
				fontSize: 13,
				align: "center"
			});
			label.anchor.set(0.5);
			label.x = BUTTON_W * 0.5;
			label.y = BUTTON_H * 0.5;
			btn.addChild(label);

			var speedValue = value;
			btn.onPress = function() {
				if (onSpeedSelected != null) {
					onSpeedSelected(speedValue);
				}
			};

			buttons.push({
				speed: speedValue,
				button: btn,
				label: label,
			});
		}
	}

	function redrawButton(button:ASprite, isSelected:Bool):Void {
		var g = button.getGraphics();
		g.clear();
		g.lineStyle(1, isSelected ? 0xFFF5C0 : 0x9ED9EE, 1);
		g.beginFill(isSelected ? 0x2C748E : 0x1E4D61, 1);
		g.drawRect(0, 0, BUTTON_W, BUTTON_H);
		g.endFill();
	}

	function redrawSmallButton(button:ASprite, fill:Int, stroke:Int, ?w:Int = 76, ?h:Int = 20):Void {
		var g = button.getGraphics();
		g.clear();
		g.lineStyle(1, stroke, 1);
		g.beginFill(fill, 1);
		g.drawRect(0, 0, w, h);
		g.endFill();
	}

	function applyMinimizedState():Void {
		drawBackground();
		speedText.visible = !minimized;
		timeText.visible = !minimized;
		for (entry in buttons) {
			entry.button.visible = !minimized;
		}
		pauseButton.visible = !minimized;

		if (minimized) {
			titleText.y = 6;
			minimizeButton.x = MINI_WIDTH - 24;
			minimizeLabel.text = "+";
			minimizeLabel.x = 10;
			redrawSmallButton(minimizeButton, 0x194F62, 0xDDF7FF, 20, 20);
		} else {
			titleText.y = 8;
			minimizeButton.x = WIDTH - 44;
			minimizeLabel.text = "-";
			minimizeLabel.x = 16;
			redrawSmallButton(minimizeButton, 0x194F62, 0xDDF7FF, 32, 20);
		}
		minimizeButton.setChildIndex(minimizeLabel, minimizeButton.children.length - 1);
	}

	function onKeyDown(e:KeyboardEvent):Void {
		if (parent == null)
			return;

		if (e.keyCode == 80) {
			setPaused(!paused);
			if (onPauseToggled != null) {
				onPauseToggled(paused);
			}
			e.preventDefault();
			return;
		}

		if (e.keyCode == 77) {
			minimized = !minimized;
			applyMinimizedState();
			e.preventDefault();
		}
	}

	function speedLabel(speed:Float):String {
		if (speed == 0.25)
			return "0.25x";
		if (speed == 0.5)
			return "0.5x";
		if (speed == 1)
			return "1x";
		if (speed == 2)
			return "2x";
		if (speed == 4)
			return "4x";
		return Std.string(speed) + "x";
	}

	function formatElapsed(elapsedMs:Float):String {
		var totalSeconds = Std.int(Math.floor(elapsedMs / 1000));
		var minutes = Std.int(totalSeconds / 60);
		var seconds = totalSeconds % 60;
		var minTxt = minutes < 10 ? "0" + minutes : Std.string(minutes);
		var secTxt = seconds < 10 ? "0" + seconds : Std.string(seconds);
		return minTxt + ":" + secTxt;
	}
}
