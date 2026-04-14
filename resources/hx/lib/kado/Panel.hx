package kado;

import pixi.core.textures.Texture;
import pixi.mesh.NineSlicePlane;
import pixi.core.display.Container;

class Panel extends NineSlicePlane {
	var titleText:pixi.core.text.Text;
	var contentContainer:Container;

	public function new(kkm:KadoKadeoManager) {
		super(Texture.from("window_back.png"), 50, 70, 50, 50);
		this.contentContainer = new Container();
		this.addChild(this.contentContainer);
	}

	public function setTitle(title:String):Void {
		if (this.titleText != null) {
			this.removeChild(this.titleText);
		}
		this.titleText = new pixi.core.text.Text(title, {
			fontFamily: 'Fredoka Bold',
			fontSize: 56,
			fill: [0xFFFF00, 0xFF9900],
			align: 'center',
			stroke: 0xFF9900,
			strokeThickness: 6,
			letterSpacing: 2
		});
		this.titleText.x = (this.width - this.titleText.width) / 2;
		this.titleText.y = -6;
		this.addChild(this.titleText);
	}

	public function clearContent():Void {
		this.contentContainer.removeChildren();
	}

	public function addContentDisplayObject(obj:pixi.core.display.DisplayObject):Void {
		this.contentContainer.addChild(obj);
	}
}
