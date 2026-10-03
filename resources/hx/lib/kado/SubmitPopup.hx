package kado;

import pixi.core.display.Container;
import pixi.core.graphics.Graphics;

// shown over the end of the game while the run is sent to the server (same panel as the server connection at start)
class SubmitPopup extends Container {
	var kkm:KadoKadeoManager;
	var panel:Panel;

	public function new(kkm:KadoKadeoManager) {
		super();
		this.kkm = kkm;

		var overlay = new Graphics();
		overlay.beginFill(0x6b95b4, 0.36);
		overlay.drawRect(0, 0, kkm.screen.width, kkm.screen.height);
		overlay.endFill();
		this.addChild(overlay);

		this.panel = new Panel(kkm);
		panel.width = KadoKadeoManager.I(216);
		this.addChild(panel);
		showSending();
	}

	public function showSending():Void {
		show("", 'ENVOI AU\nSERVEUR EN COURS...');
	}

	public function showFailure(stored:Bool):Void {
		if (stored) {
			show("ERREUR", "LA PARTIE N'A PAS PU\nÊTRE ENVOYÉE.\nELLE SERA RENVOYÉE\nPLUS TARD.", "CLIQUER POUR CONTINUER");
		} else {
			show("ERREUR", "LA PARTIE N'A PAS PU\nÊTRE ENVOYÉE.", "CLIQUER POUR CONTINUER");
		}
	}

	function show(title:String, message:String, ?hint:String):Void {
		panel.showMessage(title, message, hint);
		panel.fitHeight(KadoKadeoManager.I(83));
		panel.x = (kkm.screen.width - panel.width) / 2;
		panel.y = (kkm.screen.height - panel.height) / 2;
	}
}
