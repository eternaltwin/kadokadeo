package happyptitank;

enum State {
	Normal;
	Hurt;
	Heal;
}

// @:bind Tank (symbol 181)
class Tank extends MovieClip {
	public var ltracks:TankTracks;
	public var rtracks:TankTracks;
	public var canon:TankCanon;
	public var target:Target;
	public var direction:Int;
	public var velocity:Float;
	public var speed:Float;
	public var angle:Float;
	public var rotationSpeed:Float;
	public var initCanonRot:Float;
	public var oldX:Float;
	public var oldY:Float;
	public var maxSpeed:Float;
	public var screenX:Float;
	public var screenY:Float;

	var col1:DisplayObject;
	var col2:DisplayObject;
	var bounds:WarZone;
	var state:State;
	var stateEnd:Float;

	// (built by Game.initGameLayer before Game sets mt.Timer.wantedFPS = 30: the speeds of the tank use the
	// default 32 of mt.Timer, like the original: maxSpeed = 3 * 60 / 32)
	public function new() {
		super(181);
		state = Normal;
		angle = 0.0;
		velocity = 0.0;
		speed = 0.0;
		rotationSpeed = 0.05 * (60 / Timer.wantedFPS);
		direction = 1;
		initCanonRot = canon.rotation;
		maxSpeed = 3.0 * (60 / Timer.wantedFPS);
		screenX = Config.W / 2;
		screenY = Config.H / 2;
		var color = Game.color.random();
		ColorSet.setColor(col1, color);
		ColorSet.setColor(col2, color);
		ColorSet.setColor(canon.col3, color);
		// port: col2 and col3 ('overlay') are drawn in the pictures of the body and of the canon, one per colour
		variant = ColorSet.indexOf(color);
		Config.addGroundShadow(this);
	}

	public function setBounds(w:WarZone) {
		bounds = w;
	}

	static var ANGLES:Array<Array<Null<Float>>> = [
		[Math.PI * 5 / 4, Math.PI * 6 / 4, Math.PI * 7 / 4,],
		[Math.PI, null, 0],
		[Math.PI * 3 / 4, Math.PI * 2 / 4, Math.PI * 1 / 4],
	];
	static var oldVector = "";

	public function updateControls(up:Bool, down:Bool, left:Bool, right:Bool) {
		if (!up && !down && !left && !right) {
			noway();
			return false;
		}
		direction = 1;
		var dx = 0;
		var dy = 0;
		if (up)
			dy = -1;
		if (down)
			dy = 1;
		if (left)
			dx = -1;
		if (right)
			dx = 1;

		var newVector = dx + ":" + dy;
		if (oldVector != newVector) {
			oldVector = newVector;
		}
		var oldAngle = angle;
		var destAngle = ANGLES[dy + 1][dx + 1];
		if (destAngle != null && destAngle != angle) {
			angle = Geom.averageRadianAngle(oldAngle, destAngle);
			var diff = Geom.angleDiff(oldAngle, angle);
			if (diff <= 0.01) {
				angle = destAngle;
			} else if (diff > Math.PI / 2) {
				speed = 0.2 * (60 / Timer.wantedFPS);
			}
		}
		rotation = Geom.rad2deg(angle) - 180;
		speed = Math.min(maxSpeed, speed + 0.4 * (60 / Timer.wantedFPS) * Timer.tmod);
		rtracks.forward();
		ltracks.forward();
		return true;
	}

	public function noway() {
		if (speed > 0)
			speed = Math.max(0.0, speed - Timer.tmod * (60 / Timer.wantedFPS));
		rtracks.pause();
		ltracks.pause();
	}

	public function unmove() {
		x = oldX;
		y = oldY;
	}

	public function move() {
		oldX = x;
		oldY = y;
		if (speed > 0)
			Geom.moveAngle(this, angle, direction * speed * Timer.tmod);
		if (bounds != null && bounds.isOutOfZone(this))
			bounds.recall(this);
		canon.rotation = Geom.angleDeg({x: screenX, y: screenY}, target) - initCanonRot - rotation - 180;
		rtracks.update();
		ltracks.update();
	}

	public function setState(st) {
		state = st;
		switch (state) {
			case Normal:
				setColorTransform(1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0);
			case Hurt:
				stateEnd = Game.instance.now + 250;
				setColorTransform(1.0, 1.0, 1.0, 1.0, 1000.0, 0, 0, 0);
			case Heal:
				stateEnd = Game.instance.now + 250;
				setColorTransform(1.0, 1.0, 1.0, 1.0, 1.0, 1000.0, 1.0, 1.0);
		}
	}

	public function update() {
		switch (state) {
			case Normal:
			case Hurt, Heal:
				if (stateEnd <= Game.instance.now)
					setState(Normal);
		}
	}

	public function getAimAngle() {
		return Geom.angleDeg({x: screenX, y: screenY}, target) - initCanonRot;
	}
}

// @:bind TankTracks (symbol 162; the exporter draws its masked tread as one picture per frame)
class TankTracks extends MovieClip {
	var d:Int;

	public function new() {
		super(162);
		stop();
		d = 0;
	}

	public function pause() {
		d = 0;
	}

	public function forward() {
		d = 1;
	}

	public function backward() {
		d = -1;
	}

	public function update() {
		var f = currentFrame + d;
		if (f <= 0)
			f = totalFrames;
		else if (f > totalFrames)
			f = 1;
		gotoAndStop(f);
	}
}

// tank_fla.TankCanon_28 (symbol 180, the timeline class of the canon: its named child col3)
class TankCanon extends MovieClip {
	public var col3:DisplayObject;

	public function new() {
		super(180);
	}
}
