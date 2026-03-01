package kado;

import pixi.extras.AnimatedSprite;
import common_haxe_avm1.pixi.DropShadowFilter;
import pixi.core.graphics.Graphics;
import pixi.core.display.Container;
import pixi.core.sprites.Sprite;
import pixi.mesh.NineSlicePlane;
import mt.bumdum.Lib;

class EndScene extends Container {
	var kkm:KadoKadeoManager;

	var text:Array<String>;

	var fieldBest:pixi.core.text.Text;

	public function new(kkm:KadoKadeoManager) {
		super();
		this.kkm = kkm;
		var textFr = [
			"VOUS ETES QUALIFIE !",
			"VOUS N\'ETES PAS QUALIFIE",
			"Attention a ne pas perdre votre place!",
			"CONTRAT REUSSI !",
			"DEFENSE REUSSIE !",
			"DEFENSE RATEE !",
			"ATTAQUE LANCEE !",
			"SCORE BATTU",
			"POINTS",
			"ETOILE",
			"NOUVELLE ETOILE",
			"VOTRE SCORE",
			"NOUVEAU RECORD",
			"RECORD DE LA PERIODE",
			"Cliquez pour rejouer",
			"Cliquez pour défendre à nouveau",
			"Cliquez pour retenter une attaque",
			"ETAPE MISSION OK !",
			"ETAPE MISSION RATEE !",
			"VOUS ETES PREMIER !",
			""
		];
		var textEn = [
			"YOU ARE QUALIFIED!",
			"YOU ARE NOT QUALIFIED",
			"Pay attention and do not lose your position!",
			"CONTRACT SUCCESS!",
			"DEFENSE SUCCESS!",
			"DEFENSE FAILED!",
			"ATTACK LAUNCHED!",
			"SCORE BEATEN",
			"POINTS",
			"STAR",
			"NEW STAR",
			"YOUR SCORE",
			"NEW RECORD",
			"PERIOD RECORD",
			"Click here to play again",
			"Click here to defend again",
			"Click here to relaunch your attack",
			"MISSION STEP OK!",
			"MISSION STEP FAILED!"
		];
		var textEs = [
			"¡ESTÁS CLASIFICADO!",
			"NO TE HAS CLASIFICADO",
			"¡Presta atención y no pierdas tu posición!",
			"¡CONTRATO CUMPLIDO!",
			"¡DEFENSA CONSEGUIDA!",
			"¡DEFENSA FRACASADA!",
			"¡DESAFÍO LANZADO!",
			"PTS. SUPERADOS",
			"PTS.",
			"ESTRELLA",
			"NUEVA ESTRELLA",
			"TU PUNTUACIÓN",
			"NUEVO RÉCORD",
			"RÉCORD DEL PERIODO",
			"Haz clic aquí para jugar de nuevo",
			"Haz clic aquí para defender de nuevo",
			"Haz clic aquí para reintentar el desafío",
			"¡ETAPA DE MISIÓN SUPERADA CON ÉXITO!",
			"¡ETAPA DE MISIÓN FRACASADA!"
		];
		var textDe = [
			"DU BIST QUALIFIZIERT!",
			"DU BIST NICHT QUALIFIZIERT\t",
			"Pass auf und halte deinen Platz in der Rangliste!",
			"AUFGABE ERFÜLLT!",
			"VERTEIDIGUNG ERFOLGREICH!",
			"VERTEIDIGUNG FEHLGESCHLAGEN!",
			"ANGRIFF GESTARTET!",
			"REKORD GESCHLAGEN",
			"PUNKTE",
			"STERN",
			"NEUER STERN",
			"DEINE PUNKTE",
			"NEUER REKORD",
			"SAISONREKORD",
			"Klick hier, um nochmal zu spielen",
			"Klick hier, um nochmal zu verteidigen",
			"Klick hier, um nochmal anzugreifen",
			"MISSIONSSCHRITT OK!",
			"MISSIONSSCHRITT FEHLGESCHLAGEN!"
		];

		text = switch (kkm.lang) {
			case "fr": textFr;
			case "en": textEn;
			case "es": textEs;
			case "de": textDe;
			default: textFr;
		};

		var back = this.addChild(new Sprite(kkm.loader.resources["gameover_back"].texture));
		back.width = kkm.renderer.width;
		back.height = kkm.renderer.height;
		this.addChild(makePanScore());
		this.addChild(test());
	}

	public function makePanScore():Container {
		var isBest = true;
		var cont = new NineSlicePlane(new Sprite(kkm.loader.resources["window_back_2"].texture).texture, 50, 70, 50, 50);
		cont.width = 900;
		cont.height = 204;
		cont.x = (kkm.renderer.width - cont.width) / 2;
		cont.y = 450;
		var fieldTitle = cont.addChild(new pixi.core.text.Text(text[11], {
			fontFamily: 'Fredoka Bold',
			fontSize: 56,
			fill: 0x056a83,
			align: 'center',
			letterSpacing: 2
		}));
		fieldTitle.x = (kkm.renderer.width - fieldTitle.width) / 2;

		var fieldScore = cont.addChild(new pixi.core.text.Text(Std.string(kkm.score), {
			fontFamily: 'Junegull-Regular',
			fontSize: 142,
			fill: 0xfdb102,
			align: 'center',
			letterSpacing: 6
		}));
		fieldScore.x = (kkm.renderer.width - fieldScore.width) / 2;
		fieldScore.y = isBest ? 35 : 60;
		Filt.glow(fieldScore, 6, 4, 0xba3801);
		fieldScore.filters.push(new DropShadowFilter({
			blur: 5,
			rotation: 90,
			distance: 18,
			color: 0xb8dee5,
		}));

		fieldBest = cont.addChild(new pixi.core.text.Text(text[13], {
			fontFamily: 'Junegull-Regular',
			fontSize: 32,
			fill: 0xff6a2b,
			align: 'center',
		}));
		fieldBest.x = (kkm.renderer.width - fieldBest.width) / 2;
		fieldBest.y = 168;
		Filt.glow(fieldBest, 15, 2, 0xffff00);

		var tweenFilterBest = pixi.core.Pixi.tweenManager.createTween(fieldBest);
		tweenFilterBest.time = 300;
		tweenFilterBest.pingPong = true;
		tweenFilterBest.easing = pixi.core.Pixi.tween.Easing.inSine();
		// var testFilter1 = {}
		// var testFilter2 = {}
		// testFilter1[0] = {padding: 0};
		// testFilter2[0] = {padding: 15};
		tweenFilterBest.from({
			tint: 0xff6a2b,
			// filters: testFilter1
		});
		tweenFilterBest.to({
			tint: 0xfecd40,
			// filters: testFilter2
		});
		tweenFilterBest.loop = true;
		tweenFilterBest.start();

		var tweenY = pixi.core.Pixi.tweenManager.createTween(cont);
		tweenY.time = 1500;
		tweenY.easing = pixi.core.Pixi.tween.Easing.outExpo();
		tweenY.delay = 500;
		tweenY.from({
			y: 450
		});
		tweenY.to({
			y: 50
		});
		tweenY.start();

		return cont;
	}

	public function test():Container {
		var cont = new Container();

		var sheet = kkm.loader.resources["kkm"].spritesheet;
		var piou_cont = new Container();
		var piou_walk = new AnimatedSprite(untyped sheet.animations["piou_walk"]);
		var piou_shade = new Sprite(sheet.textures["piou_shade.png"]);
		piou_shade.scale.set(0.77);
		piou_cont.addChild(piou_shade);
		piou_cont.addChild(piou_walk);
		piou_cont.x = 50;
		piou_cont.y = 100;
		piou_walk.y = 20;
		piou_walk.animationSpeed = 0.5;
		piou_walk.play();

		var road = new Sprite(sheet.textures["road.png"]);
		cont.addChild(road);

		var end_line_cont = new Container();
		var end_line_1 = new Sprite(sheet.textures["end_line_1.png"]);
		var end_line_2 = new Sprite(sheet.textures["end_line_2.png"]);
		end_line_2.y = -52;
		end_line_2.x = 1;
		end_line_cont.addChild(end_line_1);
		end_line_cont.addChild(end_line_2);
		end_line_cont.x = 705;
		end_line_cont.y = 112;
		cont.addChild(end_line_cont);

		cont.addChild(piou_cont);
		cont.x = 50;
		cont.y = 500;

		cont.alpha = 0;
		var tweenAppear = pixi.core.Pixi.tweenManager.createTween(cont);
		tweenAppear.time = 1000;
		tweenAppear.easing = pixi.core.Pixi.tween.Easing.outExpo();
		tweenAppear.delay = 1000;
		tweenAppear.from({
			alpha: 0
		});
		tweenAppear.to({
			alpha: 1
		});
		tweenAppear.start();

		return cont;
	}
}
