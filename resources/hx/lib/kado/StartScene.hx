package kado;

import pixi.core.graphics.Graphics;
import pixi.core.display.Container;
import pixi.core.sprites.Sprite;

class StartScene extends Container {
	var kkm:KadoKadeoManager;

	var clicToStartText:pixi.core.text.Text;
	var elapsed:Float;
	var panel:Panel;
	var overlay:Graphics;

	public function new(kkm:KadoKadeoManager) {
		super();
		this.kkm = kkm;
		this.elapsed = 0;

		this.makeBottomBar();

		var art = new Sprite(kkm.loader.resources["/assets/img/content/default/default_artwork.jpg"].texture);
		this.addChild(art);

		this.overlay = new Graphics();
		overlay.beginFill(0x6b95b4, 0.36);
		overlay.drawRect(0, 0, kkm.renderer.width, kkm.renderer.height);
		overlay.endFill();
		overlay.visible = false;
		this.addChild(overlay);

		this.panel = new Panel(kkm);
		panel.width = 500;
		panel.height = 210;
		panel.x = (kkm.renderer.width - panel.width) / 2;
		panel.y = (kkm.renderer.height - panel.height) / 2;
		panel.visible = false;
		this.addChild(panel);

		var updateFn = this.update;
		kkm.ticker.add(updateFn);
	}

	public function makeBottomBar():Void {
		var bb = new Sprite(kkm.loader.resources["/assets/img/content/default/bottom_bar.png"].texture);
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
		var text = new pixi.core.text.Text('Run ID: ' + contract.run_id + '\n' + 'Server Time: ' + contract.server_time + '\n' + 'Contract Score: '
			+ contract.contract_score + '\n' + 'Contract Points: ' + contract.contract_points + '\n' + 'Seed: ' + contract.seed,
			{
				fontFamily: 'Fredoka Bold',
				fontSize: 24,
				fill: 0x0798FF,
				align: 'left',
			});
		panel.addContentDisplayObject(text);
		text.x = 20;
		text.y = 50;
	}
}
