package alchimie2;

import kado.TouchControlsConfig.TouchControlsMode;
import haxe.io.UInt16Array;
import common_haxe_avm1.KeyboardManager;
import mt.bumdum.Lib;
import mt.bumdum.Sprite;
import alchimie2.GameData.ArtefactId;

enum GameStep {
	Wait;
	Play;
	Fall;
	Transform;
	Destroy;
	ArtefactInUse;
	GameOver;
	Mode;
}

class GuiSprite extends ASprite {
	public var _group_mask:ASprite;
	public var _force_group_mask:ASprite;
}

class OutSprite extends ASprite {
	public var bmp:RenderTexture;
}

@:expose('GameAlchimie2')
class Game implements kado.GameInterface {
	public static var TOUCH_CONTROLS:kado.TouchControlsConfig = {
		mode: TouchControlsMode.KEYBOARD,
		buttons: [
			{
				id: "rotate",
				label: "",
				size: 4000,
				action: "tap_rotate",
				invisible: true,
			}
		],
		swipe: {
			leftAction: "swipe_left",
			rightAction: "swipe_right",
			downAction: "swipe_down",
			minDistance: 48,
			maxDurationMs: 300,
		},
	};

	public static var me:Game;

	static public var objectsList:Array<StageObject> = [];

	public var rdm:mt.DepthManager;
	public var mdm:mt.DepthManager;
	public var out:OutSprite;
	public var root:ASprite;
	public var mc:ASprite;
	public var bg:ASprite;

	// interface
	public var gui:GuiSprite;

	public var mcChain:Array<ObjectMc>;
	public var artefact:Array<StageObject>;
	public var onEndFall:Array<Void->Void>;

	public var data:GameData;
	public var step:GameStep;
	public var score:Int;
	public var gameOver:Bool;
	public var mode:alchimie2.mode.GameMode;
	public var stage:Stage;

	var gTimer:Float;
	var kl:Dynamic;
	var ckl:Dynamic;

	public var picks:Array<PickUp>;

	public var pLeft:Bool;
	public var pRight:Bool;

	var pendingVirtualKeyUps:Array<{keyCode:Int, framesLeft:Int}>;

	public function new(mc:ASprite) {
		var replayKeys = new UInt16Array(11);
		replayKeys[0] = KeyboardManager.ARROW_LEFT;
		replayKeys[1] = KeyboardManager.ARROW_RIGHT;
		replayKeys[2] = KeyboardManager.ARROW_UP;
		replayKeys[3] = KeyboardManager.ARROW_DOWN;
		replayKeys[4] = KeyboardManager.SPACE;
		replayKeys[5] = KeyboardManager.Z;
		replayKeys[6] = KeyboardManager.W;
		replayKeys[7] = KeyboardManager.Q;
		replayKeys[8] = KeyboardManager.A;
		replayKeys[9] = KeyboardManager.S;
		replayKeys[10] = KeyboardManager.D;
		KadoKadeoManager.kkm.replay.init({
			recordedKeys: replayKeys,
			recordInputs: true,
			recordEvents: false,
		});

		root = mc;
		me = this;
		gameOver = false;
		artefact = [];
		onEndFall = [];
		score = 0;
		step = Fall;
		picks = [];

		pLeft = false;
		pRight = false;
		pendingVirtualKeyUps = [];

		rdm = new mt.DepthManager(root);
		this.mc = rdm.empty(2);
		mdm = new mt.DepthManager(this.mc);
		// initKeyListener();

		loadData();
		init();
		start();
	}

	function init() {
		initBg();
		initInterface();
		initGame();
	}

	function initGame() {
		mode = alchimie2.mode.GameMode.get(data);
	}

	public function start() {
		stage = new Stage();
		stage.init(null);
	}

	function initInterface() {
		var skin = rdm.attach("mcBg", 1);
		skin._x = 0;
		skin._y = 0;

		var mcInterface = mdm.empty(Cs.DP_INTERFACE);

		var idm = new mt.DepthManager(mcInterface);

		gui = cast idm.attach("gui", 1);

		// gui._group_mask = mdm.empty(Cs.DP_GROUP_BOX);
		// // gui._group_mask._alpha = 0;
		// gui._group_mask._x = Cs.GROUP_MASK_X;
		// gui._group_mask._y = Cs.GROUP_MASK_Y;
		// var g = gui._group_mask.getGraphics();
		// g.beginFill(0xFFFFFF, 0.5).drawPolygon([
		// 	0,
		// 	KadoKadeoManager.I(5),
		// 	Cs.ELEMENT_SIZE * 3,
		// 	0,
		// 	Cs.ELEMENT_SIZE * 3,
		// 	Cs.ELEMENT_SIZE * 3,
		// 	0,
		// 	Cs.ELEMENT_SIZE * 3 - KadoKadeoManager.I(5)
		// ]).endFill();

		// gui._force_group_mask = mdm.attach("group_mask", Cs.DP_GROUP_BOX);
		// gui._force_group_mask._alpha = 0;
		// gui._force_group_mask._x = Cs.GROUP_MASK_X;
		// gui._force_group_mask._y = Cs.GROUP_MASK_Y;

		mcChain = new Array();
		var cx = KadoKadeoManager.S(237.5);
		var cy = KadoKadeoManager.S(115.8);
		for (i in 0...12) {
			var omc = new ObjectMc(Elt(i), mdm, i + 5);
			omc.mc._x = cx;
			omc.mc._y = cy;

			cy += KadoKadeoManager.S(14.1);

			omc.mc._xscale = omc.mc._yscale = 56.4;

			if (i > 2)
				Col.setPercentColor(omc.mc, 84, Cs.HIDE_CHAIN_COL);

			mcChain.push(omc);
		}
	}

	public function setSpiritState(c:Int) {
		/*var s = if (c >= 4)
					"_bravo"
				else
					"_combo" + Std.int(Math.max(0, c)) ;

			if (s != null)
				spiritAnims.l.add(s) ;


			if (!spiritAnims.onStage)
				spiritNextAnim() ; */
	}

	public function spiritNextAnim() {
		/*var a = spiritAnims.l.pop() ;

			spiritAnims.onStage = a != null ;

			if (a == null)
				a = "_stand" ;

			spirit.play(a) ; */
	}

	function initBg() {
		bg = mdm.attach("bg", Cs.DP_BG);
		bg._x = 0;
		bg._y = 0;
	}

	public function loadData() {
		data = Cs.getDataGame();
	}

	public function updateScore() {
		KadoKadeoManager.kkm.score = Std.int(mode.updateScore());
		KadoKadeoManager.kkm.addScore(0);
	}

	public function releaseArtefact(a:StageObject):Bool {
		return artefact.remove(a);
	}

	public function hasInUse(o:StageObject):Bool {
		for (a in artefact) {
			if (o == a)
				return true;
		}
		return false;
	}

	public function addEndFall(f:Void->Void) {
		onEndFall.push(f);
	}

	public function setStep(s, ?a:StageObject) {
		/*step = s ;
			if (step == ArtefactInUse)
				artefact.push(a) ;
			else  {
				artefact = [] ;
		}*/

		if (s == ArtefactInUse) {
			step = s;
			artefact.push(a);
		} else {
			if (artefact.length == 0)
				step = s;
			/*else
				trace("error : step " + s +  " with living artefactInUse") ; */
		}
	}

	public function canPlay() {
		return step == Play;
	}

	public function update(delta:Float) {
		if (canPlay()) {
			pLeft = KeyboardManager.isDown(KeyboardManager.ARROW_LEFT)
				|| KeyboardManager.isDown(KeyboardManager.Q)
				|| KeyboardManager.isDown(KeyboardManager.A);
			pRight = KeyboardManager.isDown(KeyboardManager.ARROW_RIGHT) || KeyboardManager.isDown(KeyboardManager.D);
			if (KeyboardManager.isJustDown(KeyboardManager.ARROW_UP)
				|| KeyboardManager.isJustDown(KeyboardManager.SPACE)
				|| KeyboardManager.isJustDown(KeyboardManager.Z)
				|| KeyboardManager.isJustDown(KeyboardManager.W)) {
				stage.rotate();
			}
			if (KeyboardManager.isDown(KeyboardManager.ARROW_DOWN) || KeyboardManager.isDown(KeyboardManager.S)) {
				stage.release();
			}
		} else {
			pLeft = false;
			pRight = false;
		}

		updateSprites();
		updateObjects();
		updateMoves();

		if (picks.length > 0) {
			for (p in picks) {
				p.update();
			}
		}

		if (stage == null)
			return;

		stage.updateEffect();
		stage.fall();

		// if (Cs.FL_DEBUG)
		// 	updateDebug();

		switch (step) {
			case Wait:

			case Play:
				if (stage.next != null)
					stage.next.update();

			case Fall:
				if (!stage.isFalling()) {
					if (!stage.check()) {
						if (!mode.checkFallEnd()) {
							if (stage.startPlay()) {
								updateScore();
							}
						}
					} else {
						updateScore();
						mode.onTransform();
						stage.startTransformation();
					}
				}

			case Transform:
				if (!stage.transform())
					stage.startFall();

			case Destroy:
				if (!stage.destroy())
					stage.startFall();

			case ArtefactInUse:
				if (artefact.length == 0)
					stage.startFall();
				else {
					for (a in artefact) {
						a.updateEffect();
					}
				}

			case GameOver:
				// nothing to do

			case Mode:
				mode.loop();
		}

		flushPendingVirtualKeyUps();

		// drawOut() ;
	}

	public function onTouchAction(action:String):Void {
		switch (action) {
			case "tap_rotate":
				queueVirtualTap(KeyboardManager.SPACE);
			case "swipe_left":
				queueVirtualTap(KeyboardManager.ARROW_LEFT);
			case "swipe_right":
				queueVirtualTap(KeyboardManager.ARROW_RIGHT);
			case "swipe_down":
				queueVirtualTap(KeyboardManager.ARROW_DOWN);
		}
	}

	function queueVirtualTap(keyCode:Int):Void {
		KeyboardManager.queueVirtualKeyDown(keyCode);
		pendingVirtualKeyUps.push({
			keyCode: keyCode,
			framesLeft: 4
		});
	}

	function flushPendingVirtualKeyUps():Void {
		var keep:Array<{keyCode:Int, framesLeft:Int}> = [];
		for (entry in pendingVirtualKeyUps) {
			entry.framesLeft--;
			if (entry.framesLeft <= 0) {
				KeyboardManager.queueVirtualKeyUp(entry.keyCode);
			} else {
				keep.push(entry);
			}
		}
		pendingVirtualKeyUps = keep;
	}

	function updateSprites() {
		Sprite.updateAll();
	}

	function updateObjects() {
		var list = Game.objectsList;
		for (s in list)
			s.update();
	}

	function updateMoves() {
		var list = alchimie2.anim.Anim.onStage;
		for (m in list)
			m.update();
	}

	public function setGameOver() {
		KadoKadeoManager.kkm.gameOver({});
		setStep(GameOver);
	}

	public function isGameOver() {
		return step == GameOver;
	}

	public function initPickUp(?forceNew = false, ?m:ASprite, ?c:{x:Float, y:Float}) {
		if (!forceNew) {
			if (picks.length > 0)
				return picks[picks.length - 1];
		}

		var np = new PickUp(m, c);
		picks.push(np);
		return np;
	}

	function updateDebug() {
		if (KeyboardManager.isJustDown(KeyboardManager.DIGIT_2)) // 2 doublon
			forceGroup(Elts(2, null));

		if (KeyboardManager.isJustDown(KeyboardManager.DIGIT_3)) // 3 triplet
			forceGroup(Elts(3, null));

		if (KeyboardManager.isJustDown(KeyboardManager.DIGIT_4)) // 3 carré
			forceGroup(Elts(4, null));

		if (KeyboardManager.isJustDown(KeyboardManager.DIGIT_5)) // 5 doublon with neutral
			forceGroup(Elts(2, Neutral));

		if (KeyboardManager.isJustDown(KeyboardManager.DIGIT_6)) // 6 triplet with neutral
			forceGroup(Elts(3, Block(1)));

		if (KeyboardManager.isJustDown(KeyboardManager.DIGIT_7)) // 7 carré with neutral
			forceGroup(Elts(4, Block(2)));

		if (KeyboardManager.isJustDown(KeyboardManager.A)) // A alchimite
			forceGroup(Alchimoth);

		if (KeyboardManager.isJustDown(KeyboardManager.B)) // B Dynamite Bomberman
			forceGroup(Dynamit(3));

		if (KeyboardManager.isJustDown(KeyboardManager.D)) // D dynamit
			forceGroup(Dynamit(0));

		if (KeyboardManager.isJustDown(KeyboardManager.V)) // V dynamit verticale
			forceGroup(Dynamit(1));

		if (KeyboardManager.isJustDown(KeyboardManager.N)) // N Neutral(true) élément neutre qui tombe dans une colonne au hasard
			forceGroup(Neutral);

		if (KeyboardManager.isJustDown(KeyboardManager.G)) // G PearGrain(0)
			forceGroup(PearGrain(0));

		if (KeyboardManager.isJustDown(KeyboardManager.H)) // H PearGrain(1) (souche)
			forceGroup(PearGrain(1));

		if (KeyboardManager.isJustDown(KeyboardManager.BACKSPACE)) // >< forceComboGrid
			stage.forceComboGrid([10, 9, 8, 7, 6, 5]);

		if (KeyboardManager.isJustDown(KeyboardManager.DELETE)) // suppr empty stage
			stage.forceEmpty();
	}

	public function forceGroup(e:ArtefactId) {
		var g = stage.nexts.pop();
		g.kill();
		stage.nexts.push(new Group(e));
	}

	public function destroy() {}
}
