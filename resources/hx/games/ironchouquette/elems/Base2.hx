package ironchouquette.elems;

class Base2 extends ASprite {
	public var light1:ASprite;
	public var light2:ASprite;

	public function new(mc:ASprite) {
		super('base2');
		mc.addChild(this);
		light1 = this.attachMovie("base2Light1");
		light2 = this.attachMovie("base2Light2");

		light1.loop = true;
		light1.play();
		light2.loop = true;
		light2.play();

		_x = 0;
		_y = 900;

		light1._x = 719;
		light1._y = -98;
		light2._x = 324;
		light2._y = -240;
	}
}
