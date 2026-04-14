package kado;

import pixi.core.textures.Texture;
import pixi.core.graphics.Graphics;
import pixi.core.display.Container;
import pixi.core.sprites.Sprite;

class StartScene extends Container {
	var kkm:KadoKadeoManager;

	var clicToStartText:pixi.core.text.Text;
	var elapsed:Float;
	var panel:Panel;
	var overlay:Graphics;

	public function new(kkm:KadoKadeoManager, gameName:String) {
		super();
		this.kkm = kkm;
		this.elapsed = 0;

		this.addChild((new Graphics()).beginFill(0x6b95b4, 1).drawRect(0, 0, kkm.renderer.width, kkm.renderer.height).endFill());
		this.makeBottomBar();

		var art = Sprite.from("/assets/img/gfx/artwork/" + gameName + ".jpg");
		this.addChild(art);

		this.overlay = new Graphics();
		overlay.beginFill(0x6b95b4, 0.36);
		overlay.drawRect(0, 0, kkm.renderer.width, kkm.renderer.height);
		overlay.endFill();
		overlay.visible = false;
		this.addChild(overlay);

		this.panel = new Panel(kkm);
		panel.width = 650;
		panel.height = 250;
		panel.x = (kkm.renderer.width - panel.width) / 2;
		panel.y = (kkm.renderer.height - panel.height) / 2;
		panel.visible = false;
		this.addChild(panel);

		var updateFn = this.update;
		kkm.ticker.add(updateFn);
	}

	public function makeBottomBar():Void {
		var bb = Sprite.from("bottom_bar.png");
		bb.x = 0;
		bb.y = kkm.renderer.height - 68;
		this.addChild(bb);

		this.clicToStartText = new pixi.core.text.Text("CLIQUER POUR COMMENCER", {
			fontFamily: 'Fredoka Bold',
			fontSize: 45,
			fill: 0xFF6400,
			align: 'center',
			stroke: 0xFFFFFF,
			strokeThickness: 10,
			letterSpacing: 2
		});
		this.clicToStartText.x = (kkm.renderer.width - this.clicToStartText.width) / 2;
		this.clicToStartText.y = kkm.renderer.height - 66;
		this.addChild(this.clicToStartText);
	}

	function update(delta:Float):Void {
		elapsed += delta;
		clicToStartText.visible = (Math.floor(elapsed / 30) % 2 == 0);
	}

	override public function destroy(?options:Null<haxe.extern.EitherType<Bool, pixi.core.display.DisplayObject.DestroyOptions>>) {
		kkm.ticker.remove(this.update);
		super.destroy(options);
	}

	public function disable():Void {
		kkm.ticker.remove(this.update);
		this.clicToStartText.visible = false;
		this.interactive = false;
		overlay.visible = true;
		panel.visible = true;
		panel.setTitle("");

		var text = new pixi.core.text.Text('CONNEXION AU\nSERVEUR EN COURS...', {
			fontFamily: 'Fredoka Bold',
			fontSize: 42,
			fill: 0x78c3c9,
			align: 'center',
		});
		panel.clearContent();
		panel.addContentDisplayObject(text);
		text.x = (panel.width - text.width) / 2;
		text.y = 70;
	}

	public function showContract(contract:Dto.RunDTO):Void {
		panel.setTitle("CONTRAT");
		panel.clearContent();
		var scoreToBeat = new pixi.core.text.Text('SCORE À BATTRE', {
			fontFamily: 'Fredoka Bold',
			fontSize: 40,
			fill: 0x78c8c8,
			align: 'left',
		});
		panel.addContentDisplayObject(scoreToBeat);
		scoreToBeat.x = 30;
		scoreToBeat.y = 70;

		var contractPoints = new pixi.core.text.Text('POINTS', {
			fontFamily: 'Fredoka Bold',
			fontSize: 40,
			fill: 0x78c8c8,
			align: 'left',
		});
		panel.addContentDisplayObject(contractPoints);
		contractPoints.x = 450;
		contractPoints.y = 70;

		var verticalBar = new Graphics();
		verticalBar.beginFill(0xd3d3d3).drawRect(400, 70, 8, 150).endFill();
		panel.addContentDisplayObject(verticalBar);

		var scoreToBeatValue = new pixi.core.text.Text(Std.string(contract.contract_score), {
			fontFamily: 'Fredoka Bold',
			fontSize: 50,
			fill: 0x0798FF,
			align: 'center',
		});
		scoreToBeatValue.x = 200 - scoreToBeatValue.width / 2;
		scoreToBeatValue.y = 140;
		panel.addContentDisplayObject(scoreToBeatValue);

		var contractPointsValue = new pixi.core.text.Text(Std.string(contract.contract_points), {
			fontFamily: 'Fredoka Bold',
			fontSize: 50,
			fill: 0x0798FF,
			align: 'right',
		});
		contractPointsValue.x = 550 - contractPointsValue.width;
		contractPointsValue.y = 140;
		panel.addContentDisplayObject(contractPointsValue);

		var kImg = new Sprite(Texture.from('kado_icon.png'));
		kImg.x = 580;
		kImg.y = 170;
		kImg.scale.set(0.5);
		panel.addContentDisplayObject(kImg);
	}
}
