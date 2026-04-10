package ironchouquette.elems;

class Base1 extends ASprite {
	public var light:ASprite;
	public var alarm:ASprite;
	public var halo:ASprite;

	public function new(mc:ASprite) {
		super('base1');
		mc.addChild(this);

		light = this.attachMovie("base1Light");
		alarm = this.attachMovie("base1Alarm");
		halo = this.attachMovie("base1Halo");
		light.loop = true;
		light.play();
		alarm.loop = true;
		alarm.play();
		halo.loop = true;
		halo.play();

		_x = 0;
		_y = 900;

		light._x = 160;
		light._y = -30;
		halo._x = 160;
		halo._y = -30;
		alarm._x = 565;
		alarm._y = -60;
	}
}
