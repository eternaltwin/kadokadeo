package cosmocrash;

// Plat.hx of the original: a launch platform. The colonists dropped on it walk into its shuttle one by one; full, the
// shuttle takes off (the ramp's timeline calls launch on its frame 74) and a new one comes back later.
class Plat {
	public var step:Int;
	public var nextTimer:Int;
	public var capacity:Int;
	public var shuttleLevel:Int;

	static var SIDE = 10;

	public var flUp:Null<Bool>;

	public var x:Float;
	public var y:Float;
	public var ray:Float;

	var nextFolk:Folk;

	// skin: shade, rampe (digit, shuttle, smc), pil0, pil1, base, left, right
	public var skin:MC;

	// skin.rampe._x (set below, never moved by a timeline)
	public var rampeX:Float;

	public function new(x:Float, y:Float, ray:Float) {
		this.x = x;
		this.y = y;
		this.ray = ray;
		skin = Game.me.dm.attach("mcPlat", Game.DP_PLAT);
		skin.cullR = 110;
		// Reflect.setField(skin, "_launch", launch)
		skin.clip.onLaunch = launch;

		// PLATEFORME
		var baseScale = ray * 2 - 2 * SIDE;
		skin.setSub("base", null, null, baseScale);
		skin.setSub("right", ray - SIDE);
		skin.setSub("left", SIDE - ray);

		// PILLIER
		var pr = ray - 15;
		skin.setSub("pil0", -pr);
		skin.setSub("pil1", pr);

		// SHADE: skin.shade.smc._xscale = skin.base._xscale (smc at the origin of shade, untransformed: the same as
		// scaling shade, which the export keeps as one picture)
		skin.setSub("shade", null, null, baseScale);

		// RAMPE
		rampeX = 8 + Game.me.seed.random(Std.int(ray * 2 - 38)) - ray;
		skin.setSub("rampe", rampeX);
		skin._x = x;
		skin._y = y;
		Game.me.plats.push(this);

		shuttleLevel = 0;

		newShuttle();
	}

	inline function rampe():Clip {
		return skin.sub("rampe");
	}

	public function getWaypoint(folk:Folk):Null<Float> {
		if (step == 0) {
			if (nextFolk == folk) {
				// SC
				var sc = Cs.SCORE_FOLK[folk.type];
				Game.me.fxScore(x + rampeX + 10, y - 25, KKApi.val(sc));
				Game.me.addScore(sc);
				rampe().gotoAndPlay("close");
				var smc = rampe().getClip("smc");
				if (smc != null)
					smc.gotoAndPlay("_face");
				folk.applySkin(smc);
				folk.kill();
				nextFolk = null;
				incCapacity(-1);
				if (capacity == 0)
					takeOf();
				return null;
			}
			if (nextFolk == null) {
				rampe().gotoAndPlay("open");
				nextFolk = folk;

				return rampeX + 10;
			}
		}

		return (Seed.rand() * 2 - 1) * ray;
	}

	public function takeOf() {
		step = 1;
		rampe().gotoAndPlay("takeOf");
		var s = rampe().getClip("shuttle");
		if (s != null)
			s.gotoAndPlay("open");
	}

	public function incCapacity(inc:Int) {
		capacity += inc;
		var d = rampe().getClip("digit");
		if (d != null)
			d.gotoAndStop(capacity + 1);
	}

	// skin._launch (frame 74 of the ramp)
	public function launch() {
		#if debug
		Game.me.stats.launches++;
		#end
		shuttleLevel++;
		if (shuttleLevel > 5)
			shuttleLevel = 5;
		var sc = KKApi.cmult(KKApi.const(shuttleLevel), Cs.SCORE_SHUTTLE);

		// Geom.getParentCoord(skin.rampe.shuttle, skin): the shuttle of the ramp on its frame 74 (Data.LAUNCH_*), through
		// the ramp (_xscale 100, _yscale RAMPE_YSCALE, at rampeX) and the platform
		var px = (Data.LAUNCH_X + rampeX) + skin._x;
		var py = Data.LAUNCH_Y * Data.RAMPE_YSCALE * 0.01 + skin._y;
		var shuttle = new Shuttle();
		shuttle.x = px;
		shuttle.y = py;
		shuttle.setAngle(Data.LAUNCH_ROT * 0.0174);
		shuttle.updatePos();
		// Reflect.setField(shuttle.root, "_lvl", shuttleLevel - 1)
		shuttle.root.clip.lvl = shuttleLevel - 1;

		Game.me.fxScore(shuttle.x + 15, y - 52, KKApi.val(sc));
		Game.me.addScore(sc);

		var shuttle = new Shuttle();
		shuttle.setPlat(this);
		shuttle.wait = 300 + shuttleLevel * 200;
		shuttle.root.clip.lvl = shuttleLevel;
	}

	public function newShuttle() {
		step = 0;
		rampe().gotoAndStop(1);
		var s = rampe().getClip("shuttle");
		if (s != null) {
			// Reflect.setField(skin.rampe.shuttle, "_lvl", shuttleLevel)
			s.lvl = shuttleLevel;
			s.gotoAndPlay("close");
		}
		capacity = Cs.SHUTTLE_CAPACITY + shuttleLevel;
		incCapacity(0);
	}
}
