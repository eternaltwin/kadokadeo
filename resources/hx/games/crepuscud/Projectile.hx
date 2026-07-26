package crepuscud;

import mt.bumdum.Sprite;
import mt.bumdum.Phys;
import mt.bumdum.Lib;

class Projectile extends Phys {
	var angle:Float;
	var speed:Float;
	var qcol:Int;

	public function new(mc:ASprite) {
		super(mc);
		qcol = 0xFFFFFF;
	}

	override function update() {
		// QUEUE
		var mc = Game.me.brushQueueMissile;
		mc._x = x;
		mc._y = y;
		mc._rotation = angle / 0.0174;
		mc._xscale = speed * mt.Timer.tmod / KadoKadeoManager.I(1);
		Col.setColor(mc, qcol);
		Game.me.brushQueueMissile._visible = true;
		Game.me.plasma.drawMc(mc);
		Game.me.brushQueueMissile._visible = false;

		super.update();
	}

	public function setAngle(n) {
		angle = n;
		root._rotation = angle / 0.0174;
	}

	public function setSpeed(n) {
		speed = n;
		vx = Math.cos(angle) * speed;
		vy = Math.sin(angle) * speed;
	}
}
