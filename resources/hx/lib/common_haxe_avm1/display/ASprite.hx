package common_haxe_avm1.display;

import haxe.ds.IntMap;
import haxe.ds.StringMap;
import pixi.core.Application;
import pixi.core.math.Matrix;
import pixi.core.math.Point;
import pixi.core.textures.RenderTexture;
import pixi.core.text.TextStyle;
import pixi.core.text.Text;
import pixi.core.display.Container;
import pixi.core.graphics.Graphics;
import pixi.core.math.shapes.Rectangle;
import pixi.core.sprites.Sprite;
import pixi.core.textures.Texture;

using Std;

typedef TextFieldOptions = {
	@:optional var x:Int;
	@:optional var y:Int;
	@:optional var size:Int;
	@:optional var font:String;
	@:optional var color:Int;
	@:optional var bold:Bool;
	@:optional var align:String;
	@:optional var wordWrap:Int; // Width
	@:optional var dropShadow:String;
	@:optional var stroke:String;
	@:optional var strokeThickness:Int;
}

class TransformState {
	var os:Sprite;

	public var x:Float = 0;
	public var y:Float = 0;
	public var width:Float = 17;
	public var height:Float = 17;
	public var xscale:Float = 1;
	public var yscale:Float = 1;
	public var rotation:Float = 0;
	public var alpha:Float = 1;

	public function new(os:Sprite) {
		this.os = os;
		this.x = os.x;
		this.y = os.y;
		this.xscale = os.scale.x;
		this.yscale = os.scale.y;
		this.rotation = os.rotation;
		this.alpha = os.alpha;
	}

	public inline function copyFrom(o:TransformState) {
		x = o.x;
		y = o.y;
		width = o.width;
		height = o.height;
		xscale = o.xscale;
		yscale = o.yscale;
		rotation = o.rotation;
		alpha = o.alpha;
	}
}

class ASprite extends Sprite {
	static public var app:Application;
	static public var spriteData:StringMap<Array<Int>> = new StringMap();
	static public var spriteAnchor:StringMap<Array<Int>> = new StringMap();
	static public var defaultAnchor:Null<String>;
	static public var ZSORTING_ENABLED:Bool = true;

	public var _xscale(get, set):Float;
	public var _yscale(get, set):Float;
	public var _alpha(get, set):Float;
	public var _visible(get, set):Bool;
	public var _x(get, set):Float;
	public var _y(get, set):Float;
	public var _width(get, null):Float = 17;
	public var _height(get, null):Float = 17;
	public var _name:String;
	public var _rotation(get, set):Float;
	public var _totalframes:Int = 0;
	public var _currentframe(default, null):Int = 1;
	public var _parent(get, set):Container;

	public var _prevState:TransformState;
	public var _curState:TransformState;

	public var onPress(default, set):Void->Void;
	public var onRollOut(default, set):Void->Void;
	public var onRollOver(default, set):Void->Void;
	public var onMouseMove(default, set):Void->Void;
	public var onDragOver:Void->Void; // Fixme
	public var onDragOut:Void->Void; // Fixme
	public var onRelease(default, set):Void->Void;
	public var onReleaseOutside:Void->Void; // Fixme
	public var useHandCursor:Bool;
	public var loop:Bool;

	public var smc:ASprite;
	public var obj:mt.bumdum.Sprite;

	public var _xmouse(get, never):Float;
	public var _ymouse(get, never):Float;

	public var realsize:Point;

	// Simulate actionscript on flash frames
	public var stopOnFrame:Array<Int> = [];
	public var removeOnFrame:Null<Int> = null;
	public var removeObjOnFrame:Null<Int> = null;
	public var onFrame:IntMap<Void->Void> = new IntMap();

	var insideGraphics:Graphics;

	var isPlaying:Bool = false;
	var _zIndex:Int;

	var textures:Array<Texture> = [];

	public var centerX:Bool = false;

	public function new(?data:Array<Int>) {
		super();
		_curState = new TransformState(this);

		if (data != null) {
			_curState.width = data[0];
			_curState.height = data[1];
			if (data.length == 4) {
				realsize = new Point(data[2], data[3]);
			} else {
				realsize = new Point(data[0], data[1]);
			}
		}
	}

	public function get__xmouse():Float {
		return ASprite.app.renderer.plugins.interaction.mouse.global.x;
	}

	public function get__ymouse():Float {
		return ASprite.app.renderer.plugins.interaction.mouse.global.y;
	}

	public function get__parent():Container {
		return parent;
	}

	public function set__parent(parent:Container) {
		this.parent = parent;
		return parent;
	}

	public function clear() {
		while (this.children.length > 0) {
			removeChild(this.children[0]);
		}
		insideGraphics = null;
	}

	public function getGraphics() {
		_initGraphics();
		return insideGraphics;
	}

	private function _initGraphics() {
		if (insideGraphics == null) {
			insideGraphics = new Graphics();
			addChild(insideGraphics);
		}
	}

	public function moveTo(x:Float, y:Float) {
		_initGraphics();
		insideGraphics.moveTo(x, y);
	}

	public function lineStyle(width:Float, color:Int, alpha:Float) {
		_initGraphics();
		insideGraphics.lineStyle(width, color, alpha / 100);
	}

	public function lineTo(x:Float, y:Float) {
		_initGraphics();
		insideGraphics.lineTo(x, y);
	}

	var cachedPixels:PixelHelper;

	public function fullMaxiHitTest(x:Float, y:Float, ?recursive:Bool) {
		if (insideGraphics != null) {
			if (insideGraphics.containsPoint(new Point(x, y))) {
				return true;
			}
		}

		if (realsize == null)
			return false;

		if (x < 0 || y < 0 || x > realsize.x - 1 || y > realsize.y - 1)
			return false;

		if (cachedPixels == null) {
			var texture = RenderTexture.create(this.width, this.height);
			PixelHelper.draw(texture, this, new Matrix());
			cachedPixels = PixelHelper.extract(texture);

			texture.destroy();
		}

		var px = cachedPixels.getPixelAlpha((x + (width - realsize.x) / 2).int(), (y + (height - realsize.y) / 2).int());
		return px != 0;
	}

	public function hitTest(x:Float, y:Float, shapeFlag:Bool) {
		// shapeFlag: Boolean
		// A Boolean value specifying whether to evaluate the entire shape of the specified instance (true), or just the bounding box (false). This parameter can be specified only if the hit area is identified by using x and y coordinate parameters.
		return (x >= _curState.x && y >= _curState.y && x <= _curState.x + this._width && y <= _curState.y + this._height);
	}

	public function startDrag(lockCenter:Bool, left:Float, top:Float, right:Float, bottom:Float) {
		trace("FIXME");
	}

	public function stopDrag() {
		trace("FIXME");
	}

	public function set_onRollOut(v:Void->Void):Void->Void {
		this.onRollOut = v;
		this.interactive = v != null;
		if (v != null) {
			this.removeAllListeners("pointerout");
			this.addListener('pointerout', v);
		}

		return v;
	}

	public function set_onRollOver(v:Void->Void):Void->Void {
		this.onRollOver = v;
		this.interactive = v != null;
		if (v != null) {
			this.removeAllListeners("pointerover");
			this.addListener('pointerover', v);
		}
		return v;
	}

	public function set_onMouseMove(v:Void->Void):Void->Void {
		this.onMouseMove = v;
		this.interactive = v != null;
		if (v != null) {
			this.removeAllListeners("pointermove");
			this.addListener('pointermove', v);
		}
		return v;
		return v;
	}

	public function set_onRelease(v:Void->Void):Void->Void {
		this.onRelease = v;
		this.interactive = v != null;

		if (v != null) {
			this.removeAllListeners("pointerup");
			this.addListener('pointerup', (e) -> {
				e.stopPropagation();
				v();
			});
		}

		return v;
	}

	public function set_onPress(v:Void->Void):Void->Void {
		this.onPress = v;
		this.interactive = v != null;
		if (v != null) {
			this.removeAllListeners("pointerdown");
			this.addListener('pointerdown', (e) -> {
				e.stopPropagation();
				v();
			});
		}

		return v;
	}

	public function get__x() {
		if (centerX)
			return _curState.x + _curState.width / 2;
		return _curState.x;
	}

	public function set__x(v:Float) {
		_curState.x = v;
		if (centerX)
			_curState.x -= _curState.width / 2;
		return v;
	}

	public function get__y()
		return _curState.y;

	public function set__y(v:Float) {
		_curState.y = v;
		return _curState.y;
	}

	public function get__width() {
		return _curState.width;
	}

	public function get__height() {
		return _curState.height;
	}

	public function get__rotation()
		return (_curState.rotation / (Math.PI * 2)) * 360;

	public function set__rotation(v:Float) {
		_curState.rotation = (v / 360) * Math.PI * 2;
		return v;
	}

	public function get__visible()
		return visible;

	public function set__visible(v:Bool) {
		visible = v;
		return visible;
	}

	public function get__alpha()
		return _curState.alpha * 100;

	public function set__alpha(v:Float) {
		_curState.alpha = v / 100;
		return _curState.alpha;
	}

	public function get__xscale()
		return _curState.xscale * 100;

	public function set__xscale(v:Float) {
		_curState.xscale = v / 100;
		return v;
	}

	public function get__yscale()
		return _curState.yscale * 100;

	public function set__yscale(v:Float) {
		_curState.yscale = v / 100;
		return v;
	}

	public function update() {
		updateState();
		for (i in this.children) {
			if (Std.is(i, ASprite)) {
				(cast i).update();
			}
		}

		if (this.isPlaying && this.visible) {
			this.nextFrame();
		}
	}

	public function updateState() {
		if (_prevState == null) {
			_prevState = new TransformState(this);
		}
		_prevState.copyFrom(_curState);
		for (i in this.children) {
			if (Std.is(i, ASprite)) {
				(cast i).updateState();
			}
		}
	}

	public function updateGraphics(a:Float) {
		if (_prevState == null) {
			this.updateState();
		}
		this.position.x = mt.gx.MathEx.lerp(_prevState.x, _curState.x, a);
		this.position.y = mt.gx.MathEx.lerp(_prevState.y, _curState.y, a);
		this._width = mt.gx.MathEx.lerp(_prevState.width, _curState.width, a);
		this._height = mt.gx.MathEx.lerp(_prevState.height, _curState.height, a);
		this.scale.x = mt.gx.MathEx.lerp(_prevState.xscale, _curState.xscale, a);
		this.scale.y = mt.gx.MathEx.lerp(_prevState.yscale, _curState.yscale, a);
		this.rotation = mt.gx.MathEx.lerp(_prevState.rotation, _curState.rotation, a);
		this.alpha = mt.gx.MathEx.lerp(_prevState.alpha, _curState.alpha, a);
		// this.position.x = _prevState.x;
		// this.position.y = _prevState.y;
		// this._width = _curState.width;
		// this._height = _curState.height;
		// this.scale.x = _curState.xscale;
		// this.scale.y = _curState.yscale;
		// this.rotation = _curState.rotation;
		// this.alpha = _curState.alpha;
		for (i in this.children) {
			if (Std.is(i, ASprite)) {
				(cast i).updateGraphics(a);
			}
		}
	}

	static public function _checkHitTestSprite(b1:Rectangle, b2:Rectangle) {
		return b1.contains(b2.x, b2.y)
			|| b1.contains(b2.x + b2.width, b2.y)
			|| b1.contains(b2.x, b2.y + b2.height)
			|| b1.contains(b2.x + b2.width, b2.y + b2.height);
	}

	public function hitTestSprite(other:ASprite) {
		var b1 = other.getBounds();
		var b2 = this.getBounds();

		return _checkHitTestSprite(b1, b2) || _checkHitTestSprite(b2, b1);
	}

	public function load(baseTexture:Texture, ?squareness:Int = 1) {
		// Textures are stacked vertically (or in a square depending of squareness)
		_totalframes = Std.int(baseTexture.height / _curState.height) * squareness;
		for (i in 0..._totalframes) {
			var line = (i % squareness) * _curState.width;
			var col = Math.floor(i / squareness) * _curState.height;
			textures.push(new Texture(baseTexture.baseTexture, new Rectangle(line, col, _curState.width, _curState.height)));
		}

		if (this._currentframe > this._totalframes)
			this._currentframe = this._totalframes;

		// Preserve scaleX / scaleY
		var scaleX = this.scale.x;
		var scaleY = this.scale.y;
		this.texture = textures[this._currentframe - 1];
		this.scale.x = scaleX;
		this.scale.y = scaleY;
	}

	public function prevFrame() {
		if (this._currentframe == 1) {
			stop();
			return;
		}

		this._currentframe--;
		showFrame();
	}

	public function nextFrame() {
		if (this._totalframes == 0) {
			this._currentframe++;
			return;
		}

		if (this._currentframe == this._totalframes) {
			if (!this.loop) {
				stop();
				return;
			} else {
				this._currentframe = 0;
			}
		}

		this._currentframe++;
		showFrame();
	}

	public function attachBitmap(b:Texture, ?depth:Int) {
		var s = new Sprite(b);
		if (depth == null)
			this.addChild(s);
		else {
			if (depth > children.length)
				depth = children.length;
			this.addChildAt(s, depth);
		}
		return s;
	}

	public function removeMovieClip() {
		if (this.parent != null) {
			this.parent.removeChild(this);
		}

		this._name = null; // For DepthManager garbage collection
		for (i in this.children) {
			if (Std.is(i, ASprite))
				(cast i).removeMovieClip();
		}
	}

	public function swapDepths(with:Dynamic) {
		if (Std.is(with, ASprite)) {
			this.parent.swapChildren(this, with);
		} else {
			this._zIndex = with;
			this.zsort();
			// Int
		}
	}

	private function zsort() {
		if (this.parent != null && ASprite.ZSORTING_ENABLED)
			parent.children.sort(function(a, b) return (untyped a)._zIndex - (untyped b)._zIndex);
	}

	public function getDepth():Int {
		return _zIndex;
	}

	public function createEmptyMovieClip(newName:String = "smc", depth:Int = 0):ASprite {
		var t = new ASprite();
		t._zIndex = depth;
		t._name = newName;
		addChild(t);
		t.zsort();
		return t;
	}

	static public function createFromTexture(identifier:String, texture:Texture):ASprite {
		var data = spriteData.get(identifier);
		if (data == null)
			throw 'Trying to load an unknown sprite "$identifier"';
		var a = new ASprite(data);
		a.load(texture);

		return a;
	}

	public function getDefaultAnchor(identifier:String) {
		var anchor = spriteAnchor.get(identifier);
		trace(anchor);
	}

	public function attachMovie(identifier:String, newName:String = "smc", depth:Int = 0, ?squareness:Int):ASprite {
		var data = spriteData.get(identifier);
		if (data == null)
			throw 'Trying to load an unknown sprite "$identifier"';

		// Load texture
		var t:js.lib.Promise<Texture> = (untyped Texture).fromURL('/assets/img/content/$identifier.png');

		var a = new ASprite(data);
		t.then((texture) -> {
			a.load(texture, squareness);
			a.emit("complete");
		});

		addChild(a);

		if (spriteAnchor.exists(identifier)) {
			var anchor = spriteAnchor.get(identifier);
			a.anchor.set(anchor[0] / data[0], anchor[1] / data[1]);
			trace(a.anchor);
		} else if (defaultAnchor == "center") {
			a.anchor.set(0.5, 0.5);
		}

		a._name = newName;
		a._zIndex = depth;
		a.zsort();
		return a;
	}

	public function stop() {
		this.isPlaying = false;
	}

	public function play() {
		this.isPlaying = true;
	}

	public function initTextField(prop:String, ?options:TextFieldOptions) {
		if (Reflect.hasField(this, prop))
			return Reflect.getProperty(this, prop);

		var style = new TextStyle();
		var textField = new Text("");
		addChild(textField);
		Reflect.setField(this, prop, textField);

		if (options != null) {
			if (options.align == 'right') {
				textField.anchor.set(1, 0);
			} else if (options.align == 'center')
				textField.anchor.set(0.5, 0);
			if (options.dropShadow != null) {
				style.dropShadow = true;
				style.dropShadowColor = options.dropShadow;
			}
			if (options.x != null)
				textField.x = options.x;
			if (options.y != null)
				textField.y = options.y;
			if (options.stroke != null)
				style.stroke = options.stroke;
			if (options.strokeThickness != null)
				style.strokeThickness = options.strokeThickness;
			if (options.size != null)
				style.fontSize = options.size;
			if (options.font != null)
				style.fontFamily = options.font;
			if (options.color != null)
				style.fill = options.color;
			if (options.bold != null)
				style.fontWeight = "bold";
			if (options.wordWrap != null) {
				style.wordWrap = true;
				style.wordWrapWidth = options.wordWrap;
			}
		}

		textField.style = style;

		return textField;
	}

	function showFrame() {
		var scale = untyped this.scale.clone();
		this.texture = textures[this._currentframe - 1];
		this.scale.copyFrom(scale);

		if (this.stopOnFrame.contains(this._currentframe)) {
			stop();
		}

		if (this.removeOnFrame == this._currentframe) {
			stop();
			removeMovieClip();
		}
		if (this.removeObjOnFrame == this._currentframe) {
			stop();
			this.obj.kill();
		}

		if (this.onFrame.exists(this._currentframe)) {
			this.onFrame.get(this._currentframe)();
		}
	}

	public function gotoAndStop(frame:Dynamic) {
		if (Std.is(frame, Int)) {
			var f = Std.int(frame);
			if (_totalframes == 0) {
				this._currentframe = f;
				return;
			}

			if (f < 1)
				f = 1;
			else if (f > _totalframes)
				f = _totalframes;

			this._currentframe = f;
			this.isPlaying = false;
			showFrame();
		} else {
			js.Browser.window.console.trace('FIXME: Trying to go to frame name $frame');
		}
	}

	public function gotoAndPlay(frame:Dynamic) {
		gotoAndStop(frame);
		play();
	}
}
