package happyptitank;

// @:bind FlyPaper (symbol 84): a piece of paper of an explosion
class FlyPaper extends MovieClip {
	public var vect:{x:Float, y:Float};
	public var speed:Float;
	public var rotationSpeed:Float;
	public var fadeTime:Float;

	public function new() {
		super(84);
		fadeTime = FlyPaperAnim.FADE_TIME;
		rotationSpeed = 0.0;
	}
}

// (bound to no symbol: a Sprite; the papers are pictures only: visual random)
class FlyPaperAnim extends Sprite implements Anim {
	public static var ST_BOOM = 1;
	public static var ST_FADE = 2;
	public static var FADE_TIME = 300;

	var papers:List<FlyPaper>;
	var center:Point;

	public var state:Int;

	var start:Float;
	var time:Float;

	public function new(c:Point) {
		super();
		state = ST_BOOM;
		center = c;
		time = 0.0;
		var n = 20 + Seed.randomVfx(10);
		if (Game.instance.slowLevel == 3)
			n = Math.ceil(n / 4);
		else if (Game.instance.slowLevel == 2)
			n = Math.ceil(n / 3);
		else if (Game.instance.slowLevel == 1)
			n = Math.ceil(n / 2);
		var aPerPaper = Math.PI * 2 / n;
		var angle = 0.0;
		papers = new List();
		var sr = 60 / Timer.wantedFPS;
		for (i in 0...n) {
			var p = new FlyPaper();
			p.gotoAndStop(Seed.randomVfx(p.totalFrames) + 1);
			p.x = center.x;
			p.y = center.y;
			p.scaleX = 0.3;
			p.scaleY = 0.3;
			p.vect = Geom.radToVector(angle);
			p.speed = (1 + 2 - Seed.randVfx() * 1) * sr;
			papers.push(p);
			addChild(p);
			angle += aPerPaper;
			p.rotationSpeed = (2.5 - Seed.randVfx() * 5) * sr;
		}
		angle = 0.0;
		var ft = FADE_TIME;
		var n = 15 + Seed.randomVfx(15);
		if (Game.instance.slowLevel == 3) {
			ft = Math.round(ft / 4);
			n = Math.ceil(n / 4);
		} else if (Game.instance.slowLevel == 2) {
			ft = Math.round(ft / 3);
			n = Math.ceil(n / 3);
		} else if (Game.instance.slowLevel == 1) {
			ft = Math.round(ft / 2);
			n = Math.ceil(n / 2);
		}
		for (i in 0...n) {
			var p = new FlyPaper();
			p.gotoAndStop(Seed.randomVfx(p.totalFrames) + 1);
			p.fadeTime = ft;
			p.x = center.x;
			p.y = center.y;
			p.vect = Geom.radToVector(angle);
			p.speed = (0.5 + 2 - Seed.randVfx() * 1) * sr;
			papers.push(p);
			addChild(p);
			angle += aPerPaper;
			p.rotationSpeed = (2.5 - Seed.randVfx() * 5) * sr;
		}
	}

	public function destroy() {
		for (p in papers)
			removeChild(p);
		parent.removeChild(this);
	}

	public function update():Bool {
		switch (state) {
			case 1: // ST_BOOM
				for (p in papers) {
					p.x += p.vect.x * p.speed * Timer.tmod;
					p.y += p.vect.y * p.speed * Timer.tmod;
					p.scaleX = Math.min(2, p.scaleX + Timer.tmod / 20);
					p.scaleY = Math.min(2, p.scaleY + Timer.tmod / 20);
					p.rotation += p.rotationSpeed;
				}

			case 2: // ST_FADE
				for (p in papers) {
					p.x += p.vect.x * 0.5 * p.speed * Timer.tmod;
					p.y += p.vect.y * 0.5 * p.speed * Timer.tmod;
					p.scaleX = Math.max(0.3, p.scaleX - Timer.tmod / 10);
					p.scaleY = Math.max(0.3, p.scaleY - Timer.tmod / 10);
					p.alpha = p.alpha - (Timer.tmod * 1 / p.fadeTime);
					p.rotation += p.rotationSpeed;
					if (p.alpha <= 0)
						papers.remove(p);
				}
				if (papers.length == 0)
					return false;
		}
		return true;
	}
}

// @:bind XMissileCross (symbol 120): where a missile falls
class XMissileCross extends MovieClip {
	public function new() {
		super(120, true);
	}
}

private enum State {
	Waiting;
	Falling;
	Exploding;
	Smoking;
}

// @:bind XMissile (symbol 118)
class XMissile extends MovieClip {
	public static var EXPLODING_TIME = 0.2;
	public static var SMOKING_TIME = 3;

	var cross:XMissileCross;

	public var dangerous:Bool;

	var state:State;
	var speed:Float;
	var time:Float;
	var papers:FlyPaperAnim;

	public function new(targetX:Float, targetY:Float, ?delay:Float = 0.0) {
		super(118);
		speed = 10;
		var circle = Game.instance.scroll.getCurrentCircle();
		if (circle < 8)
			speed = 5;
		else
			speed = Math.min(10, 5 + circle - 8);
		speed = speed * (60 / Timer.wantedFPS);
		state = Falling;
		cross = new XMissileCross();
		cross.x = targetX;
		cross.y = targetY;
		// (the picture only: visual random)
		gotoAndStop(1 + Seed.randomVfx(totalFrames));
		Game.instance.groundLayer.addChild(cross);
		x = cross.x;
		y = cross.y - Game.H;
		Game.instance.missiles.push(this);
		Game.instance.gameLayer.addChild(this);
		dangerous = false;
		if (delay > 0)
			setWait(delay);
	}

	public function setWait(t:Float) {
		state = Waiting;
		time = t;
		cross.visible = false;
		visible = false;
	}

	public function isColliding(t:Tank):Bool {
		var radius = 16;
		var tankBox = {
			xMin: t.x - t.width / 2,
			xMax: t.x + t.width / 2,
			yMin: t.y - t.height / 2,
			yMax: t.y + t.height / 2
		};
		var explBox = {
			xMin: cross.x - radius,
			xMax: cross.x + radius,
			yMin: cross.y - radius,
			yMax: cross.y + radius
		}
		if (tankBox.xMin > explBox.xMax)
			return false;
		if (tankBox.xMax < explBox.xMin)
			return false;
		if (tankBox.yMin > explBox.yMax)
			return false;
		if (tankBox.yMax < explBox.yMin)
			return false;
		return true;
	}

	public function update() {
		switch (state) {
			case Waiting:
				time -= Timer.deltaT;
				if (time <= 0) {
					time = 0;
					cross.visible = true;
					visible = true;
					state = Falling;
				}

			case Falling:
				y += speed * Timer.tmod;
				var elap = 1 - ((cross.y - y) / Game.H);
				var scale = 1 - elap;
				alpha = elap;
				scaleX = 1 + scale;
				scaleY = 1 + scale * 2;
				if (y >= cross.y) {
					alpha = 1;
					scaleX = 0.5;
					scaleY = 0.5;
					y = cross.y;
					cross.parent.removeChild(cross);
					state = Exploding;
					papers = new FlyPaperAnim(new Point(cross.x, cross.y));
					Game.instance.gameLayer.addChild(papers);
					Game.instance.gameLayer.swapChildren(this, papers);
					time = 0;
					dangerous = true;
				}

			case Exploding:
				papers.update();
				time += Timer.deltaT;
				alpha = 0.9 - Math.min(1, time / EXPLODING_TIME);
				if (time >= EXPLODING_TIME) {
					time = 0;
					state = Smoking;
					papers.state = FlyPaperAnim.ST_FADE;
					Game.instance.addAnimation(papers);
					dangerous = false;
				}

			case Smoking:
				// papers.update();
				time += Timer.deltaT;
				if (time >= SMOKING_TIME) {
					// papers.destroy();
					parent.removeChild(this);
					Game.instance.missiles.remove(this);
				}
		}
	}
}
