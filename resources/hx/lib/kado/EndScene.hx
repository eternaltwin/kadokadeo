package kado;

import pixi.extras.AnimatedSprite;
import common_haxe_avm1.pixi.DropShadowFilter;
import pixi.core.display.Container;
import pixi.core.sprites.Sprite;
import pixi.mesh.NineSlicePlane;
import mt.bumdum.Lib;

class EndScene extends Container {
	var kkm:KadoKadeoManager;
	var details:Dto.EndRunResponseDTO;
	var disposed:Bool = false;
	var tweens:Array<Dynamic> = [];
	var piouWalk:AnimatedSprite;
	var piouFloat:AnimatedSprite;

	var text:Array<String>;

	var fieldBest:pixi.core.text.Text;

	inline function registerTween(tween:Dynamic):Dynamic {
		tweens.push(tween);
		return tween;
	}

	public function dispose():Void {
		if (disposed) {
			return;
		}
		disposed = true;
		for (tween in tweens) {
			if (tween != null) {
				untyped tween.stop();
				untyped tween.remove();
				untyped tween.removeAllListeners();
			}
		}
		tweens = [];
		if (piouWalk != null) {
			piouWalk.stop();
		}
		if (piouFloat != null) {
			piouFloat.stop();
		}
	}

	public function new(kkm:KadoKadeoManager, details:Dto.EndRunResponseDTO) {
		super();
		this.kkm = kkm;
		this.details = details;
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

		var back = this.addChild(Sprite.from("gameover_back.png"));
		back.width = kkm.renderer.width;
		back.height = kkm.renderer.height;
		this.addChild(makePanScore());
		this.addChild(makePiouTrack());
		this.addChild(clickToReplay());
	}

	public function makePanScore():Container {
		var cont = new NineSlicePlane(Sprite.from("window_back_2.png").texture, 50, 70, 50, 50);
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
		fieldScore.y = details.is_best ? 35 : 60;
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
		fieldBest.alpha = details.is_best ? 1 : 0;
		Filt.glow(fieldBest, 15, 2, 0xffff00);

		var tweenFilterBest = registerTween(pixi.core.Pixi.tweenManager.createTween(fieldBest));
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

		var tweenY = registerTween(pixi.core.Pixi.tweenManager.createTween(cont));
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

	private function makePiouTrack():Container {
		var cont = new Container();

		var piouCont = new Container();
		piouWalk = new AnimatedSprite(untyped kkm.sheet.animations["piou_walk"]);
		var piouShade = Sprite.from("piou_shade.png");
		piouShade.scale.set(0.77);
		piouCont.addChild(piouShade);
		piouCont.addChild(piouWalk);
		piouCont.x = 50;
		piouCont.y = 100;
		piouWalk.y = 20;
		piouWalk.animationSpeed = 0.5;
		piouWalk.gotoAndStop(0);

		var road = Sprite.from("road.png");
		cont.addChild(road);

		var end_line_cont = new Container();
		var end_line_1 = Sprite.from("end_line_1.png");
		var end_line_2 = Sprite.from("end_line_2.png");
		end_line_2.y = -52;
		end_line_2.x = 1;
		end_line_cont.addChild(end_line_1);
		end_line_cont.addChild(end_line_2);
		end_line_cont.x = 705;
		end_line_cont.y = 112;
		cont.addChild(end_line_cont);

		cont.addChild(piouCont);
		cont.x = 50;
		cont.y = 500;

		cont.alpha = 0;
		var tweenAppear = registerTween(pixi.core.Pixi.tweenManager.createTween(cont));
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

		var textQualField = cont.addChild(new pixi.core.text.Text(text[19], {
			fontFamily: 'Junegull-Regular',
			fontSize: 32,
			fill: 0x056a83,
			align: 'center',
		}));
		textQualField.x = (kkm.renderer.width - textQualField.width) / 2 - cont.x;
		textQualField.y = 150;
		textQualField.alpha = details.people_to_beat == 0 ? 1 : 0;

		var textQual = cont.addChild(new pixi.core.text.Text(txtPlayersToOvertake(details.people_to_beat), {
			// fontFamily: 'Junegull-Regular',
			fontSize: 32,
			fill: 0x056a83,
			align: 'center',
		}));
		textQual.x = (kkm.renderer.width - textQual.width) / 2 - cont.x;
		textQual.y = 200;
		textQual.alpha = details.people_to_beat > 0 ? 1 : 0;
		cont.addChild(textQual);
		cont.addChild(textQualField);

		var tweenPiouMove = registerTween(pixi.core.Pixi.tweenManager.createTween(piouCont));
		var MOVE_TIME_PER_PX = 1500 / 655;
		var MOVE_VALUES = [705, 639.5, 574, 508.5, 443, 377.5, 312, 246.5, 181, 115.5];
		var moveIndex = details.people_to_beat > 9 ? 9 : details.people_to_beat;
		var moveTargetX = MOVE_VALUES[moveIndex];
		var moveDistance = Math.abs(moveTargetX - 50);
		tweenPiouMove.time = Std.int(moveDistance * MOVE_TIME_PER_PX);
		// tweenPiouMove.time = 1500;
		tweenPiouMove.delay = 2000;
		tweenPiouMove.from({x: 50}).to({x: moveTargetX}).start();

		untyped tweenPiouMove.on("start", () -> {
			if (disposed || piouWalk == null) {
				return;
			}
			piouWalk.play();
		});

		untyped tweenPiouMove.on("end", () -> {
			if (disposed || piouWalk == null) {
				return;
			}
			piouWalk.gotoAndStop(0);
			if (details.people_to_beat == 0) {
				piouFloat = new AnimatedSprite(untyped kkm.sheet.animations["piou_float"]);
				piouFloat.animationSpeed = 0.5;
				piouFloat.y = -50;
				piouCont.removeChild(piouWalk);
				piouCont.addChild(piouFloat);
				piouFloat.play();

				var tweenFloat1 = registerTween(pixi.core.Pixi.tweenManager.createTween(piouFloat));
				tweenFloat1.time = 600;
				tweenFloat1.pingPong = true;
				tweenFloat1.loop = true;
				tweenFloat1.from({y: piouFloat.y}).to({y: piouFloat.y - 20}).start();
				var tweenFloat2 = registerTween(pixi.core.Pixi.tweenManager.createTween(piouFloat));
				tweenFloat2.time = 800;
				tweenFloat2.loop = true;
				tweenFloat2.from({rotation: 0}).to({rotation: 6.28}).start();
			}
		});

		return cont;
	}

	private function clickToReplay():Container {
		var cont = new Container();
		var field = cont.addChild(new pixi.core.text.Text(text[14], {
			fontFamily: 'Verdana',
			fontSize: 28,
			fill: 0x056a83,
			align: 'center',
		}));
		field.x = (kkm.renderer.width - field.width) / 2;
		field.y = 900;
		field.alpha = 0;
		cont.addChild(field);

		var tweenBlink = registerTween(pixi.core.Pixi.tweenManager.createTween(field));
		tweenBlink.time = 500;
		tweenBlink.delay = 1000;
		tweenBlink.loop = true;
		tweenBlink.pingPong = true;
		tweenBlink.easing = untyped(a) -> a < 0.251 ? 0 : 1;
		tweenBlink.from({alpha: 1}).to({alpha: 0}).start();

		return cont;
	}

	private function txtPlayersToOvertake(n:Int):String {
		if (kkm.lang == "en") {
			return "You still have " + n + " players to overtake!";
		}
		if (kkm.lang == "es") {
			return "¡Todavía tienes que superar a " + n + " jugadores!";
		}
		if (kkm.lang == "de") {
			return "Du hast noch " + n + " Spieler vor dir!";
		}
		return "Il y a encore " + n + " joueurs à dépasser !";
	}
}
