package punchin;

enum AfroStep {
	Wait;
	Attack;
	Defense;
	Ouch;
}

enum AfroMove {
	Left;
	Center;
	Right;
}

// Afro.hx of the original: the opponent (mcAfro)
class Afro extends Sprite {
	static var MVCOOLDOWN = 50;
	static var ATKCOOLDOWN = 50;
	static var DEFCOOLDOWN = 50;

	static var DEFLVLMIN = 20;
	static var ATKLVLMIN = 20;
	static var MOVLVLMIN = 20;

	public var defLevel:Float;

	var atkLevel:Int;
	var movLevel:Int;

	public var afroStep:AfroStep;
	public var afroMove:AfroMove;
	public var afroNextMove:AfroMove;
	public var afroPrevMove:AfroMove;

	var moveCool:Float;
	var defTimer:Float;
	var defCool:Float;
	var atkCool:Float;

	// (undefined until the first move or attack of the original: NaN, `weak > 0` is false)
	var weak:Float = Math.NaN;
	var danger:Float;
	var invert:Bool;

	var cFrame:Float;

	var label:String;
	var nLabel:String;
	var defState:String;
	var nbDef:Int;

	public var flHit:Bool;
	public var flMissed:Bool;
	public var flAttacked:Bool;
	// (undefined until a defence decides to counter: false)
	public var flCounter:Bool = false;
	public var reverse:Bool;

	public var atkLock:Bool;
	public var mvLock:Bool;
	public var defLock:Bool;
	public var ouchLock:Bool;
	public var hitLock:Bool = false;

	public static var ANIM = [
		{name: "stand", start: 1, end: 19},
		{name: "attack", start: 20, end: 26},
		{name: "attack_missed", start: 27, end: 37},
		{name: "attack_hit", start: 38, end: 45},
		{name: "def", start: 58, end: 62},
		{name: "def_anim", start: 63, end: 67},
		{name: "def_end", start: 68, end: 71},
		{name: "ouch", start: 78, end: 85},
		{name: "move2side", start: 91, end: 95},
		{name: "move2center", start: 98, end: 105},
		{name: "side_stand", start: 108, end: 117},
		{name: "side_ouch", start: 118, end: 123},
		{name: "side_def", start: 138, end: 141},
		{name: "side_def_anim", start: 143, end: 146},
		{name: "side_def_end", start: 148, end: 152}
	];

	public function new(mc:MC) {
		super(mc);
		invert = false;
		x = Cs.w * 0.5;
		y = Cs.h - 10;

		atkLevel = ATKLVLMIN * 2;
		defLevel = DEFLVLMIN * 2;
		movLevel = MOVLVLMIN * 2;

		moveCool = 20;
		defTimer = 10;
		defCool = 20;
		atkCool = 20;

		setScale(100);
		defState = "";
		nbDef = 0;

		flHit = false;
		flMissed = false;
		flAttacked = false;
		cFrame = 0;
		afroStep = Wait;
		afroMove = Center;

		atkLock = false;
		mvLock = false;
		defLock = false;
		ouchLock = false;
		reverse = false;

		this.root.gotoAndStop("stand");
	}

	override public function update() {
		super.update();

		defLevel += Timer.tmod;
		switch (afroStep) {
			case Wait:
				// cooldown --
				if (defCool > 0)
					defCool -= Timer.tmod;
				if (moveCool > 0)
					moveCool -= Timer.tmod;
				if (atkCool > 0)
					atkCool -= Timer.tmod;

				if (weak > 0)
					weak -= Timer.tmod;

				if (!mvLock) {
					if (flAttacked) {
						if ((defLevel / 5900) > Seed.rand()) {
							afroStep = Defense;
							if ((defLevel / 5900) > Seed.rand()) {
								flCounter = true;
							}
							#if debug
							Game.me.dbg.autoDef++;
							#end
						}
					} else {
						switch (Seed.random(3)) {
							case 0:
								// DEF
								if ((defCool <= 0) && (Seed.random(DEFLVLMIN) > DEFLVLMIN / 2)) {
									afroStep = Defense;
								} else {
									playStand();
								}

							case 1:
								// MOV
								if ((moveCool <= 0)) {
									randomMove();
									weak = 5;
								} else {
									playStand();
								}
							case 2:
								// ATK
								if ((atkCool <= 0) && (Seed.random(ATKLVLMIN) > ATKLVLMIN / 2)) {
									playAtk();
									weak = 10;
								} else {
									playStand();
								}
						}
					}
				} else {
					playMove();
				}

			case Attack:
				animAtk();

			case Defense:
				if (defTimer > 0) {
					defTimer -= Timer.tmod;
				}
				defend();

			case Ouch:
				playOuch();
		}
	}

	public function playAtk() {
		afroStep = Attack;
		atkLock = true;
		afroMove = Center;
		atkCool = ATKCOOLDOWN + Seed.random(2);
		initAnim("attack", reverse);
		#if debug
		Game.me.dbg.afroAtk++;
		#end
	}

	// (the original tests `_currentframe < end` to advance; the compiled code `_currentframe >= end` first: the same
	// branches, the end of an animation is never unknown)
	function animAtk() {
		if (flHit) {
			if (!hitLock) {
				initAnim("attack_hit", reverse);
				hitLock = true;
				Game.boxer.initOuch(reverse);
			} else {
				if (this.root._currentframe >= getEndAnim(label)) {
					hitLock = false;
					flHit = false;
					afroStep = Wait;
				} else {
					nextFrame();
				}
			}
		} else if (flMissed) {
			if (!hitLock) {
				initAnim("attack_missed", reverse);
				hitLock = true;
			} else {
				if (this.root._currentframe >= getEndAnim(label)) {
					hitLock = false;
					flMissed = false;
					afroStep = Wait;
				} else {
					nextFrame();
				}
			}
		} else {
			if (this.root._currentframe >= getEndAnim(label)) {
				isTouched();
			} else {
				nextFrame();
			}
		}
	}

	function isTouched() {
		if (!Game.boxer.mvLock) {
			switch (Game.boxer.move) {
				case Left:
					flMissed = true;
				case Center:
					flHit = true;
				case Right:
					flMissed = true;
			}
		} else {
			flMissed = true;
		}
	}

	function defend() {
		if (defState == "defending") {
			if (this.root._currentframe >= getEndAnim(label)) {
				if (defTimer < 0) {
					defState = "end";
				}
			} else {
				nextFrame();
			}
		} else if (defState == "encaisse") {
			if (this.root._currentframe >= getEndAnim(label)) {
				if (defTimer < 0) {
					defState = "end";

					switch (afroMove) {
						case Left:
							initAnim("side_def_end", true);
						case Center:
							initAnim("def_end", reverse);
						case Right:
							initAnim("side_def_end");
					}
				}
			} else {
				nextFrame();
			}
		} else if (defState == "end") {
			if (flCounter) {
				playAtk();
				flCounter = false;
				#if debug
				Game.me.dbg.counterAtk++;
				#end
			} else {
				if (this.root._currentframe >= getEndAnim(label)) {
					if (defTimer < 0) {
						defState = "";
						afroStep = Wait;
						defLock = false;
						defCool = DEFCOOLDOWN;
						flAttacked = false;
					}
				} else {
					nextFrame();
				}
			}
		} else {
			switch (afroMove) {
				case Left:
					initAnim("side_def", true);
				case Center:
					initAnim("def", reverse);
				case Right:
					initAnim("side_def");
			}

			defTimer = Seed.random(DEFLVLMIN) + DEFLVLMIN;
			defState = "defending";
			#if debug
			Game.me.dbg.afroDef++;
			#end
		}
	}

	public function defMe() {
		Game.boxer.nbCombo = 0;
		defState = "encaisse";

		switch (afroMove) {
			case Left:
				initAnim("side_def_anim", true);
			case Center:
				initAnim("def_anim");
			case Right:
				initAnim("side_def_anim");
		}
	}

	function randomMove() {
		mvLock = true;
		switch (afroMove) {
			case Left:
				afroNextMove = Center;
				initAnim("move2center", true);

			case Center:
				if (Seed.random(2) == 0) {
					afroNextMove = Left;
					initAnim("move2side", true);
				} else {
					afroNextMove = Right;
					initAnim("move2side");
				}
			case Right:
				afroNextMove = Center;
				initAnim("move2center");
		}

		moveCool = Seed.random(MVCOOLDOWN);
	}

	function playMove() {
		mvLock = true;
		switch (afroNextMove) {
			case Left | Center | Right:
				if (this.root._currentframe >= getEndAnim(label)) {
					mvLock = false;
					afroMove = afroNextMove;
				} else {
					nextFrame();
				}
		}
	}

	function playStand() {
		switch (afroMove) {
			case Left:
				if (label != "side_stand") {
					initAnim("side_stand", true);
				}

			case Center:
				if (label != "stand") {
					initAnim("stand", reverse);
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

	public function willBeAttacked() {
		afroPrevMove = afroMove;
		flAttacked = true;
	}

	// (null while the afro attacks: the punch misses)
	public function couldBeTouched(atkReversed:Bool):Bool {
		var touched:Null<Bool> = null;
		if (afroPrevMove == afroMove) {
			switch (afroStep) {
				case Wait:
					touched = true;
					mvLock = false;
				case Attack:
				// todo
				case Defense:
					touched = false;
					defMe();
				case Ouch:
					touched = false;
			}
		} else {
			touched = false;
		}

		if (touched)
			initOuch(atkReversed);
		flAttacked = false;
		return touched == true;
	}

	public function isWeak() {
		return (weak > 0);
	}

	public function initOuch(atkReversed:Bool) {
		afroStep = Ouch;
		reverse = atkReversed;
		switch (afroMove) {
			case Left:
				Game.me.moveBg("left");
				initAnim("side_ouch", true);
			case Center:
				initAnim("ouch", atkReversed);
				Game.me.moveBg("center");
			case Right:
				initAnim("side_ouch");
				Game.me.moveBg("right");
		}
	}

	function playOuch() {
		if (this.root._currentframe >= getEndAnim(label)) {
			afroStep = Wait;
			ouchLock = false;
			flAttacked = false;
			playStand();
		} else {
			nextFrame();
		}
	}

	function initAnim(labelname:String, ?reverse:Bool) {
		label = labelname;
		if (reverse)
			this.root._xscale = -100;
		else
			this.root._xscale = 100;
		this.root.gotoAndStop(label);
		cFrame = this.root._currentframe;
	}

	function nextFrame() {
		cFrame += 1;
		this.root.gotoAndStop(Math.ceil(cFrame));
	}

	// (null for an unknown animation: NaN in a comparison, like Flash)
	function getEndAnim(anim:String):Float {
		for (a in ANIM) {
			if (a.name == anim)
				return a.end;
		}
		return Math.NaN;
	}
}
