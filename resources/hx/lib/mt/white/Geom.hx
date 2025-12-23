package mt.white;

import common_haxe_avm1.display.PixelDrawer;
import pixi.core.textures.RenderTexture;
import pixi.core.graphics.Graphics;
import pixi.core.math.Matrix;
import pixi.core.math.shapes.Rectangle;
import mt.bumdum.Lib;
import common_haxe_avm1.display.ASprite;
import pixi.core.textures.Texture;

using common_haxe_avm1.PixelHelper;

class Geom {
	public static var DegreesToRadMult = 0.0174;

	public static function degrees(rad:Float) {
		return rad / Math.PI * 180;
	}

	public static function rad(angle:Float, aprox = true) {
		if (aprox)
			return angle * DegreesToRadMult;

		return angle * Math.PI / 180;
	}

	public static function invertHorizontal(mc:ASprite) {
		mc._xscale = -100;
	}

	public static function sin(angle:Float, aprox = true) {
		if (aprox)
			return Math.sin(angle * DegreesToRadMult);

		return Math.sin(angle * Math.PI / 180);
	}

	public static function cos(angle:Float, aprox = true) {
		if (aprox)
			return Math.cos(angle * DegreesToRadMult);

		return Math.cos(angle * Math.PI / 180);
	}

	public static function drawPoint(mc:ASprite, rgb = 0xFFFFFF) {
		mc.lineStyle(1, rgb, 100);

		mc.moveTo(0, 0);

		mc.lineTo(0, 1);
	}

	public static function drawBitmapLine(x0:Int, y0:Int, x1:Int, y1:Int, color:Int, bmp:PixelDrawer) {
		/* Adapté de : http://www.cs.unc.edu/~mcmillan/comp136/Lecture6/Lines.html */

		var dy = y1 - y0;

		var dx = x1 - x0;

		var stepx, stepy;

		if (dy < 0) {
			dy = -dy;
			stepy = -1;
		} else {
			stepy = 1;
		}

		if (dx < 0) {
			dx = -dx;
			stepx = -1;
		} else {
			stepx = 1;
		}

		dy <<= 1;

		dx <<= 1;

		bmp.setPixel32(x0, y0, color);

		if (dx > dy) {
			var fraction:Int = dy - (dx >> 1);

			while (x0 != x1) {
				if (fraction >= 0) {
					y0 += stepy;

					fraction -= dx;
				}

				x0 += stepx;

				fraction += dy;

				bmp.setPixel32(x0, y0, color);
			}
		} else {
			var fraction = dx - (dy >> 1);

			while (y0 != y1) {
				if (fraction >= 0) {
					x0 += stepx;

					fraction -= dy;
				}

				y0 += stepy;

				fraction += dx;

				bmp.setPixel32(x0, y0, color);
			}
		}
	}

	public static function drawLine(mc:Graphics, x:Float, y:Float, rgb:Int = 0xFFFFFF, gradient:Bool = false, thickness:Float = 1.0, alpha:Float = 100) {
		mc.lineStyle(thickness, rgb, alpha);

		mc.moveTo(0, 0);

		mc.lineTo(x, y);
	}

	public static function drawRectangle(mc:Graphics, width:Float, height:Float, frgb:Int = null, falpha = 0, rgb = 0x000000, alpha = 100, thickness = 0) {
		if (frgb != null)
			mc.beginFill(frgb, falpha);

		mc.lineStyle(thickness, rgb, alpha);

		mc.moveTo(0, 0);

		mc.lineTo(width, 0);

		mc.lineTo(width, height);

		mc.lineTo(0, height);

		mc.lineTo(0, 0);

		mc.endFill();
	}

	// Replace dans un contexte horaire l'angle retourné par atan2
	// REMINDER : atan2 travaille dans le sens anti-horaire en démarrant à 90°

	public static function clockWiseAtan2(y:Float, x:Float) {
		return angle360(360 + degrees(Math.atan2(y, x)) + 90);
	}

	// Replace dans un contexte 0-360 l'angle récupéré la valeur de rotation d'un ASprite

	public static function clockWiseAngle(a:Float) {
		if (a >= 0) {
			if (a == 360)
				return 0.0;

			return a;
		}

		return 180 + 180 + a;
	}

	public static function angle360(a:Float) {
		if (a < 0)
			return 360 - a;

		if (a > 360)
			return a - 360;

		return a;
	}

	public static function getMatrix(mc:ASprite, tx = 0.0, ty = 0.0) {
		var m = new Matrix();

		m.translate(mc._x + tx, mc._y + ty);

		return m;
	}

	public static function getRectangle(mc:ASprite, root:ASprite) {
		return mc.getBounds();
	}

	function hsv2rgb(hsv:{h:Int, s:Int, v:Int}):{r:Int, g:Int, b:Int} {
		var s = hsv.s;

		var v = hsv.v;

		var h = hsv.h;

		var r = 0.0;

		var g = 0.0;

		var b = 0.0;

		if (s == 0)
			return {r: Math.round(v * 255), g: Math.round(v * 255), b: Math.round(v * 255)};

		var var_h = h * 6;

		if (var_h == 6)
			var_h = 0; // H must be < 1

		var var_i = Std.int(var_h); // Or ... var_i = floor( var_h )

		var var_1 = v * (1 - s);

		var var_2 = v * (1 - s * (var_h - var_i));

		var var_3 = v * (1 - s * (1 - (var_h - var_i)));

		if (var_i == 0) {
			r = v;
			g = var_3;
			b = var_1;
		} else if (var_i == 1) {
			r = var_2;
			g = v;
			b = var_1;
		} else if (var_i == 2) {
			r = var_1;
			g = v;
			b = var_3;
		} else if (var_i == 3) {
			r = var_1;
			g = var_2;
			b = v;
		} else if (var_i == 4) {
			r = var_3;
			g = var_1;
			b = v;
		} else {
			r = v;
			g = var_1;
			b = var_2;
		}

		return {r: Math.round(r * 255), g: Math.round(g * 255), b: Math.round(b * 255)};
	}

	function rgb2hsv(col:{r:Int, g:Int, b:Int}):{h:Int, s:Int, v:Int} {
		var r = (col.r / 255);

		var g = (col.g / 255);

		var b = (col.b / 255);

		var minVal = min([r, g, b]); // Min. value of RGB

		var maxVal = max([r, g, b]); // Max. value of RGB

		var delta = maxVal - minVal; // Delta RGB value

		var h = 0.0;

		var s = 0.0;

		var v = maxVal;

		if (delta == 0)
			return {h: Math.round(h * 100), s: Math.round(s * 100), v: Math.round(v * 100)};

		s = delta / maxVal;

		var deltaR = (((maxVal - r) / 6) + (delta / 2)) / delta;

		var deltaG = (((maxVal - g) / 6) + (delta / 2)) / delta;

		var deltaBlue = (((maxVal - b) / 6) + (delta / 2)) / delta;

		if (r == maxVal)
			h = deltaBlue - deltaG;
		else if (g == maxVal)
			h = (1 / 3) + deltaR - deltaBlue;
		else if (b == maxVal)
			h = (2 / 3) + deltaG - deltaR;

		if (h < 0)
			h++;

		if (h > 1)
			h--;

		return {h: Math.round(h * 100), s: Math.round(s * 100), v: Math.round(v * 100)};
	}

	function max(values:Array<Float>) {
		var f = values.pop();

		for (v in values) {
			if (v > f) {
				f = v;
			}
		}

		return f;
	}

	function min(values:Array<Float>) {
		var f = values.pop();

		for (v in values) {
			if (v < f) {
				f = v;
			}
		}

		return f;
	}
}
