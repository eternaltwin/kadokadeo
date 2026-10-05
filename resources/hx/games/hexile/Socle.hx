package hexile;

import hexile.Data.HitMask;
import hexile.Game.HexType;

class Socle {
	public var height:Int;

	public var dataSea:Int;

	public var team:Null<Int>;
	public var n:Int;
	public var x:Int;
	public var y:Int;

	// the mcSoldat the base registered (register): the ones on screen, see showBase
	public var soldats:Array<SoldierMC>;

	public var type:HexType;
	public var root:HexMC;

	var mcSelection:MC;

	// (port) root.enabled: the hex answers the mouse (Game.updateMouse)
	public var enabled:Bool;

	// (port) what the clip shows: the base of mcHex is a timeline (one frame per number of soldiers), drawn here as
	// the picture of the hex (texture frame of the base, decor variant) and the soldiers of its frame
	var img:MC;
	var base:MC;
	var tex:Int;
	var dirtVariant:Int = 0;
	// Col.setColor(root, 0, 20) of rover: the brightened pictures
	var bright:Bool = false;

	public function new(x:Int, y:Int) {
		this.x = x;
		this.y = y;
		team = null;
		n = 0;
		// (never set for the hex under the castle, which gets no type)
		height = 0;

		soldats = [];

		root = cast Game.me.gdm.attach(new HexMC(this));
		root._x = Cs.getX(x, y);
		root._y = Cs.getY(x, y);
		// the base of frame 1 (sprite 61): gotoAndStop(random(_totalframes) + 1) of its texture, a picture only
		tex = Seed.randomVfx(7) + 1;
		img = root.attach(new MC("hexB"));
		base = root.attach(new MC());
		updateImg();

		Game.me.grid[x][y] = this;
		Game.me.socles.push(this);

		//
		enabled = false;
	}

	// DECOR
	public function setType(t:HexType) {
		type = t;
		// root.gotoAndStop(Type.enumIndex(t) + 1): frames 2 and 3 hold another base, with its own random texture
		if (t != Beach)
			tex = Seed.randomVfx(7) + 1;

		height = 0;
		switch (type) {
			case Dirt:
				var n = Seed.random(2);
				height = 3 + n * 5;
				dirtVariant = n;
			case Mountain:
				height = 12 + Seed.random(8);
			default:
		}
		base._y = -height;
		showBase();
		updateImg();
	}

	public function seekSea() {
		var a = getNeighbors();
		dataSea = Cs.DIR.length - a.length;
	}

	// SOLDATS
	public function incSoldat(inc:Int) {
		n += inc;
		// root.base.gotoAndStop(n + 1)
		showBase();
		Game.me.incTeamScore(team, inc);
	}

	public function register(mc:SoldierMC) {
		soldats.push(mc);
		mc.setTeam(team);
		mc._x = Math.round(mc._x);
		mc._y = Math.round(mc._y);
	}

	public function swapTeam() {
		Game.me.incTeamScore(team, -n);
		if (team == 0)
			Game.me.decScore(Cs.SCORE_HEX[Type.enumIndex(type)]);
		if (team == 1)
			Game.me.addScore(Cs.SCORE_HEX[Type.enumIndex(type)]);
		team = 1 - team;
		Game.me.incTeamScore(team, n);
		soldats = [];
		// root.base.gotoAndStop(1); root.base.gotoAndStop(n + 1): the soldiers placed again register in the new colour
		showBase();
	}

	// INTER
	public function active() {
		enabled = true;
	}

	public function unactive() {
		enabled = false;
	}

	public function rover() {
		bright = true;
		updateImg();

		var max = Std.int(Math.min(getMax(type), Game.me.count));
		var list = getRenfort(max - 1);
		var a = getConvert(max);
		for (h in a)
			list.push(h);
		Game.me.blinks = list;

		mcSelection = root.attach(new MC("sel"));
		mcSelection._y = -height;
		mcSelection.showNow = true;
	}

	public function rout() {
		bright = false;
		updateImg();
		if (Game.me.blinks != null)
			for (h in Game.me.blinks) {
				for (sol in h.soldats)
					sol.setBlink(false);
			}
		Game.me.blinks = [];

		if (mcSelection != null)
			mcSelection.removeMovieClip();
		mcSelection = null;
	}

	public function select() {
		rout();
		Game.me.initJump(this);
	}

	// FX
	public function fxPop() {}

	public function fxStar() {
		var cr = 0.5;
		var p = new Phys(Game.me.dm.attach("star", Game.DP_PARTS));
		// (Math.random: the stars are a picture only)
		p.x = root._x + (Seed.randVfx() * 2 - 1) * Cs.WW * cr;
		p.y = root._y + (Seed.randVfx() * 2 - 1) * Cs.HH * cr;
		p.weight = -(0.1 + Seed.randVfx() * 0.2);
		p.timer = 20 + Seed.randVfx() * 20;
		p.fadeType = 0;
		p.updatePos();
	}

	public function getRenfort(max:Int):Array<Socle> {
		var fill = [];
		for (d in Cs.DIR) {
			var nx = x + d[0];
			var ny = y + d[1];
			var h = Game.me.cell(nx, ny);
			if (h != null && h.team == Game.me.turn && h.n < getMax(h.type))
				fill.push(h);
		}
		var f = function(a:Socle, b:Socle) {
			if (a.n < b.n)
				return -1;
			return 1;
		}
		Game.sort(fill, f);
		while (fill.length > max)
			fill.pop();
		return fill;
	}

	public function getConvert(max:Int):Array<Socle> {
		var list = [];
		for (d in Cs.DIR) {
			var nx = x + d[0];
			var ny = y + d[1];
			var h = Game.me.cell(nx, ny);
			// (a cell of the sea: undefined in Flash, its team neither the player's nor null... but undefined == null)
			if (h != null && h.team != Game.me.turn && h.team != null) {
				if (h.getAttack(h.n) < getAttack(max)) {
					list.push(h);
				}
			}
		}
		return list;
	}

	// TOOLS
	public function getNeighbors():Array<Socle> {
		var list = [];
		for (d in Cs.DIR) {
			var x = x + d[0];
			var y = y + d[1];
			var hex = Game.me.cell(x, y);
			if (hex != null)
				list.push(hex);
		}
		return list;
	}

	public function getAttack(att:Int):Int {
		if (type == Mountain)
			att += 3;
		return att;
	}

	// (the hex under the castle never gets a type: undefined, every comparison with it is false)
	public static function getMax(type:HexType):Null<Int> {
		if (type == null)
			return null;
		switch (type) {
			case Beach:
				return 10;
			case Dirt:
				return 8;
			case Mountain:
				return 4;
		}
	}

	// ---------------------------------------------------------------- port: display and mouse
	// the frame n + 1 of the base: every soldier of the previous frame is removed and new ones are placed (the base
	// timelines place each frame's soldiers at new depths), which register on their first frame
	// (_parent._parent._obj.register(this)): standing, in the colour of the team, on whole pixels
	function showBase() {
		for (c in base.children.copy())
			c.removeMovieClip();
		var layout = switch (look()) {
			case Dirt: Data.BASE_DIRT;
			case Mountain: Data.BASE_MOUNT;
			default: Data.BASE_BEACH;
		}
		for (it in layout[n]) {
			if (it[0] == 1) {
				var s = base.attach(new MC("shade"));
				s.showNow = true;
				s._x = it[1];
				s._y = it[2];
				s._alpha = it[3] * 100;
			} else {
				var sol = new SoldierMC();
				base.attach(sol);
				sol._x = it[1];
				sol._y = it[2];
				register(sol);
			}
		}
	}

	function updateImg() {
		var t = bright ? "H" : "";
		switch (look()) {
			case Dirt:
				img.setFrames("hexD" + t);
				img.gotoAndStop(dirtVariant * 7 + tex);
			case Mountain:
				img.setFrames("hexM" + t);
				img.gotoAndStop(height - Data.MOUNT_MIN + 1);
			default:
				img.setFrames("hexB" + t);
				img.gotoAndStop(tex);
		}
	}

	#if debug
	// test harness (Game.debugShow): a hex in a given state
	public function debugSet(t:HexType, variant:Int, tex:Int, height:Int, n:Int, team:Null<Int>) {
		type = t;
		dirtVariant = variant;
		this.tex = tex;
		this.height = height;
		base._y = -height;
		this.n = n;
		this.team = team;
		showBase();
		updateImg();
	}
	#end

	// the frame of mcHex shown: the hex under the castle never gets a type and stays on frame 1 (Beach)
	inline function look():HexType {
		return type == null ? Beach : type;
	}

	// the hex picture (not brightened), for the sea bitmap
	public function picture():{anim:String, frame:Int} {
		return switch (look()) {
			case Dirt: {anim: "hexD", frame: dirtVariant * 7 + tex};
			case Mountain: {anim: "hexM", frame: height - Data.MOUNT_MIN + 1};
			default: {anim: "hexB", frame: tex};
		}
	}

	// Flash's mouse test on the shapes of the clip: the pixels of its picture (Data masks, measured in the SWF; the
	// gameplay never reads the display). fx, fy: Flash pixels of the scene
	public function hitTest(fx:Float, fy:Float):Bool {
		var m = switch (look()) {
			case Dirt: Data.MASK_D[dirtVariant * 7 + tex - 1];
			case Mountain: Data.MASK_M[height - Data.MOUNT_MIN];
			default: Data.MASK_B[tex - 1];
		}
		var rows = maskRows(m);
		var ix = Math.floor((fx - root._x) * Game.K) - m.x;
		var iy = Math.floor((fy - root._y) * Game.K) - m.y;
		if (iy < 0 || iy >= rows.length)
			return false;
		var r = rows[iy];
		var i = 0;
		while (i < r.length) {
			if (ix >= r[i] && ix < r[i + 1])
				return true;
			i += 2;
		}
		return false;
	}

	static var masks:Map<String, Array<Array<Int>>> = new Map();

	static function maskRows(m:HitMask):Array<Array<Int>> {
		var r = masks.get(m.rows);
		if (r == null) {
			r = [];
			for (row in m.rows.split(";")) {
				var runs = [];
				if (row != "")
					for (run in row.split(",")) {
						var p = run.split("-");
						runs.push(Std.parseInt(p[0]));
						runs.push(Std.parseInt(p[1]));
					}
				r.push(runs);
			}
			masks.set(m.rows, r);
		}
		return r;
	}
}

// mcHex
class HexMC extends MC {
	public var socle:Socle;

	public function new(s:Socle) {
		super();
		socle = s;
	}
}

// mcSoldat placed by a base timeline (hexes, castle): the colour of its team (frame 1 / 2), the white blink of
// Col.setPercentColor(sol, 30, 0xFFFFFF) (Game.updatePlay) and the victory dance (smc frame 2, its smc playing)
class SoldierMC extends MC {
	var frame:Int = 1;
	var blink:Bool = false;
	var dancing:Bool = false;

	public function new() {
		super("sold");
		showNow = true;
	}

	// mc.gotoAndStop(team + 1)
	public function setTeam(team:Int) {
		frame = team + 1;
		refresh();
	}

	public function setBlink(b:Bool) {
		blink = b;
		refresh();
	}

	// mc.smc.gotoAndStop(2); mc.smc.smc.gotoAndPlay(f)
	public function dance(f:Int) {
		dancing = true;
		setFrames("dance" + (frame - 1));
		gotoAndPlay(f);
	}

	function refresh() {
		if (!dancing)
			gotoAndStop(frame + (blink ? 2 : 0));
	}
}
