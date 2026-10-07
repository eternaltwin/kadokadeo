package punchin;

import punchin.Afro.AfroMove;
import punchin.Afro.AfroStep;

enum BoxerStep {
	Stand;
	Attack;
	Defense;
	Ouch;
	GameOver;
}

enum BoxerMove {
	Left;
	Center;
	Right;
}

// Boxer.hx of the original: the player, seen from behind (mcPlayer)
class Boxer extends Sprite {
	var isFalling:Bool = false;

	var staOuch:Int;
	var staHit:Int;
	var staMissed:Int;

	public var nbCombo:Int;

	static var ATKCOOLDOWN = 4;
	static var MVCOOLDOWN = 30;

	public static var ANIM = [
		{name: "stand", start: 0, end: 19},
		{name: "attack", start: 20, end: 24},
		{name: "attack_missed", start: 25, end: 29},
		{name: "attack_hit", start: 30, end: 42},
		{name: "hook", start: 50, end: 51},
		{name: "hook_missed", start: 55, end: 59},
		{name: "hook_hit", start: 60, end: 72},
		{name: "ouch", start: 80, end: 86},
		{name: "move2side", start: 90, end: 92},
		{name: "move2center", start: 100, end: 103},
		{name: "side_stand", start: 110, end: 119}
	];

	public var step:BoxerStep;
	public var move:BoxerMove;
	public var nextMove:BoxerMove;

	public var reversed:Bool;
	public var flLeft:Bool;
	public var flRight:Bool;
	public var flAtk:Bool;
	public var flHit:Bool;
	public var flMissed:Bool;
	// (undefined until the first hit of the original: false)
	public var flWeak:Bool = false;
	public var flBonus:Bool;

	var label:String;
	var atkType:String;

	public var mvLock:Bool;

	// (undefined until the first attack of the original: false)
	var atkLock:Bool = false;
	var hitLock:Bool;

	var cFrame:Float;
	var moveCool:Float;
	var atkCool:Float;

	public function new(mc:MC) {
		super(mc);
		x = Cs.w * 0.5;
		y = Cs.h + 20;

		move = Center;
		mvLock = false;
		hitLock = false;

		flHit = false;
		flMissed = false;
		flBonus = false;
		moveCool = 0;
		atkCool = 0;

		step = Stand;
		label = "";
		this.root.gotoAndStop("stand");

		staOuch = 20;
		staHit = 5;
		staMissed = 2;
		reversed = false;
		nbCombo = 0;
	}

	override public function update() {
		super.update();
		if (!Game.me.isPlaying())
			return;
		flLeft = KeyboardManager.isDown(KeyboardManager.LEFT);
		flRight = KeyboardManager.isDown(KeyboardManager.RIGHT);
		flAtk = KeyboardManager.isDown(KeyboardManager.SPACE);

		control();
	}

	// MOVE
	// (moveCool stays 0: the compiled code tests `moveCool > 0` first, the same branches)
	function control() {
		switch (step) {
			case Stand:
				if (!mvLock) {
					if (!atkLock) {
						if (moveCool <= 0) {
							if ((flRight) && (move != Left) && (move != Right)) {
								mvLock = true;
								nextMove = Right;
								initAnim("move2side");
								playMove();
							} else if ((flLeft) && (move != Right) && (move != Left)) {
								mvLock = true;
								nextMove = Left;
								initAnim("move2side", true);
								playMove();
							} else {
								if ((move == Right) && (!flRight)) {
									mvLock = true;
									nextMove = Center;
									initAnim("move2center");
									playMove();
								} else if ((move == Left) && (!flLeft)) {
									mvLock = true;
									nextMove = Center;
									initAnim("move2center", true);
									playMove();
								} else {
									playStand();
								}
							}
							if (atkCool > 0) {
								atkCool -= Timer.tmod;
							} else {
								if ((flAtk) && (!flRight) && (!flLeft)) {
									playAtk();
								}
							}
						} else {
							moveCool -= Timer.tmod;
							playStand();
						}
					} else {
						animAtk();
					}
				} else {
					playMove();
				}

			case Attack:
			case Defense:
			case Ouch:
				playOuch();
			case GameOver:
				this.root.gotoAndStop(85);
				this.y += 10;
				this.x += 5;
				if (this.y > (Cs.h + 220)) {
					Game.me.initGameOver();
				}
		}
	}

	// (the original tests `_currentframe < end` to advance; the compiled code `_currentframe >= end` first: the same
	// branches, the end of an animation is never unknown)
	function playStand() {
		switch (move) {
			case Left:
				if (label != "side_stand") {
					initAnim("side_stand", true);
				}
			case Center:
				if (label != "stand") {
					initAnim("stand", reversed);
				}
			case Right:
				if (label != "side_stand") {
					initAnim("side_stand");
				}
		}

		if (this.root._currentframe >= getEndAnim(label)) {
			this.root.gotoAndStop(label);
			cFrame = this.root._currentframe;
		} else {
			nextFrame();
		}
	}

	function playMove() {
		switch (nextMove) {
			case Left | Center | Right:
				if (this.root._currentframe >= getEndAnim(label)) {
					mvLock = false;
					move = nextMove;
				} else {
					nextFrame();
				}
		}
	}

	function playAtk() {
		atkLock = true;
		atkCool = ATKCOOLDOWN;
		Game.afro.willBeAttacked();
		switch (Game.afro.afroMove) {
			case AfroMove.Left:
				initAnim("hook", true);
				atkType = "hookreverse";
			case AfroMove.Center:
				if (Seed.random(2) == 1) {
					reversed = true;
				} else {
					reversed = false;
				}
				initAnim("attack", reversed);
				atkType = "attack";

			case AfroMove.Right:
				initAnim("hook");
				atkType = "hook";
		}
	}

	function hit() {
		if (Game.me.st.maskXScale > staHit + 1) {
			Game.me.decStamina(staHit);
		}

		switch (Game.bonusCol) {
			case 1:
				if (flWeak) {
					Game.me.newMsg("Contre Attaque", 15);
					Game.me.addScore(Cs.SCORE_COUNTER);
					#if debug
					Game.me.dbg.counters++;
					#end
				} else {
					nbCombo++;
					if (nbCombo >= 2) {
						Game.me.newMsg(nbCombo + " COMBO", 15);
					}
					var pts:Null<KKConst> = Cs.SCORE_PUNCH[nbCombo];
					if (pts == null)
						pts = Cs.SCORE_PUNCH_BIG;
					Game.me.addScore(pts);
				}
			case 2:
				Game.me.newMsg("1000pts !", 15);
				Game.me.addScore(Cs.SCORE_BONUS[0]);
				Game.bonusCol = 1;
				#if debug
				Game.me.dbg.bonus0++;
				#end
			case 3:
				Game.me.newMsg("3000pts !!!", 15);
				Game.me.addScore(Cs.SCORE_BONUS[1]);
				Game.bonusCol = 1;
				#if debug
				Game.me.dbg.bonus1++;
				#end
			case 4:
				Game.me.newMsg("6000pts !!!", 15);
				Game.me.addScore(Cs.SCORE_BONUS[2]);
				Game.bonusCol = 1;
				#if debug
				Game.me.dbg.bonus2++;
				#end
		}
		#if debug
		Game.me.dbg.hits++;
		Game.me.dbg.maxCombo = Std.int(Math.max(Game.me.dbg.maxCombo, nbCombo));
		#end
	}

	function miss() {
		Game.me.decStamina(staMissed);
		Game.afro.defMe();
		#if debug
		Game.me.dbg.misses++;
		#end
	}

	public function fall() {
		playOuch();
		isFalling = true;
	}

	function animAtk() {
		if (flHit) {
			if (!hitLock) {
				if (atkType == "hookreverse") {
					initAnim("hook_hit", true);
				} else if (atkType == "attack") {
					initAnim("attack_hit", reversed);
				} else {
					initAnim("hook_hit");
				}
				hitLock = true;
				hit();
			} else {
				if (this.root._currentframe >= getEndAnim(label)) {
					hitLock = false;
					flHit = false;
					atkLock = false;
				} else {
					nextFrame();
				}
			}
		} else if (flMissed) {
			if (!hitLock) {
				if (atkType == "hookreverse") {
					initAnim("hook_missed", true);
				} else if (atkType == "attack") {
					initAnim("attack_missed");
				} else {
					initAnim("hook_missed");
				}
				hitLock = true;
				miss();
			} else {
				if (this.root._currentframe >= getEndAnim(label)) {
					hitLock = false;
					flMissed = false;
					atkLock = false;
				} else {
					nextFrame();
				}
			}
		} else {
			if (this.root._currentframe >= getEndAnim(label)) {
				if (Game.afro.couldBeTouched(reversed)) {
					flHit = true;
					flWeak = Game.afro.isWeak();
				} else
					flMissed = true;
			} else {
				nextFrame();
			}
		}
	}

	function isTouched() {
		switch (Game.afro.afroStep) {
			case AfroStep.Wait:
				flHit = true;
			case AfroStep.Attack:
				flHit = true;
			case AfroStep.Defense:
				flMissed = true;
			case AfroStep.Ouch:
				flMissed = true;
		}
	}

	public function initOuch(reverse:Bool) {
		step = Ouch;
		reversed = reverse;
		Game.me.decStamina(staOuch);
		nbCombo = 0;
		initAnim("ouch", reversed);
		atkLock = false;
		mvLock = false;
		#if debug
		Game.me.dbg.ouch++;
		#end
	}

	function playOuch() {
		if (this.root._currentframe >= getEndAnim(label)) {
			step = Stand;
			// (`Game.me.initGameOver;` without a call, then a trace: nothing; isFalling is never set)
		} else {
			nextFrame();
		}
		if (isFalling) {
			y += 10;
		}
	}

	// ANIM mng

	function initAnim(labelname:String, ?reverse:Bool) {
		label = labelname;
		if (reverse)
			this.root._xscale = -100;
		else
			this.root._xscale = 100;
		this.root.gotoAndStop(label);
		cFrame = this.root._currentframe;
	}

	function prevFrame() {
		cFrame -= Timer.tmod;
		this.root.gotoAndStop(Math.ceil(cFrame));
	}

	function nextFrame() {
		cFrame += 1;
		this.root.gotoAndStop(Math.ceil(cFrame));
	}

	function getStartAnim(anim:String):Float {
		for (a in ANIM) {
			if (a.name == anim)
				return a.start;
		}
		return Math.NaN;
	}

	// (null for an unknown animation: NaN in a comparison, like Flash)
	function getEndAnim(anim:String):Float {
		for (a in ANIM) {
			if (a.name == anim)
				return a.end;
		}
		return Math.NaN;
	}

	public static function reset() {
		ATKCOOLDOWN = 4;
		MVCOOLDOWN = 30;
	}
}
