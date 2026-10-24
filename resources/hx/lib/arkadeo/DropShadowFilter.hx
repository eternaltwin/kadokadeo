package arkadeo;

// flash.filters.DropShadowFilter, drawn by the DropShadowFilter of pixi-filters (outer shadow: inner and knockout are not
// drawn; the box blur of Flash as a gaussian blur of the same size)
class DropShadowFilter extends BitmapFilter {
	public var distance:Float;
	public var angle:Float;
	public var color:Int;
	public var alpha:Float;
	public var blurX:Float;
	public var blurY:Float;
	public var strength:Float;
	public var quality:Int;
	public var inner:Bool;
	public var knockout:Bool;
	public var hideObject:Bool;

	public function new(distance:Float = 4, angle:Float = 45, color:Int = 0, alpha:Float = 1, blurX:Float = 4, blurY:Float = 4, strength:Float = 1,
			quality:Int = 1, inner:Bool = false, knockout:Bool = false, hideObject:Bool = false) {
		this.distance = distance;
		this.angle = angle;
		this.color = color;
		this.alpha = alpha;
		this.blurX = blurX;
		this.blurY = blurY;
		this.strength = strength;
		this.quality = quality;
		this.inner = inner;
		this.knockout = knockout;
		this.hideObject = hideObject;
	}

	override public function toPixi():Dynamic {
		return new common_haxe_avm1.pixi.DropShadowFilter({
			distance: distance,
			rotation: angle,
			color: color,
			alpha: Math.min(1, alpha * strength),
			shadowOnly: hideObject,
			blur: Math.max(blurX, blurY) / 4,
			quality: quality,
		});
	}

	override public function clone():BitmapFilter {
		return new DropShadowFilter(distance, angle, color, alpha, blurX, blurY, strength, quality, inner, knockout, hideObject);
	}
}
