package electrolink;

import js.Browser;
import js.html.CanvasElement;
import js.lib.Float32Array;
import pixi.core.sprites.Sprite as PixiSprite;
import pixi.core.textures.Texture;

class TextField {
	public var text:String = "";

	public function new() {}
}

// "scoring" (16): its _t (14) slides in from the right and out again over 27 frames (stop() on the last one), with
// an alpha and a horizontal BlurFilter per frame (Data.SCORING_*)
class Scoring extends MC {
	public var _t:ScoringT;

	public function new() {
		super();
		_totalframes = Data.SCORING_X.length;
		_t = cast attach(new ScoringT());
		place();
	}

	override function goto(f:Int):Void {
		super.goto(f);
		place();
	}

	override function advance():Void {
		super.advance();
		if (playing && _currentframe == _totalframes)
			stop();
		place();
	}

	function place():Void {
		_t._x = Data.SCORING_X[_currentframe - 1];
		_t._alpha = Data.SCORING_ALPHA[_currentframe - 1] * 100;
		_t.blur = Data.SCORING_BLUR[_currentframe - 1];
	}
}

// _t: the text fields _pts and _mult (TexasLED 40, GlowFilter + DropShadowFilter) and the static text "PTS".
// Their pictures depend on the texts the code writes: composed here when they are shown, like Flash draws them (the
// glyphs of the SWF font placed like a text field, then the filters as box blurs, the same as electrolink_assets.py)
class ScoringT extends MC {
	public var _pts:TextField = new TextField();
	public var _mult:TextField = new TextField();
	public var blur:Float = 0;

	var pic:PixiSprite;
	var key:String = null;
	var base:TextGfx.Rgba = null;
	var shown:Float = -1;
	var tex:Texture = null;

	public function new() {
		super();
		pic = new PixiSprite(Texture.EMPTY);
		pic.scale.set(1 / Game.K, 1 / Game.K);
		pic.visible = false;
		spr.addChild(pic);
	}

	override function drawn(f:Float):Void {
		var seeking = untyped KadoKadeoManager.kkm.seekTarget != null;
		// the texts are composed as soon as they change (the popup starts invisible: the work is spread over 2 steps)
		var k = _pts.text + "|" + _mult.text;
		if (k != key && !seeking) {
			key = k;
			base = TextGfx.compose(_pts.text, _mult.text);
			shown = -1;
		}
		if (spr._alpha <= 0 || !_visible) {
			pic.visible = false;
			return;
		}
		pic.visible = true;
		var at = TextGfx.origin(blur);
		pic.x = at.x;
		pic.y = at.y;
		// (while a replay seeks, nothing is drawn: the pictures are made when shown)
		if (seeking || base == null)
			return;
		if (blur != shown) {
			shown = blur;
			if (tex != null)
				tex.destroy(true);
			tex = TextGfx.texture(TextGfx.hblur(base, blur));
			pic.texture = tex;
		}
	}

	override public function removeMovieClip():Void {
		if (tex != null)
			tex.destroy(true);
		tex = null;
		super.removeMovieClip();
	}
}
