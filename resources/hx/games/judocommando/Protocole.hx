package judocommando;

// Protocole.hx of the original. (A switch on one of these enums set to null fell to `default` in Flash; in Haxe 4
// it reads the index of null: every switch on a value that can be null has a `case null`.)
enum State {
	Normal;
	Brawl;
	KnockOut;
	Crash;
	Held;
	KneeGrabbed;
	Wheel;
	Jump;
	Seek;

	Ground;
	Stand;
	Fly;
	Ladder;
	Grapple;
	Hang;

	Crouch;
	Script;
	AirDrop;
	KneeGrab;

	Fall;
}

enum MonsterBehaviour {
	Puncher;
	Gunner;
	Croucher;
	Acrobat;
	LadderClimber;
	LongJumper;
	Miner;
	Faller;
	Jumper;
	God;
	Sword;
	Shuriken;
	Stealth;
	Teleport;
	Rocketer;
}

enum MonsterActivity {
	Walk;
	Wait;
	Patrol;
}

enum MonsterType {
	Standard;
	Soldat;
	Sapper;
	Heavy;
	Ninja;
	Gorilla;
	Super;
}

enum HoldMode {
	GRAPPLE;
	SHOULDER;
	LIFT;
	KNEE;
}

enum EntType {
	BULLET;
	MONSTER;
	HERO;
	PART;
	BONUS;
}

enum Tag {
	OSOTOGARI;
	TOMOENAGE;
	HEADCRUSHER;
	KATAGURUMA;
	STROKE;
	IPPONSEOI;
	PILEDRIVER;
	ARMLOCK;
}

enum Bonus {
	Gem(t:Tag);
	Burger;
	Yakitori;
}

typedef Command = {
	f:Void->Void,
	t:Float,
}

enum SquareType {
	EMPTY;
	BLOCK;
	PLAT;
}

typedef Square = {
	x:Int,
	y:Int,
	ent:Array<Ent>,
	type:SquareType,
	ladder:Bool
};
