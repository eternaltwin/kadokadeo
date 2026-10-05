package linea;

typedef DOT = {x:Int, y:Int, color32:Int, color:Int, stopped:Bool, started:Bool, a:Float, ready:Bool, merged:Bool, idx:Int, uid:Int}

class Dotter {
	var dots:Array<DOT>;
	var startPos:Int;
	var startAim:Int;
	var margin:Int;
	var plane:TrailBitmap;
	var xSpeed:Int;
	var ySpeed:Int;
	var xMargin:Int;
	var yMargin:Float;
	var sinct:Float;
	var scroll:Int;
	var ldy:Int;
	var width:Float;
	var height:Float;
	var merge:Bool = false;
	var uid:Int;
	var marginThickness:Int;

	public var cannotGoY:Bool = false;

	public function new(root:MC, width:Int, height:Int, xMargin:Int, yMargin:Float, startPos:Int = 0, startAim:Int = 0, margin:Int = 10) {
		plane = new TrailBitmap(width, height);
		root.spr.addChild(plane.sprite);

		dots = new Array();
		sinct = 0;
		marginThickness = 1;
		this.startPos = if (startPos == 0) Math.round(width / 2) else startPos;
		this.startAim = if (startAim == 0) Math.round(width / 6) else startAim;
		this.margin = margin;
		xSpeed = 0;
		ySpeed = 0;
		ldy = 0;
		this.xMargin = xMargin;
		this.yMargin = yMargin;
		this.width = width;
		this.height = height;
		this.scroll = 0;
		this.uid = 0;
	}

	public function addDot(color:Int = 0xFFFFFF) {
		var dot:DOT = cast {};
		var aim = Lambda.filter(dots, function(dot:DOT) {
			return !dot.ready;
		});
		dot.y = startPos + aim.length * 10;
		dot.x = 0;
		dot.a = 0;
		dot.idx = 0;
		dot.uid = uid++;
		// fields never set are undefined in Flash: false in the tests
		dot.stopped = dot.started = dot.ready = dot.merged = false;
		// Col.addAlpha of the original: 0xFF << 24 | color (ARGB; the shared mt.bumdum.Lib version puts the alpha in
		// the low byte, which turned the line colours into others)
		var col = 0xFF000000 | color;
		plane.setPixel32(0, startPos, col);
		dot.color32 = col;
		dot.color = color;
		dots.push(dot);
	}

	public function getFirst() {
		return dots[0];
	}

	public function getReady() {
		return Lambda.filter(dots, function(d:DOT) {
			return d.ready;
		});
	}

	public function getStarted() {
		return Lambda.filter(dots, function(d:DOT) {
			return d.started;
		});
	}

	public function updateSpeed(vx, vy) {
		xSpeed = vx;
		ySpeed = vy;
	}

	public function getLength() {
		return dots.length;
	}

	public function remove(uid:Int) {
		for (d in dots.copy()) {
			if (d.uid == uid)
				dots.remove(d);
		}
	}

	public function update(sx:Int, sy:Int, scr:Int, cbk:DOT->Void) {
		this.scroll = scr;
		plane.scroll(-scroll);

		sinct += 5;
		var varsin = 0.5 * mt.white.Geom.sin(sinct);
		plane.colorTransform(0.98 + varsin / 50, 128);

		var linked = Lambda.filter(dots, function(dot:DOT) {
			return dot.started;
		});
		// (Lambda.filter gave a List in Haxe 1, an Array now)
		var first = linked[0];
		// the group's bounds and the place of a joining line: the lowest line already in the group (the original took
		// the last line started, the joining one too, and gave it the place readyCount * margin, the one of another
		// line if one in the middle broke)
		var last = null;
		for (dot in linked)
			if (dot.ready && (last == null || dot.y > last.y))
				last = dot;
		if (last == null)
			last = linked[linked.length - 1];
		var min = margin;

		// Lignes groupées
		var free = Lambda.filter(dots, function(dot:DOT) {
			return !dot.started;
		});
		var idx = -2;
		var firstWent = false;
		var below = if (last != null && last.ready) last.y - first.y + min else 0;
		for (dot in linked) {
			idx++;
			var dx = 0;
			var dy = 0;

			if (!dot.ready) {
				var dest = if (dot.idx == 0) below else (dot.idx) * min;

				// On est arrivé à la bonne position
				if (Math.abs(first.x - dot.x) <= 3 && Math.abs(first.y + dest - dot.y) <= 3) {
					dot.ready = true;
					dot.x = first.x;
					dot.y = first.y + dest;
					if (dot.idx == 0)
						dot.idx = idx + 1;
					dot.a = idx * 90;
					if (!dot.merged) {
						cbk(dot);
					} else {
						dot.merged = false;
					}
					moveDot(dot, dx, dy);
					continue;
				}

				// Il n'y a pas assez d'espace pour accueillir la nouvelle ligne
				var t = this.height - this.xMargin - (dest << 1);
				if (first.y >= t) {
					moveDot(dot, dx, dy);
					continue;
				}

				// On se dirige vers la bonne position
				// (not rounded: on an axis, cos(atan2(dy, 0)) is 6.1e-17 in every browser, and Math.ceil makes it a
				// 1 px step like in Flash; elsewhere the results are far from an integer)
				var vx = sx * (dot.idx + 1) / 2;
				var vy = sy * (dot.idx + 1) / 2;
				var vary = first.y + dest - dot.y;
				var varx = first.x - dot.x;
				var a = Math.atan2(vary, varx);
				var dx = Math.cos(a) * vx;
				var dy = Math.sin(a) * vy;
				moveDot(dot, Math.ceil(dx), Math.ceil(dy));
				continue;
			}

			if (dot.stopped) {
				moveDot(dot, dx, dy);
				continue;
			}

			// the lines of the group move together (the original moved each one alone, stopping on its own at the
			// margins, while exactly one line was joining: `count == 1` counted those, and the group got squeezed)
			if ((first.y <= (yMargin - marginThickness) && ySpeed > 0)
				|| (dot.idx == first.idx && dot.y <= yMargin - marginThickness && ySpeed > 0)
				|| (dot.y >= this.height - yMargin - marginThickness && ySpeed < 0)
				|| (first.y >= this.height - yMargin - marginThickness && ySpeed < 0)
				|| (last.y >= this.height - yMargin - marginThickness && ySpeed < 0)
				|| (last.y <= this.height - yMargin - marginThickness && first.y >= yMargin && dot.y >= yMargin)
				|| firstWent) {
				if (dot.idx == first.idx)
					firstWent = true;
				dy = ySpeed;
				cannotGoY = false;
			} else {
				if (dot.idx == first.idx)
					firstWent = false;
				dy = 0;
				cannotGoY = true;
			}

			if (dot.x <= xMargin && xSpeed > 0 || (dot.x >= this.height - xMargin && xSpeed < 0) || (dot.x > xMargin && dot.x < this.height - xMargin)) {
				dx = xSpeed;
			}

			// Fusion
			if (dot.color != first.color) {
				if (merge) {
					dy = Math.ceil(mt.white.Geom.sin(dot.a) * 5) + first.y - dot.y;
					dot.a += 45;
					dx = first.x - dot.x - xSpeed;
					dot.merged = true;
				} else {
					if (dot.merged) {
						dot.ready = false;
					}
				}
			}

			moveDot(dot, dx, dy);
		}

		// Lignes non groupées
		for (dot in free) {
			if (dot.x < startAim) {
				moveDot(dot, sx, 0);
				continue;
			}
			dot.started = true;
			moveDot(dot, 0, 0);
		}
	}

	function moveDot(dot:DOT, dx:Int, dy:Int) {
		var x = dot.x;
		var y = dot.y;

		var col = if (dot.ready) dot.color32 else 0x60888888;

		// 1 - déplacement horizontal simple
		if (dy == 0) {
			for (i in 0...scroll + dx) {
				plane.setPixel32(x + i, y, col);
			}
			dot.x += dx;
			ldy = 0;
			return;
		}

		// 2 - déplacement vertical simple
		var x1 = x + scroll;
		var y1 = y + dy;
		plane.setPixel32(x, y, col);
		drawBitmapLine(x, y, x1, y1, col);

		// 3 - smooth (pas optmisé du tout mais bon ça ira)
		if (ldy <= 0) {
			if (dy > 0) {
				plane.setPixel32(x + 2, y + 1, col);
				plane.setPixel32(x + 2, y + 1, col);
				plane.setPixel32(x + 3, y + 1, col);
				plane.setPixel32(x + 2, y + 2, 0x60000000);
			}
		}
		dot.y += dy;
		ldy += dy;
	}

	// mt.white.Geom.drawBitmapLine
	function drawBitmapLine(x0:Int, y0:Int, x1:Int, y1:Int, color:Int) {
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
		plane.setPixel32(x0, y0, color);
		if (dx > dy) {
			var fraction = dy - (dx >> 1);
			while (x0 != x1) {
				if (fraction >= 0) {
					y0 += stepy;
					fraction -= dx;
				}
				x0 += stepx;
				fraction += dy;
				plane.setPixel32(x0, y0, color);
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
				plane.setPixel32(x0, y0, color);
			}
		}
	}

	// display (see TrailBitmap)
	public function frameStart() {
		plane.frameStart();
	}

	public function frameEnd() {
		plane.frameEnd();
	}

	public function display(f:Float) {
		plane.display(f);
	}

	public function destroy() {
		plane.destroy();
	}
}
