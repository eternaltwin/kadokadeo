package loader;

import flash.Boot;
import flash.display.DisplayObjectContainer;
import flash.display.Loader;
import flash.display.MovieClip;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.filters.BitmapFilter;
import flash.filters.BlurFilter;
import flash.filters.ColorMatrixFilter;
import flash.geom.ColorTransform;
import flash.net.URLRequest;
import flash.text.TextField;

public class Init {
	public static var SLIDE_SPEED:int;
	public static var frames:int;
	public var waitServer:WaitServer;
	public var view:MovieClip;
	public var urlScreen:Array;
	public var step:Step;
	public var slideshow:Sprite;
	public var sliders:Array;
	public var loading:Loading;
	public var loader:loader.Loader;
	public var layer:McLayer;
	public var flTitle:Boolean;
	public var filter:BitmapFilter;
	public var bg:Bg;

	public function new(l:loader.Loader = undefined) {
		if (Boot.skip_constructor) {
			return;
		}
		loader = l;
		bg = new Bg();
		l.base.addChild(bg);
		slideshow = new Sprite();
		l.base.addChild(slideshow);
		l.scoreBar = new Score();
		l.scoreBar.visible = false;
		l.base.addChild(l.scoreBar);
		loading = new Loading();
		setView(loading, null);
		step = Step.Load;
		filter = new ColorMatrixFilter([0.6, 0.2, 0.2, 0, 0, 0.2, 0.6, 0.2, 0, 0, 0.2, 0.2, 0.6, 0, 0, 0, 0, 0, 1, 0]);
	}

	public function updateSlideshow():void {
		var c:Number = NaN;
		var ct: * = null
		as
		ColorTransform;
		var _g:int = 0;
		var filter: * = null
		as
		BlurFilter;
		var _g1: * = null
		as
		Array;
		var s: * = null
		as
		Slider;
		if (int(sliders.length) <= 1) {
			return;
		}
		var sl:Slider = sliders[int(sliders.length) - 1];
		--sl.time;
		var lim:int = 8;
		if (sl.time < lim) {
			c = sl.time / lim;
			sl.alpha = Math.pow(c, 0.5);
			sl.filters = [filter];
			if (sl.isTitle) {
				ct = new ColorTransform();
				_g = int((1 - c) * 255);
				ct.color = _g << 16 | _g << 8 | _g;
				sl.transform.colorTransform = ct;
			} else {
				filter = new BlurFilter();
				filter.blurX = (1 - c) * 200;
				sl.filters.push(filter);
				sl.x = -(1 - c) * 50;
			}
		}
		if (sl.time <= 0) {
			sliders.unshift(sliders.pop());
			for (_g = 0,
			_g1 = sliders;
			_g < int(_g1.length);
		)
			{
				s = _g1[_g];
				_g++;
				slideshow.removeChild(s);
				slideshow.addChild(s);
			}
			initSlider(sl);
		}
	}

	public function update():void {
		switch (step.index) {
			case 0:
				null;
				break;
			case 1:
				updateSlideshow();
				if (loader.scoreBar.visible && (loader.scoreBar.click != null && loader.scoreBar.click.label != null)) {
					++Init.frames;
					loader.scoreBar.click.label.text = loader.Loader.TEXT.CLICK_TO_START;
					if (Init.frames < 15) {
						loader.scoreBar.click.visible = true;
					} else if (Init.frames < 25) {
						loader.scoreBar.click.visible = false;
					} else {
						Init.frames = 0;
					}
				}
				break;
			case 2:
				null;
		}
	}

	public function start():void {
		if (waitServer != null) {
			return;
		}
		waitServer = new WaitServer();
		setView(waitServer, start);
		bg.useHandCursor = false;
		loader.scoreBar.gotoAndStop(5);
		layer = new McLayer();
		step = Step.Play;
		if (slideshow.parent != null) {
			slideshow.parent.removeChild(slideshow);
		}
		loader.callServer();
	}

	public function sliderLoaded(_: *):void {
		if (int(sliders.length) < int(urlScreen.length)) {
			addSlider();
		}
	}

	public function setView(mc:MovieClip,:Function):Sprite {
		var clicked:Boolean;
		var zone:Sprite;
		var onclick:Function;
		var bg: * = null
		as
		Bg;
		var doOnClick: * = null
		as
		Function;
		onclick = param2;
		if (view != null && view.parent != null) {
			view.parent.removeChild(view);
			view.visible = false;
		}
		if (bg != null) {
			bg.visible = false;
		}
		view = mc;
		if (view != null) {
			bg.visible = true;
			bg.addChild(mc);
			if (onclick != null) {
				zone = new Sprite();
				bg = bg;
				clicked = false;
				doOnClick = function(_: *):void {
					if (clicked) {
						return;
					}
					clicked = true;
					if (zone.parent != null) {
						zone.parent.removeChild(zone);
					}
					onclick();
				};
				bg.useHandCursor = true;
				zone.useHandCursor = true;
				zone.width = bg.width;
				zone.height = bg.height;
				zone.buttonMode = true;
				zone.hitArea = bg;
				zone.addEventListener(MouseEvent.CLICK, doOnClick);
				loader.base.addChild(zone);
				loader.registerButton(zone);
				return zone;
			}
		} else {
			bg.visible = false;
		}
		return null;
	}

	public function loadProgress(p:Number):void {
		loading.maskXXXX.width = 163 * p;
		loading.bar.mask = loading.maskXXXX;
	}

	public function loadComplete():void {
		var zone:Sprite = setView(new ClickToStart(), start);
		loader.scoreBar.visible = true;
		loader.scoreBar.gotoAndStop(4);
		initSlideshow();
		step = Step.Slide;
	}

	public function initSlideshow():void {
		step = Step.Slide;
		sliders = [];
		urlScreen = loader.init._images.copy();
		if (urlScreen == null || int(urlScreen.length) == 0) {
			return;
		}
		if (loader.init._artwork != null) {
			urlScreen.unshift(loader.init._artwork);
			addSlider(true);
		} else {
			addSlider(false);
		}
	}

	public function initSlider(mc:Slider):void {
		mc.time = Init.SLIDE_SPEED;
		if (mc.isTitle) {
			mc.time *= 3;
		}
		mc.alpha = 1;
		mc.filters = mc.isTitle ? [] : [filter];
		var ct:ColorTransform = new ColorTransform();
		mc.transform.colorTransform = ct;
		mc.x = 0;
	}

	public function displayError(msg:String):void {
		cleanup();
		var error:loader.Error = new loader.Error();
		setView(error, null);
		error.msg.text = msg;
		error.msg.y = 110 + (100 - error.msg.textHeight) / 2;
	}

	public function displayContract():void {
		setView(new Contract(loader), loader.Loader.inst.startGame);
	}

	public function cleanup():void {
		var slide: * = null
		as
		Slider;
		if (sliders != null) {
			while (int(sliders.length) > 0) {
				slide = sliders.pop();
				slide.parent.removeChild(slide);
			}
		}
		if (layer != null && layer.parent != null) {
			layer.parent.removeChild(layer);
		}
		setView(null, null);
	}

	public function addSlider(flTitle:Object = undefined):void {
		var s: * = null
		as
		Slider;
		var url:String = urlScreen[int(sliders.length)];
		if (url == null) {
			return;
		}
		var mc:Slider = new Slider();
		slideshow.addChild(mc);
		mc.isTitle = flTitle;
		initSlider(mc);
		var mcl:flash.display.Loader = new flash.display.Loader();
		mcl.contentLoaderInfo.addEventListener(Event.COMPLETE, (function(param1:Function):Function {
			var f:Function = param1;
			return function(a1: *):void {
				return f(a1);
			};
		})(sliderLoaded));
		mc.addChild(mcl);
		sliders.unshift(mc);
		for (var _g:int = 0,
		var _g1:Array = sliders;
		_g < int(_g1.length);
	)
		{
			s = _g1[_g];
			_g++;
			slideshow.removeChild(s);
			slideshow.addChild(s);
		}
		if (mc.isTitle != true) {
			mc.filters = [filter];
		}
		var req:URLRequest = new URLRequest(url);
		mcl.load(req);
	}
}
