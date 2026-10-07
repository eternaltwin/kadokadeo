package happyptitank;

import haxe.io.Bytes;
import js.lib.Uint8Array;

/*
	Original AS3 source code from Troy Gilbert
	(http://troygilbert.com/category/game-dev/)

	Port: the original draws both objects into BitmapData (BitmapData.draw with their matrices to the common parent)
	and looks for a pixel where both alphas are drawn (getColorBoundsRect(0x010100) on the alpha of one in red, of the
	other in green: the lowest bit of both alphas). That reads the rendering: here every picture has a mask from the SWF
	(4 samples per Flash pixel, Data.masks) and a pixel of the grid of the intersection rectangle is drawn by an object
	when one of its 4 x 4 samples falls inside one of the object's visible pictures (Flash's anti-aliasing samples a
	pixel 4 x 4 in high quality; any coverage gives an odd alpha, 255 * n / 16 truncated). draw() ignores the object's
	own visibility, alpha and colour, not the ones of its children.
 */
class Collision {
	/**
	   Get the collision rectangle between two display objects.
	**/
	public static function getCollisionRect(target1:DisplayObject, target2:DisplayObject, commonParent:DisplayObject, pixelPrecise:Bool = false,
			tolerance:Int = 0):Rect {
		// find the intersection of the two bounding boxes
		var intersectionRect = target1.getBounds(commonParent).intersection(target2.getBounds(commonParent));
		if (!intersectionRect.isEmpty()) {
			if (pixelPrecise) {
				// size of rect needs to integer size for bitmap data
				var w = Math.ceil(intersectionRect.width);
				var h = Math.ceil(intersectionRect.height);
				var p1 = pictures(target1, commonParent);
				var p2 = pictures(target2, commonParent);
				for (j in 0...h) {
					var py = intersectionRect.y + j;
					for (i in 0...w) {
						var px = intersectionRect.x + i;
						if (pixelDrawn(p1, px, py) && pixelDrawn(p2, px, py))
							return Rect.make(px, py, 1, 1);
					}
				}
				return new Rect();
			}
			return intersectionRect;
		}
		return null;
	}

	/**
	   Are the two display objects colliding (overlapping)?
	**/
	public static function isColliding(target1:DisplayObject, target2:DisplayObject, commonParent:DisplayObject, pixelPrecise:Bool = false,
			tolerance:Int = 0):Bool {
		var collisionRect = getCollisionRect(target1, target2, commonParent, pixelPrecise, tolerance);
		return (collisionRect != null && !collisionRect.isEmpty());
	}

	// ---------------------------------------------------------------- port: the masks
	// the visible pictures of an object, with the matrix from the common parent's space to the mask's samples
	static function pictures(o:DisplayObject, space:DisplayObject):Array<Pic> {
		var out:Array<Pic> = [];
		var m = o.matrixTo(space);
		collect(o, m, out, true);
		return out;
	}

	static function collect(o:DisplayObject, m:Mat, out:Array<Pic>, top:Bool) {
		if (!top && (!o.visible || o.alpha <= 0))
			return;
		var l = Std.downcast(o, Leaf);
		if (l != null) {
			var D = l.data();
			if (D.mask == null)
				return;
			var mk = mask(D.mask);
			// space -> leaf -> mask samples (4 per unit from the mask's origin)
			var inv = m.invert();
			var k = new Mat(4, 0, 0, 4, -4 * (D.mox : Float), -4 * (D.moy : Float)).mul(inv);
			out.push({m: k, mask: mk});
			return;
		}
		var s = Std.downcast(o, Sprite);
		if (s != null)
			for (c in s.children)
				collect(c, c.concat(m), out, false);
	}

	static inline function pixelDrawn(pics:Array<Pic>, px:Float, py:Float):Bool {
		var hit = false;
		for (p in pics) {
			var k = p.m;
			var mk = p.mask;
			for (sj in 0...4) {
				var sy = py + (sj + 0.5) / 4;
				for (si in 0...4) {
					var sx = px + (si + 0.5) / 4;
					var mx = Math.floor(k.a * sx + k.c * sy + k.tx);
					var my = Math.floor(k.b * sx + k.d * sy + k.ty);
					if (mx >= 0 && my >= 0 && mx < mk.w && my < mk.h && mk.bits[my * mk.w + mx] != 0) {
						hit = true;
						break;
					}
				}
				if (hit)
					break;
			}
			if (hit)
				break;
		}
		return hit;
	}

	static var masks:Array<MaskBits> = [];

	static function mask(i:Int):MaskBits {
		if (masks[i] != null)
			return masks[i];
		var M:Dynamic = Data.get().masks[i];
		var w:Int = M.w;
		var h:Int = M.h;
		var bits = new Uint8Array(w * h);
		var rle = haxe.crypto.Base64.decode(M.rle);
		var p = 0;
		for (y in 0...h) {
			var n = rle.get(p++);
			var x = 0;
			var drawn = false;
			for (r in 0...n) {
				var len = 0;
				var b = 255;
				while (b == 255) {
					b = rle.get(p++);
					len += b;
				}
				if (drawn)
					for (i in x...x + len)
						bits[y * w + i] = 1;
				x += len;
				drawn = !drawn;
			}
			if (drawn)
				for (i in x...w)
					bits[y * w + i] = 1;
		}
		var mb = {w: w, h: h, bits: bits};
		masks[i] = mb;
		return mb;
	}
}

typedef Pic = {m:Mat, mask:MaskBits};
typedef MaskBits = {w:Int, h:Int, bits:Uint8Array};
