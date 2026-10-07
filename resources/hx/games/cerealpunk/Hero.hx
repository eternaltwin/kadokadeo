package cerealpunk;

// Hero.mt: the cook, above the grid. Left / right: one column, up: takes the top cereals of the column (all of the same
// kind), down: throws them back
class Hero {
	// (the animations are compared by identity: WAIT and WAIT_LOCK are two different arrays)
	static var WAIT = [1];
	static var WAIT_LOCK = [1];
	static var JUMP = [8, 9, 10, 11, 12, 13];
	static var END_JUMP = [14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24];
	static var TAKE = [27, 28, 29, 30, 31];
	static var END_TAKE = [32, 33, 34, 35, 36, 37, 38, 39];
	static var PUT = [42, 43, 44];
	static var END_PUT = [45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58];

	var game:Game;

	public var mc:MC;
	public var px:Int;

	var frame:Float;
	var anim:Array<Int>;

	public var legumes:Array<Legume>;

	// (undefined until set in Flash: false)
	var key_flag:Bool = false;
	var down_flag:Bool = false;

	public function new(g:Game) {
		game = g;
		mc = game.dmanager.attach("kanji", Const.PLAN_HERO);
		legumes = [];
		px = Std.int((Const.WIDTH - 1) / 2);
		anim = WAIT;
		frame = 0;
		mc._y = Const.YLIMIT;
		mc._x = px;
		mc._xscale = 90;
		mc._yscale = 90;
		updateHands();
	}

	// mc.m.m: the hands
	function hands():Clip {
		var m = mc.sub("m");
		return m != null ? m.getClip("m") : null;
	}

	// the hands show the first 3 cereals held (it0..it2, all of the kind of the first one; gold or not each); the
	// cracks of a stone held (it0.sub)
	function updateHands() {
		var h = hands();
		if (h == null)
			return;
		h.gotoAndStop(Std.string(1 + (legumes.length > 3 ? 3 : legumes.length)));
		// (no cereal: NaN, but the hands then show no it0)
		var id = legumes.length > 0 ? 1 + legumes[0].id : 0;
		for (k in 0...3) {
			var it = h.getClip("it" + k);
			if (it != null)
				it.gotoAndStop((legumes[k].gold ? Const.GOLD : 0) + id);
		}
		var it0 = h.getClip("it0");
		var sub = it0 != null ? it0.getClip("sub") : null;
		if (sub != null)
			sub.gotoAndStop(Const.PIERRE_LIFE + 1 - legumes[0].life);
		reverse(mc._xscale < 0);
	}

	function setAnim(a:Array<Int>) {
		anim = a;
		frame = 0;
	}

	function animDone() {
		if (anim == JUMP)
			setAnim(END_JUMP);
		else if (anim == END_JUMP)
			setAnim(WAIT);
		else if (anim == PUT)
			setAnim(END_PUT);
		else if (anim == END_PUT)
			setAnim(WAIT);
		else if (anim == TAKE)
			setAnim(END_TAKE);
		else if (anim == END_TAKE)
			setAnim(WAIT);
	}

	public function getLegume(l:Legume) {
		if (anim != TAKE)
			setAnim(TAKE);
		l.mc._visible = false;
		legumes.push(l);
		updateHands();
	}

	// facing left: the cook mirrored, his hands mirrored back (the cereals held are never mirrored)
	function reverse(flg:Bool) {
		mc._xscale = flg ? -90 : 90;
		var m = mc.sub("m");
		if (m != null)
			m.setSubXScale("m", flg ? -100 : 100);
	}

	public function main() {
		var lock = game.animator.locked(false);
		if (anim != WAIT && anim != END_JUMP && anim != END_PUT && anim != END_TAKE)
			lock = true;

		if (anim != JUMP && anim != TAKE && game.animator.gets.length == 0) {
			if (KeyboardManager.isDown(KeyboardManager.LEFT) && px > 0) {
				px--;
				reverse(true);
				setAnim(JUMP);
			} else if (KeyboardManager.isDown(KeyboardManager.RIGHT) && px < Const.WIDTH - 1) {
				px++;
				reverse(false);
				setAnim(JUMP);
			}
		}

		if (legumes.length > 0 && KeyboardManager.isDown(KeyboardManager.DOWN))
			down_flag = true;

		if (!lock) {
			if (KeyboardManager.isDown(KeyboardManager.UP)) {
				if (!key_flag) {
					key_flag = true;
					// (no cereal held: undefined, any kind can be taken)
					var id:Null<Int> = legumes.length > 0 ? legumes[0].id : null;
					var l;
					var take = false;
					while ((l = game.level.popLegume(px, id)) != null) {
						id = l.id;
						game.animator.getLegume(l);
						if (l.id != Const.BULLE && l.id != Const.BONUS1 && l.id != Const.BONUS2)
							take = true;
					}
					if (take)
						setAnim(WAIT_LOCK);
				}
			} else
				key_flag = false;
			if (down_flag) {
				down_flag = false;
				var dy = 0;
				for (i in 0...legumes.length) {
					var l = legumes[i];
					var y = game.level.pushLegume(px, l);
					l.moved = true;
					if (y == -1) {
						// the column is full: thrown above the screen (Game.explode adds them to the next combo)
						game.animator.putLegume(l, px, --dy, i);
						game.hscombo.push(l);
					} else
						game.animator.putLegume(l, px, y, i);
					setAnim(PUT);
				}
				legumes = [];
				game.combo_phase = 0;
				updateHands();
			}
		}

		frame += Timer.tmod;
		if (frame >= anim.length) {
			animDone();
			frame = frame % anim.length;
		}
		mc.gotoAndStop(Std.string(anim[Std.int(frame)]));
		var x = px * 30 + Const.DX;
		var moved = x != mc._x;
		mc._x = x;
		// (a new column: the JUMP picture draws the cook on the column he leaves)
		if (moved)
			mc.teleport();
	}
}
