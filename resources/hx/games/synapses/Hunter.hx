package synapses;

import pixi.core.text.Text;
import mt.bumdum.Lib;
import mt.bumdum.Sprite;

class Hunter extends Sprite {
	public var score:Int;

	var angle:Float;

	public var speed:Float;

	public var flExplode:Bool;

	public var action:Void->Void;
	public var col:Int;
	public var trg:{x:Float, y:Float};
	public var first:Element;
	public var layer:Layer;
	public var queue:ASprite;

	var queuePool:Array<ASprite>;
	var queueLife:Array<Float>;
	var queueCursor:Int;

	public var scoreField:Text;

	public function new(col) {
		this.col = col;
		var mc = Game.me.dm.attach("mcHunter", Game.DP_HUNTER);
		super(mc);
		angle = 0;
		Game.me.hunters.push(this);

		x = Cs.rand() * Cs.mcw;
		y = Cs.rand() * Cs.mch;

		speed = 10 * Cs.NEW_GEN_SCALE;
		initQueuePool();

		initPlay();
		scoreField = root.initTextField("field", {
			color: Cs.HUNTER_COLORS[col],
			align: "center",
			font: "Impact",
			size: 36,
		});
		scoreField.y = -20;
	}

	override function update() {
		updateQueuePool();
		action();

		super.update();
	}

	function initQueuePool() {
		queuePool = [];
		queueLife = [];
		queueCursor = 0;
		for (i in 0...9) {
			var mc = Game.me.dm.attach("mcQueue", Game.DP_UNDER_FX);
			mc._visible = false;
			queuePool.push(mc);
			queueLife.push(0);
		}
	}

	function updateQueuePool() {
		for (i in 0...queuePool.length) {
			if (queueLife[i] <= 0)
				continue;
			queueLife[i] -= mt.Timer.tmod;
			if (queueLife[i] <= 0)
				queuePool[i]._visible = false;
		}
	}

	function emitQueue(x:Float, y:Float, len:Float, rot:Float) {
		var i = queueCursor;
		queueCursor = (queueCursor + 1) % queuePool.length;
		var mc = queuePool[i];
		queueLife[i] = 9.0;
		mc._x = x;
		mc._y = y;
		mc._xscale = len / Cs.NEW_GEN_SCALE;
		mc._rotation = rot;
		mc._visible = true;
		mc.gotoAndPlay(1);
		mc.updateState();
	}

	// PLAY
	public function initPlay() {
		score = 0;
		root._visible = true;
		layer = Game.me.newLayer();
		// layer.root.blendMode = "overlay";
		// Filt.glow(layer.root,8,1,0xFFFFFF);

		action = move;
		root.gotoAndStop(col + 1);
	}

	public function move() {
		if (col == 0)
			trg = Game.me.getPlayerTarget();
		else if (trg == null)
			newTrg();

		var dx = trg.x - x;
		var dy = trg.y - y;
		var dist2 = dx * dx + dy * dy;
		var minDist = 20 * Cs.NEW_GEN_SCALE;
		var minDist2 = minDist * minDist;

		if (dist2 > minDist2) {
			var da = Num.hMod(Math.atan2(dy, dx) - angle, 3.14);
			var c = 0.5;
			var lim = 0.8;
			var ba = Num.mm(-lim, da * c, lim) * mt.Timer.tmod;
			var lim2 = Math.abs(da);
			ba = Num.mm(-lim2, ba, lim2);
			angle += ba;

			var ox = x;
			var oy = y;

			x += Math.cos(angle) * speed;
			y += Math.sin(angle) * speed;

			var qdx = ox - x;
			var qdy = oy - y;
			emitQueue(x, y, Math.sqrt(qdx * qdx + qdy * qdy), Math.atan2(qdy, qdx) / 0.0174);

			root._rotation = angle / 0.0174;
		} else {
			if (col > 0)
				newTrg();
		}
	}

	function newTrg() {
		var ray = 20 * Cs.NEW_GEN_SCALE;
		trg = {
			x: ray + Cs.rand() * (Cs.mcw - 2 * ray),
			y: ray + Cs.rand() * (Cs.mch - 2 * ray)
		}
	}

	// RESOLVE
	public function initResolve() {
		action = resolve;
		scoreField.visible = true;

		var el = new Element();
		el.x = x;
		el.y = y;
		el.convert(col);
		el.updatePos();
		if (col > 0)
			el.updateConvert();
		first = el;

		root._rotation = 0;
		root.gotoAndStop(11 + col);
		incScore(0);
	}

	public function resolve() {
		if (first.size == 0 && flExplode) {
			var max = 36;
			for (i in 0...max) {
				var sp = 3 + Math.random() * 8;
				var a = i / max * 6.28;
				var cr = 4;
				var p = new mt.bumdum.Phys(Game.me.dm.attach("partPix", Game.DP_FX));
				p.vx = Math.cos(a) * sp;
				p.vy = Math.sin(a) * sp;
				p.x = x + p.vx * cr;
				p.y = y + p.vy * cr;
				p.updatePos();
				p.timer = 10 + Math.random() * 10;
				p.frict = 0.85;
			}
			kill();
		}

		// for( el in elements )el.seek();
	}

	public function incScore(n) {
		score += n;
		scoreField.text = Std.string(score);
	}

	//
	public function cacheShape() {
		var list = [];
		for (el in Game.me.elements) {
			if (el.col == col) {
				if (el.branch != null) {
					layer.draw(el.branch);
					el.branch.removeMovieClip();
				}
				list.push(el);
			}
		}

		for (el in list) {
			layer.draw(el.root);
			el.kill();
		}
	}

	// KILL
	override function kill() {
		for (mc in queuePool) {
			mc.removeMovieClip();
		}
		layer.kill();
		Game.me.hunters.remove(this);
		super.kill();
	}
}
