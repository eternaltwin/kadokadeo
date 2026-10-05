package interwheel;

import mt.bumdum.Lib.Num;
import mt.DepthManager;
import mt.Timer;

class Wheel extends Element {
	var flDestroy:Bool;

	public var a:Float;
	public var speed:Float;
	public var mList:Array<{mc:ASprite, a:Float}>;
	public var id:Int;

	var fr:Int;
	var aBoom:Float;
	var wh:ASprite;
	var sh:ASprite;
	var light:ASprite;

	public function new(id:Int) {
		super();
		a = 0;
		speed = (Seed.random(2) * 2 - 1) * (0.1 + Seed.rand() * 0.1);
		skin = "mcWheel";
		fr = Seed.randomVfx(5) + 1;
		mList = new Array();
		this.id = id;
	}

	override function update() {
		super.update();
		a = Num.q(a + speed * Timer.tmod);
		wh._rotation = a / 0.0174;
		sh._rotation = wh._rotation;
		if (Cs.game.blob.step == 1) {
			if (Num.q(Cs.game.blob.getDist(this)) < ray + Blob.RAY) {
				for (o in mList) {
					var ba = Num.q(Cs.game.blob.getAng(this) + 3.14);
					var da = Num.q(Num.hMod((o.a + a) - ba, 3.14));
					if (Num.q(Math.abs(da) * ray) < Cs.MINE_SPACE) {
						Cs.game.blob.explode(ba);
						//
						var x = Num.q(x + Math.cos(a + o.a) * ray);
						var y = Num.q(y + Math.sin(a + o.a) * ray);
						var mcExp = Cs.game.dm.attach("mcExplosion", Game.DP_PART);
						mcExp.play();
						mcExp._x = x;
						mcExp._y = y;
						mcExp._xscale = 50;
						mcExp._yscale = 50;

						// PART MINE
						for (n in 0...5) {
							var p = new Part(Cs.game.dm.attach("partMine", Game.DP_PART));
							var a = ba + (Seed.randVfx() * 2 - 1) * 1.57; // Math.random()*6.28
							var ray = 4;
							var sp = 1 + Seed.randVfx() * 4;
							var ca = Math.cos(a);
							var sa = Math.sin(a);
							p.x = x + ca * ray;
							p.y = y + sa * ray;
							p.vx = ca * sp;
							p.vy = sa * sp;
							p.setScale(80 + Seed.randVfx() * 40);
							p.weight = 0.1 + Seed.randVfx() * 0.2;
							p.fadeType = 0;
							p.timer = 10 + Seed.randVfx() * 30;
							p.vr = (Seed.randVfx() * 2 - 1) * 20;
							p.root._rotation = Seed.randVfx() * 360;
							p.root.gotoAndStop(Seed.randomVfx(p.root._totalframes) + 1);
						}
						// SMOKE
						for (n in 0...6) {
							var p = new Part(Cs.game.dm.attach("partSmoke", Game.DP_PART));
							var a = Seed.randVfx() * 6.28;
							var sp = 0.5 + Seed.randVfx() * 2;
							p.x = x;
							p.y = y;
							p.vx = Math.cos(a) * sp;
							p.vy = Math.sin(a) * sp;
							p.frict = 0.95;
							p.setScale(80 + Seed.randVfx() * 60);
							p.weight = -(0.1 + Seed.randVfx() * 0.3);
							p.timer = 10 + Seed.randVfx() * 20;
							p.vr = (Seed.randVfx() * 2 - 1) * 12;
							p.root._rotation = Seed.randVfx() * 360;
							p.root.play();
							p.updatePos();
						}
						// TACHE MUR
						for (n in 0...4) {
							var p = new Part(Cs.game.dm.attach("partWallTache", Game.DP_BG));
							var a = ba + (Seed.randVfx() * 2 - 1) * 1.57;
							var sp = Seed.randVfx() * 36;
							p.x = x + Math.cos(a) * sp;
							p.y = y + Math.sin(a) * sp;
							p.weight = Seed.randVfx() * 0.01;
							p.setScale(50 + Seed.randVfx() * 50);
							p.root._rotation = Seed.randVfx() * 360;
							p.root.gotoAndStop(Seed.randomVfx(p.root._totalframes) + 1);
							p.updatePos();
						}
						// GROSSE TACHE
						{
							var p = new Part(Cs.game.dm.attach("mcStarTache", Game.DP_BG));
							p.x = x;
							p.y = y;
							p.vs = 30;
							p.sFrict = 0.65;
							p.root._rotation = Seed.randVfx() * 360;
							p.setScale(40);
							p.updatePos();
						}

						// TACHE SUR ROUE
						var ldm = new DepthManager(wh);
						var base = ldm.empty(4);
						var mask = ldm.attach("mcMask", 4);
						mask.gotoAndStop(fr);
						base.mask = mask;
						var bdm = new DepthManager(base);
						var bx = Math.cos(o.a) * 50;
						var by = Math.sin(o.a) * 50;
						var scm = 100 / (ray * 2);
						for (n in 0...4) {
							var p = new Part(bdm.attach("partWallTache", 0));
							var a = o.a + 3.14 + (Seed.randVfx() * 2 - 1) * 1.57;
							var sp = (Seed.randVfx() * 10) * scm;
							p.x = bx + Math.cos(a) * sp;
							p.y = by + Math.sin(a) * sp;
							p.setScale((50 + Seed.randVfx() * 60) * scm);
							p.root._rotation = Seed.randVfx() * 360;
							p.root.gotoAndStop(Seed.randomVfx(p.root._totalframes) + 1);
						}

						// YEUX
						{
							var mc = Cs.game.dm.attach("mcEyes", Game.DP_BG);
							mc._x = x;
							mc._y = y;
							mc._rotation = ba / 0.0174;
						}
						o.mc.removeMovieClip();
						flDestroy = true;
						aBoom = o.a;
						return;
					}
				}
				Cs.game.blob.cw = this;
				Cs.game.blob.initStep(2);
			};
		}

		// if (flDestroy) {
		// 	speed = Num.q(speed * Math.pow(0.97, Timer.tmod));
		// 	// tit'gouttes
		// 	var ca = Math.cos(a + aBoom);
		// 	var sa = Math.sin(a + aBoom);
		// 	if (Seed.randVfx() / Timer.tmod < speed * 5) {
		// 		var p = new Part(Cs.game.dm.attach("partOil", Game.DP_PART));
		// 		var dist = ray - (5 + Seed.randVfx() * 5);
		// 		p.x = x + ca * dist;
		// 		p.y = y + sa * dist;
		// 		p.weight = 0.1 + Seed.randVfx() * 0.1;
		// 		p.setScale(80 + Seed.randVfx() * 80);
		// 		p.fadeType = 0;
		// 		p.timer = 10 + Seed.randVfx() * 20;
		// 		p.updatePos();
		// 	}
		// }
	}

	public override function attach() {
		if (root != null)
			return;
		super.attach();
		var dm = new DepthManager(root);

		sh = Cs.game.dm.attach("mcMask", Game.DP_SHADE);
		sh._x = x;
		sh._y = y + KadoKadeoManager.I(6);
		sh._alpha = 20;
		sh.gotoAndStop(fr);

		var dust = dm.attach("mcDust", 0);
		dust.loop = true;
		dust.play();

		wh = dm.empty(0);

		light = dm.attach("mcWheelLight", 0);
		light.gotoAndStop(fr);

		wh._xscale = ray * 2 / KadoKadeoManager.I(1);
		wh._yscale = ray * 2 / KadoKadeoManager.I(1);
		sh._xscale = ray * 2 / KadoKadeoManager.I(1);
		sh._yscale = ray * 2 / KadoKadeoManager.I(1);
		dust._xscale = ray;
		dust._yscale = ray;
		if (fr == 2) {
			light._xscale = ray * 2 / KadoKadeoManager.I(1);
			light._yscale = ray * 2 / KadoKadeoManager.I(1);
		}

		var wdm = new DepthManager(wh);
		var wheelScale = wh._xscale;
		var mineVisualScale = Math.max(50, Math.min(wheelScale, 80));
		var mineLocalScale = mineVisualScale * 100 / wheelScale;
		for (o in mList) {
			var c = 100 / wh._xscale;
			o.mc = wdm.attach("mcMine", 0); // Std.attachMC(root,"mcMine"+i,i)//
			// o.mc.getGraphics()
			// 	.clear()
			// 	.beginFill(0xFF0000, 0.5)
			// 	.drawCircle(0, 0, c * 100 / KadoKadeoManager.I(1))
			// 	.endFill();

			o.mc._x = Math.cos(o.a) * ray * c;
			o.mc._y = Math.sin(o.a) * ray * c;
			o.mc._xscale = mineLocalScale;
			o.mc._yscale = o.mc._xscale;
			o.mc._rotation = o.a / 0.0174;
		}
		var skin = wdm.attach("mcWheelBase", 0);
		skin.gotoAndStop(fr);
	}

	public override function detach() {
		super.detach();
		sh.removeMovieClip();
	}

	public function addMine() {
		var perim = 6.28 * ray;
		if (mList.length > 0 && perim / mList.length < Cs.MINE_SPACE * 2)
			return;

		var tr = 0;
		var a:Float = 0;
		while (true) {
			var flBreak = true;
			a = Num.q(Seed.rand() * 6.28);
			for (o in mList) {
				var da:Float = Num.q(Math.abs(Num.hMod(o.a - a, 3.14)));
				if (Num.q(da * ray) < Cs.MINE_SPACE) {
					flBreak = false;
					break;
				}
			}
			if (tr++ > 20)
				return;
			if (flBreak)
				break;
		}
		mList.push({a: a, mc: null});
		/*
			var max = int((2*ray*Math.PI)/Cs.MINE_SPACE)
			if(mList.length==max-1)return;

		 */
	}
}
