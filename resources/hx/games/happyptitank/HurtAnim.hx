package happyptitank;

class HurtAnim implements Anim {
	var obj:DisplayObject;
	var end:Float;

	public function new(e:DisplayObject, time:Int = 100) {
		obj = e;
		end = Game.instance.now + time;
		obj.setColorTransform(1.0, 1.0, 1.0, 1.0, 1000.0, 1000.0, 1000.0, 1000.0);
	}

	public function update():Bool {
		if (end <= Game.instance.now) {
			obj.setColorTransform(1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0);
			return false;
		}
		return true;
	}
}
