package kado;

import js.Browser;
import js.html.CanvasElement;
import js.html.KeyboardEvent;
import js.html.PointerEvent;
import pixi.core.display.Container;
import pixi.core.graphics.Graphics;
import pixi.core.text.Text;

// Replay progress bar at the top of the game, like a video player: click or drag it to go to any moment of the
// replay (backwards too), the time under the pointer is shown over it.
// Keys: left / right arrows -5 / +5 s, J / L -10 / +10 s, Home / End, 0..9 for 0..90 %, Space or K pause.
class ReplaySeekBar extends Container {
	static inline var WIDTH = 600;
	static inline var HIT_HEIGHT = 22;
	static inline var THIN = 4;
	static inline var THICK = 8;
	static inline var RED = 0xFF0033;

	var canvas:CanvasElement;
	var onSeek:Int->Void;
	var onTogglePause:Void->Void;
	var frameMs:Float;

	var shade:Graphics;
	var bar:Graphics;
	var thumb:Graphics;
	var tip:Container;
	var tipBg:Graphics;
	var tipText:Text;
	var timeText:Text;

	var frame:Float = 0;
	var total:Float = 1;
	var totalKnown:Bool = true;
	var seekTarget:Null<Float> = null;

	var hover:Bool = false;
	var hoverX:Float = 0;
	var dragging:Bool = false;
	var dragPointer:Null<Int> = null;
	var grow:Float = 0;

	public function new(canvas:CanvasElement, frameMs:Float, onSeek:Int->Void, onTogglePause:Void->Void) {
		super();
		this.canvas = canvas;
		this.frameMs = frameMs;
		this.onSeek = onSeek;
		this.onTogglePause = onTogglePause;

		shade = new Graphics();
		addChild(shade);
		bar = new Graphics();
		addChild(bar);
		thumb = new Graphics();
		thumb.beginFill(RED);
		thumb.drawCircle(0, 0, 7);
		thumb.endFill();
		addChild(thumb);

		tip = new Container();
		tipBg = new Graphics();
		tip.addChild(tipBg);
		tipText = new Text("0:00", {
			fill: 0xFFFFFF,
			fontFamily: "Arial",
			fontSize: 14,
			fontWeight: "bold"
		});
		tipText.anchor.set(0.5, 0);
		tip.addChild(tipText);
		tip.visible = false;
		addChild(tip);

		// "current / total" on the right while the bar is used
		timeText = new Text("", {
			fill: 0xFFFFFF,
			fontFamily: "Arial",
			fontSize: 13,
			fontWeight: "bold",
			dropShadow: true,
			dropShadowColor: "#000000",
			dropShadowBlur: 3,
			dropShadowDistance: 0
		});
		timeText.anchor.set(1, 0);
		timeText.x = WIDTH - 8;
		addChild(timeText);

		canvas.addEventListener("pointerdown", onPointerDown);
		Browser.window.addEventListener("pointermove", onPointerMove);
		Browser.window.addEventListener("pointerup", onPointerUp);
		Browser.window.addEventListener("pointercancel", onPointerUp);
		Browser.window.addEventListener("keydown", onKeyDown);
		redraw();
	}

	public function dispose():Void {
		canvas.removeEventListener("pointerdown", onPointerDown);
		Browser.window.removeEventListener("pointermove", onPointerMove);
		Browser.window.removeEventListener("pointerup", onPointerUp);
		Browser.window.removeEventListener("pointercancel", onPointerUp);
		Browser.window.removeEventListener("keydown", onKeyDown);
	}

	// called every rendered frame
	public function setProgress(frame:Float, total:Float, totalKnown:Bool):Void {
		this.frame = frame;
		this.total = Math.max(1, total);
		this.totalKnown = totalKnown;
		var target = hover || dragging ? 1.0 : 0.0;
		grow += (target - grow) * 0.35;
		if (Math.abs(target - grow) < 0.01)
			grow = target;
		redraw();
	}

	// frame being reached by a seek (null when done)
	public function setSeeking(target:Null<Int>):Void {
		seekTarget = target;
		redraw();
	}

	public function isSeeking():Bool {
		return seekTarget != null;
	}

	function redraw():Void {
		var h = THIN + (THICK - THIN) * grow;
		var shown = dragging ? frameAt(hoverX) : (seekTarget != null ? seekTarget : frame);
		var px = WIDTH * Math.min(1, shown / total);

		shade.clear();
		if (grow > 0) {
			// darkens the top of the game a little so that the bar reads well
			shade.beginFill(0x000000, 0.28 * grow);
			shade.drawRect(0, 0, WIDTH, 30);
			shade.endFill();
		}

		bar.clear();
		bar.beginFill(0xFFFFFF, 0.32);
		bar.drawRect(0, 0, WIDTH, h);
		bar.endFill();
		if ((hover || dragging) && hoverX > px) {
			bar.beginFill(0xFFFFFF, 0.38);
			bar.drawRect(px, 0, hoverX - px, h);
			bar.endFill();
		}
		bar.beginFill(RED);
		bar.drawRect(0, 0, px, h);
		bar.endFill();

		thumb.x = px;
		thumb.y = h * 0.5;
		thumb.scale.set(grow);
		thumb.visible = grow > 0.05;

		timeText.visible = grow > 0.05 || seekTarget != null;
		if (timeText.visible) {
			timeText.text = format(shown) + " / " + format(total) + (totalKnown ? "" : "+");
			timeText.y = h + 7;
			timeText.alpha = Math.max(grow, seekTarget != null ? 1 : 0);
		}

		tip.visible = hover || dragging || seekTarget != null;
		if (tip.visible) {
			var label:String;
			var tx:Float;
			if (seekTarget != null && !dragging) {
				label = (seekTarget < frame ? "⏪ " : "⏩ ") + format(seekTarget);
				tx = px;
			} else {
				label = format(frameAt(hoverX)) + (totalKnown ? "" : "");
				tx = hoverX;
			}
			tipText.text = label;
			var w = tipText.width + 16;
			tx = Math.max(w * 0.5 + 2, Math.min(WIDTH - w * 0.5 - 2, tx));
			tipBg.clear();
			tipBg.beginFill(0x111111, 0.85);
			tipBg.drawRoundedRect(-w * 0.5, 0, w, tipText.height + 6, 6);
			tipBg.endFill();
			tipText.y = 3;
			tip.x = tx;
			tip.y = h + 6;
		}
	}

	function frameAt(x:Float):Int {
		return Std.int(Math.round(Math.max(0, Math.min(1, x / WIDTH)) * total));
	}

	function format(f:Float):String {
		var s = Std.int(f * frameMs / 1000);
		var m = Std.int(s / 60);
		s = s % 60;
		return m + ":" + (s < 10 ? "0" : "") + s;
	}

	// pointer position in game pixels
	function toGame(e:PointerEvent):{x:Float, y:Float} {
		var r = canvas.getBoundingClientRect();
		if (r.width <= 0 || r.height <= 0)
			return null;
		return {
			x: (e.clientX - r.left) * canvas.width / r.width,
			y: (e.clientY - r.top) * canvas.height / r.height
		};
	}

	function onPointerDown(e:PointerEvent):Void {
		if (parent == null)
			return;
		var p = toGame(e);
		if (p == null || p.y < 0 || p.y > HIT_HEIGHT || p.x < 0 || p.x > WIDTH)
			return;
		e.preventDefault();
		e.stopImmediatePropagation();
		dragging = true;
		dragPointer = e.pointerId;
		hoverX = p.x;
		try {
			canvas.setPointerCapture(e.pointerId);
		} catch (_:Dynamic) {}
		redraw();
	}

	function onPointerMove(e:PointerEvent):Void {
		if (parent == null)
			return;
		var p = toGame(e);
		if (p == null)
			return;
		if (dragging) {
			if (e.pointerId == dragPointer)
				hoverX = Math.max(0, Math.min(WIDTH, p.x));
			return;
		}
		hover = e.pointerType != "touch" && p.y >= 0 && p.y <= HIT_HEIGHT + 6 * grow && p.x >= 0 && p.x <= WIDTH;
		if (hover)
			hoverX = p.x;
	}

	function onPointerUp(e:PointerEvent):Void {
		if (!dragging || e.pointerId != dragPointer)
			return;
		dragging = false;
		dragPointer = null;
		var p = toGame(e);
		if (p != null)
			hoverX = Math.max(0, Math.min(WIDTH, p.x));
		hover = e.pointerType != "touch" && p != null && p.y >= 0 && p.y <= HIT_HEIGHT;
		if (onSeek != null)
			onSeek(frameAt(hoverX));
	}

	function onKeyDown(e:KeyboardEvent):Void {
		if (parent == null)
			return;
		var sec = 1000 / frameMs;
		var from = seekTarget != null ? seekTarget : frame;
		var target:Null<Float> = null;
		switch (e.code) {
			case "ArrowLeft":
				target = from - 5 * sec;
			case "ArrowRight":
				target = from + 5 * sec;
			case "KeyJ":
				target = from - 10 * sec;
			case "KeyL":
				target = from + 10 * sec;
			case "Home":
				target = 0;
			case "End":
				target = total;
			case "Space" | "KeyK":
				if (onTogglePause != null)
					onTogglePause();
				e.preventDefault();
				return;
			default:
				if (e.code != null && e.code.length == 6 && e.code.substr(0, 5) == "Digit") {
					var n = Std.parseInt(e.code.substr(5));
					if (n != null)
						target = total * n / 10;
				}
		}
		if (target == null)
			return;
		e.preventDefault();
		if (onSeek != null)
			onSeek(Std.int(Math.round(Math.max(0, Math.min(total, target)))));
	}
}
