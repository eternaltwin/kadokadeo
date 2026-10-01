package elloninthedark;

class Dragon extends Bads {
	public static var MARGIN = KadoKadeoManager.I(30);
	public static var ECART = 9;

	public var flLeader:Bool;
	public var qList:Array<Dragon>;
	public var op:Array<Array<Float>>;
	public var leader:Dragon;

	// frame 1 of the clip: body segment / frame 2: head ("sub" clip, 80 orientations, its shell keeps shimmering)
	var skin:ASprite;
	var head:SlotClip;

	public function new(mc:ASprite) {
		super(mc, 4);
		ray = KadoKadeoManager.I(18);
		hp = 2;
		skin = root.attachMovie("mcDragonBody", "body", 1);
		frict = 0.98;
		score = Cs.SCORE_DRAGON;
		gid = 2;
		flLeader = false;
	}

	override public function update() {
		super.update();
		if (flLeader) {
			var last:Dragon = this;
			for (i in 0...qList.length) {
				var b = qList[i];
				var pos = op[(i + 1) * ECART];
				b.x = pos[0];
				b.y = pos[1];
				b.root._rotation = b.getAng(last) / 0.0174;
				last = b;
			}
			op.unshift([x, y]);
			while (op.length > 300)
				op.pop();

			var fa = a;
			while (fa < 0)
				fa += 6.28;
			head.gotoAndStop(Std.int(1 + 80 * (fa / 6.28)));
		}
	}

	override public function shoot() {
		cooldown = 50;
		var max = 3;
		var ec = 0.3;
		var sp = KadoKadeoManager.S(5);
		for (i in 0...max) {
			var c = ((i / (max - 1)) * 2 - 1);
			var s = newShot();
			s.vx = Math.cos(a + c * ec) * sp;
			s.vy = Math.sin(a + c * ec) * sp;
			s.x += s.vx * 4;
			s.y += s.vy * 4;
			s.orient();
			s.setSkin(4);
		}
	}

	public function setLeader() {
		flLeader = true;
		if (head == null) {
			skin.removeMovieClip();
			head = new SlotClip(Data.DRAGON_HEAD).attachTo(root, 1);
		}
		hp = 5;
		shootRate = 80;

		op = new Array();
		qList = new Array();
		for (i in 0...300)
			op.push([x, y]);

		// BEHAVIOUR
		bList.push(3);
		a = -1.57;
		turnCoef = 0.1;
		va = 0.05;
		speed = KadoKadeoManager.S(2.5);

		// FIRST TRG
		trg = {
			x: Cs.mcw * 0.5,
			y: MARGIN + Seed.rand() * (Cs.GL - 2 * MARGIN)
		};

		//
		Cs.game.mdm.over(root);
		root._rotation = 0;
	}

	override public function explode() {
		if (flLeader) {
			for (b in qList.copy()) {
				b.explode();
			}
		} else {
			if (leader.hp > 0)
				leader.explodePart(this);
		}
		super.explode();
	}

	public function explodePart(eb:Dragon) {
		var i = 0;
		while (i < qList.length) {
			if (eb == qList[i] && i < qList.length - 1) {
				i++;
				var newLeader = qList[i];
				qList.splice(i, 1);
				newLeader.setLeader();
				newLeader.op = new Array();
				var n = (i + 1) * ECART;
				while (n < op.length) {
					var p = op[n];
					newLeader.op.push([p[0], p[1]]);
					n++;
				}
				while (i < qList.length) {
					var b = qList[i];
					qList.splice(i, 1);
					newLeader.qList.push(b);
					b.leader = newLeader;
				}
			}
			i++;
		}
	}

	override public function onTargetReach() {
		super.onTargetReach();
		trg = {
			x: MARGIN + Seed.rand() * (Cs.mcw - 2 * MARGIN),
			y: MARGIN + Seed.rand() * (Cs.GL - 2 * MARGIN)
		};
	}
}
