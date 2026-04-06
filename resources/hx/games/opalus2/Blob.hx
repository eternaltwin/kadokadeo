package opalus2;

import common_haxe_avm1.KKApi;
import mt.bumdum.Lib;
import mt.bumdum.Phys;
import mt.Timer;
import mt.DepthManager;
import pixi.core.text.Text;

class PanelSprite extends ASprite {
	public var field:Text;
	public var a:Float;
	public var ta:Float;
}

class Blob extends Phys {
	static var RANGE = 1.6;
	static var EPAISSEUR = 2;

	static var FL_SHADE = false;

	var vsx:Float;
	var vsy:Float;

	public var tsx:Float;
	public var tsy:Float;
	public var panel:PanelSprite;

	var trg:{x:Float, y:Float};

	// var turnList:Array<ASprite>
	var dec:Float;
	var rayCoef:Float;

	var shade:ASprite;

	var dm:DepthManager;
	var blobBaseWidth:Float;
	var blobBaseHeight:Float;

	public function new(mc) {
		super(mc);
		vsx = 0;
		vsy = 0;

		panel = cast Cs.game.gdm.attach("mcCounter", 4);
		panel.field = panel.initTextField("field", {
			font: "Arial",
			size: 50,
			color: 0xFFFFFF,
			align: "center",
			y: -30
		});
		panel.field.text = Std.string(KKApi.val(Cs.game.turn));
		panel.a = -2.8; //-0.77
		panel.ta = panel.a;

		if (FL_SHADE)
			shade = Cs.game.gdm.attach("mcBlob", 0);

		dm = new DepthManager(root);

		var sx = (root._xscale == 0) ? 100 : root._xscale;
		var sy = (root._yscale == 0) ? 100 : root._yscale;
		blobBaseWidth = root._width * 100 / sx;
		blobBaseHeight = root._height * 100 / sy;
		if (blobBaseWidth <= 0)
			blobBaseWidth = 100;
		if (blobBaseHeight <= 0)
			blobBaseHeight = 100;

		rayCoef = 1.5;
		frict = 0.85;
	}

	public override function update() {
		towardSpeed(trg, 0.1, 0.2 * Cs.NEW_GEN_SCALE);
		updateScale();
		updatePanel();

		super.update();
		if (FL_SHADE) {
			shade._x = root._x;
			shade._y = root._y;
			shade._xscale = root._xscale + EPAISSEUR * 2;
			shade._yscale = root._yscale + EPAISSEUR * 2;
		}
	}

	public function updatePanel() {
		var rayX = blobBaseWidth * rayCoef;
		var rayY = blobBaseHeight * rayCoef;
		var bpx = x + Math.cos(panel.ta) * rayX;
		var bpy = y + Math.sin(panel.ta) * rayY;
		var m = 16 * Cs.NEW_GEN_SCALE;

		var rec = 1 / 0;
		var nnta = null;
		for (i in 0...2) {
			var sens = i * 2 - 1;
			var nta = panel.ta;
			var px = bpx;
			var py = bpy;
			var tr = 0;
			while (px < m || px > Cs.mcw - m || py < m || py > Cs.mch - m) {
				nta += 0.0314 * sens;
				px = x + Math.cos(nta) * rayX;
				py = y + Math.sin(nta) * rayY;
				if (tr++ > 200)
					break;
			}
			if (tr < rec) {
				rec = tr;
				nnta = nta;
			}
		}
		if (rec < 200)
			panel.ta = nnta;

		var da = Num.hMod(panel.ta - panel.a, 3.14);
		panel.a += da * 0.2 * Timer.tmod;

		panel._x = x + Math.cos(panel.a) * rayX;
		panel._y = y + Math.sin(panel.a) * rayY;
	}

	public function updateScale() {
		var lim = 3 * Cs.NEW_GEN_SCALE;
		var c = 0.12;
		var dsx = tsx - root._xscale;
		vsx += Num.mm(-lim, dsx * c, lim);
		var dsy = tsy - root._yscale;
		vsy += Num.mm(-lim, dsy * c, lim);
		var fs = Math.pow(0.85, Timer.tmod);
		vsx *= fs;
		vsy *= fs;
		root._xscale += vsx * Timer.tmod;
		root._yscale += vsy * Timer.tmod;
		if (root._xscale < 0)
			root._xscale = 0;
		if (root._yscale < 0)
			root._yscale = 0;

		var prc = (root._xscale + root._yscale) / 2;
		if (prc < 50) {
			panel._xscale = prc * 2;
			panel._yscale = prc * 2;
		}
	}

	public function updateSize() {
		var o = Cs.game.zlim;
		var targetWidth = ((o.xmax - o.xmin) + RANGE) * Cs.SIZE;
		var targetHeight = ((o.ymax - o.ymin) + RANGE) * Cs.SIZE;

		trg = {
			x: (((o.xmin + o.xmax) * 0.5) + 0.5) * Cs.SIZE,
			y: (((o.ymin + o.ymax) * 0.5) + 0.5) * Cs.SIZE
		};

		// PATCH
		var ox = x;
		var oy = y;
		x = trg.x;
		y = trg.y;
		var boost = 5;
		for (p in Cs.game.zone) {
			var pos:Point = cast {
				x: p.x * Cs.SIZE,
				y: p.y * Cs.SIZE
			};
			var dist = getDist(pos);
			var a = getAng(pos);

			var dx = Math.cos(a) * targetWidth * 0.5;
			var dy = Math.sin(a) * targetHeight * 0.5;
			var lim = Math.sqrt(dx * dx + dy * dy);
			while (dist > lim - RANGE * Cs.SIZE) {
				// Log.trace("+++")
				targetWidth += Math.abs(Math.cos(a) * boost);
				targetHeight += Math.abs(Math.sin(a) * boost);
				dx = Math.cos(a) * targetWidth * 0.5;
				dy = Math.sin(a) * targetHeight * 0.5;
				lim = Math.sqrt(dx * dx + dy * dy);
			}
		}
		x = ox;
		y = oy;

		tsx = targetWidth * 100 / blobBaseWidth;
		tsy = targetHeight * 100 / blobBaseHeight;
	}
}
