package electrolink;

import pixi.core.Pixi.BlendModes;
import pixi.core.sprites.Sprite as PixiSprite;
import pixi.core.textures.Texture;

// "color" (51): frame 1 a grey square, frame 2 the green pulse, frame 3 the blue pulse (80 frames each, looping on
// their own: smc). It is masked by the pipes and drawn with blendMode "overlay": its pictures are drawn by the
// clip that holds it (TileMC, GoalMC) from the pictures of electrolink_assets.py
class ColorMC extends MC {
	// the pulse (sprite 46 or 50, 80 frames, playing); null on frame 1 (a shape)
	public var smc:MC;

	public function new() {
		super(null, null, 3);
	}

	override function goto(f:Int):Void {
		var old = _currentframe;
		super.goto(f);
		// another frame: the clip at depth 1 is replaced (a new pulse starts on its frame 1)
		if (_currentframe != old) {
			if (smc != null)
				smc.removeMovieClip();
			smc = null;
			if (_currentframe > 1) {
				smc = new MC(null, null, Data.PULSE_GREEN.length);
				smc.playing = true;
			}
		}
	}

	// colour of the square on the current frame (frames 2 and 3)
	public function colour():Int {
		var p = smc._currentframe - 1;
		return _currentframe == 2 ? Data.PULSE_GREEN[p] : Data.PULSE_BLUE[p];
	}

	// mc.smc.smc.smc.gotoAndPlay(...): nothing when there is no pulse (undefined in Flash)
	public function syncPulse(f:Null<Int>):Void {
		if (smc != null && f != null)
			smc.gotoAndPlay(f);
	}

	public function pulseFrame():Null<Int> {
		return smc != null ? smc._currentframe : null;
	}

	override public function removeMovieClip():Void {
		if (smc != null)
			smc.removeMovieClip();
		super.removeMovieClip();
	}
}

// a piece whose pipe holds a ColorMC: picture of the grey state, or picture A + picture B (blendMode ADD, tinted
// with the colour of the pulse) for the lit states: exactly the "overlay" of the colour on the pipe
class Piece {
	var grey:Texture;
	var a:Texture;
	public var main:PixiSprite;
	public var plus:PixiSprite;

	public function new(holder:ASprite, name:String, scale:Float) {
		grey = Tex.get(name + "Grey")[0];
		a = Tex.get(name + "A")[0];
		main = sprite(holder, name + "Grey", scale);
		plus = sprite(holder, name + "B", scale);
		plus.blendMode = BlendModes.ADD;
	}

	public static function sprite(holder:ASprite, anim:String, scale:Float):PixiSprite {
		var t = Tex.get(anim)[0];
		var s = new PixiSprite(t);
		s.anchor.copyFrom(t.defaultAnchor);
		s.scale.set(scale, scale);
		holder.addChild(s);
		return s;
	}

	public function show(color:ColorMC):Void {
		var lit = color._currentframe > 1;
		var t = lit ? a : grey;
		if (main.texture != t) {
			main.texture = t;
			main.anchor.copyFrom(t.defaultAnchor);
		}
		plus.visible = lit;
		if (lit)
			plus.tint = color.colour();
	}
}

// "shapes" (64): one frame per kind of tile, its color clip (smc) and the GlowFilters Tile.update puts on it
class ShapesMC extends MC {
	public var smc:ColorMC;
	// Filt.glow(m, 10, 2, 0xFFFFFF) + Filt.glow(m, 2, 2, 0xFFFFFF, true)
	public var charged:Bool = false;

	public function new() {
		super(null, null, 5);
		smc = new ColorMC();
		smc.playing = true;
	}

	override function goto(f:Int):Void {
		var old = _currentframe;
		super.goto(f);
		// every frame of "shapes" places its own color clip
		if (_currentframe != old) {
			smc.removeMovieClip();
			smc = new ColorMC();
			smc.playing = true;
		}
	}

	override public function removeMovieClip():Void {
		if (smc != null)
			smc.removeMovieClip();
		super.removeMovieClip();
	}
}

// "tile" (66): bg + shapes (smc). The mouse handlers of Tile.activate are called by Buttons
class TileMC extends MC {
	public var smc:ShapesMC;
	// Tile.tileOver: mc.filters = [GlowFilter]; tileOut: mc.filters = null
	public var hoverGlow:Bool = false;

	var glow:ASprite;
	var halo:PixiSprite;
	var piece:Piece;
	var kind:Int = 0;

	public function new() {
		super();
		smc = new ShapesMC();
		// the glow is drawn in stage orientation: it is counter-rotated (interpolated like the tile)
		glow = new ASprite();
		glow.visible = false;
		spr.addChild(glow);
		Piece.sprite(spr, "tileBg", 1 / Game.K);
	}

	// the half side of the square of the tile (shape 8): the hit area of the button
	override public function hitTest(x:Float, y:Float):Bool {
		var a = -_rotation * Math.PI / 180;
		var dx = x - _x;
		var dy = y - _y;
		var lx = (dx * Math.cos(a) - dy * Math.sin(a)) / (_xscale / 100);
		var ly = (dx * Math.sin(a) + dy * Math.cos(a)) / (_yscale / 100);
		return lx >= Data.TILE_HIT[0] && lx < Data.TILE_HIT[1] && ly >= Data.TILE_HIT[2] && ly < Data.TILE_HIT[3];
	}

	override function drawn(f:Float):Void {
		if (kind != smc._currentframe) {
			// (the kind of a tile never changes: built once)
			kind = smc._currentframe;
			halo = Piece.sprite(spr, "halo" + kind, 1 / Game.K);
			piece = new Piece(spr, "shape" + kind, 1 / Game.K);
		}
		halo.visible = smc.charged;
		piece.show(smc.smc);
		glow.visible = hoverGlow;
		if (hoverGlow) {
			// picture computed for the scale and rotation (mod 90) shown
			var r = spr._rotation;
			var m = ((r % 90) + 90) % 90;
			var best = 0;
			var bd = 1e9;
			for (i in 0...Data.HOVER_ROT.length) {
				var d = Math.abs(Data.HOVER_SCALE[i] * 100 - spr._xscale) * 10 + Math.min(Math.abs(Data.HOVER_ROT[i] - m), 90 - Math.abs(Data.HOVER_ROT[i] - m));
				if (d < bd) {
					bd = d;
					best = i;
				}
			}
			var t = Tex.get("hover" + best)[0];
			if (glow.texture != t) {
				glow.texture = t;
				glow.anchor.copyFrom(t.defaultAnchor);
			}
			// the picture already holds the rotation (mod 90) and the scale, in stage orientation: undo the tile's
			glow._rotation = -r;
			glow._xscale = glow._yscale = 100 / Game.K * 100 / spr._xscale;
		}
	}

	override public function removeMovieClip():Void {
		smc.removeMovieClip();
		super.removeMovieClip();
	}
}

// "goal" (75): plug + connect + color clip (smc, overlay), drawn at 70 % (1.4 texture pixels per unit)
class GoalMC extends MC {
	public var smc:ColorMC;
	// Goal.charge: Filt.glow(mc, 10, 2, 0xFFFFFF); unLight: mc.filters = []
	public var glow:Bool = false;

	var glowSpr:PixiSprite;
	var piece:Piece;

	public function new() {
		super();
		smc = new ColorMC();
		smc.playing = true;
		glowSpr = Piece.sprite(spr, "goalGlow", 1 / Data.GOAL_RES);
		piece = new Piece(spr, "goal", 1 / Data.GOAL_RES);
	}

	override function drawn(f:Float):Void {
		glowSpr.visible = glow;
		piece.show(smc);
	}

	override public function removeMovieClip():Void {
		smc.removeMovieClip();
		super.removeMovieClip();
	}
}

// "part1": a white dot of 2 frames (looping), coloured by Col.setColor and drawn with blendMode "add". Its vertical
// scale is baked in the pictures (part<yscale>): only the horizontal one changes (Phys fadeType 5)
class Part extends MC {
	var sy:Float = -1;

	public function new() {
		super();
		_totalframes = 2;
		playing = true;
		add = true;
	}

	override function drawn(f:Float):Void {
		if (sy != _yscale) {
			sy = _yscale;
			frames = Tex.get("part" + Std.int(sy));
			showFrame();
		}
		spr._yscale = 100 / Game.K;
	}
}

// "timeLine" (70) and its _timeLeft (68), scaled by Game.updateTime
class TimeLine extends MC {
	public var _timeLeft:TimeLeft;
	// mcTime.start: the time of the start of the game (Game.getTimer), increased by the exploded tiles
	public var start:Float;

	public function new() {
		// (a container: its own picture is a child, under _timeLeft)
		super();
		Piece.sprite(spr, "timeLine", 1 / Game.K);
		_timeLeft = cast attach(new TimeLeft());
	}
}

class TimeLeft extends MC {
	public var _width(get, never):Float;
	public var _height(get, never):Float;

	public function new() {
		super("timeLeft");
	}

	function get__width():Float {
		return Data.TIME_LEFT_W * Math.abs(_xscale) / 100;
	}

	function get__height():Float {
		return Data.TIME_LEFT_H * Math.abs(_yscale) / 100;
	}
}
