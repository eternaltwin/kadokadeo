package bactery;

import common_haxe_avm1.MouseManager;
import haxe.io.UInt16Array;
import kado.KadoKadeoManager;
import mt.DepthManager;
import mt.Timer;
import mt.bumdum.Lib;

typedef FlashInfo = {
	var mc:ASprite;
	var prc:Float;
}

typedef GameStats = {
	var n:Int;
	var k:Int;
	var m:Int;
	var w:Int;
	var b:Int;
}

@:expose('GameBactery')
class Game implements kado.GameInterface {
	var root_mc:ASprite;

	public var dmanager:DepthManager;
	public var level:Level;
	public var lock:Bool;

	var sel:Bille;
	var init_timer:Float;
	var isReplayMode:Bool;
	var pendingLiveClicks:Array<Int>;

	var fList:Array<FlashInfo>;

	public var pList:Array<Part>;
	public var stats:GameStats;

	public function new(root:ASprite, ?isReplay:Bool = false) {
		isReplayMode = isReplay;
		pendingLiveClicks = [];
		KadoKadeoManager.kkm.replay.init({
			recordedKeys: new UInt16Array(0),
			recordInputs: false,
			recordEvents: true,
			recordMousePosition: false,
			recordedMouseButtons: new UInt16Array(0),
		});

		root_mc = root;
		init_timer = 1;
		dmanager = new DepthManager(root);
		dmanager.attach("bg", Const.PLAN_BG);
		level = new Level(this);
		level.init();
		stats = {
			k: 0,
			n: 0,
			m: 0,
			w: 0,
			b: 0
		};

		fList = new Array();
		pList = new Array();
	}

	public function onSelect(b:Bille):Void {
		if (lock || init_timer > 0)
			return;
		if (sel == null) {
			b.select(true);
			sel = b;
		} else {
			var s = sel;
			sel.select(false);
			sel = null;
			if (b.x == s.x && b.y == s.y)
				return;
			stats.n++;
			lock = true;
			level.swap(s, b);
		}
	}

	public function update(delta:Float):Void {
		for (event in KadoKadeoManager.kkm.replay.consumeEvents())
			applyReplayEvent(event);

		if (!isReplayMode) {
			var clicks = pendingLiveClicks;
			pendingLiveClicks = [];
			for (cell in clicks)
				applyCellClick(cell);
		}

		init_timer -= Timer.deltaT;
		recordGridClick();
		level.update();

		var i = 0;
		while (i < fList.length) {
			var info = fList[i];
			if (info.prc < 1) {
				fList.splice(i, 1);
				info.prc = 0;
				i--;
			}
			if (info.mc != null) {
				Col.setPercentColor(info.mc, info.prc, 0xFFFFFF);
			}
			info.prc *= Math.pow(0.85, Timer.tmod);
			i++;
		}

		var list = pList.copy();
		for (part in list)
			part.update();
	}

	function recordGridClick():Void {
		if (isReplayMode || lock || init_timer > 0 || !MouseManager.isButtonJustPressed(MouseManager.BUTTON_LEFT))
			return;

		var cell = getMouseCell();
		if (cell == null)
			return;

		KadoKadeoManager.kkm.replay.recordEvent(cell);
		pendingLiveClicks.push(cell);
	}

	function getMouseCell():Null<Int> {
		var left = Const.PX - Const.BSIZE * 0.5;
		var top = Const.PY - Const.BSIZE * 0.5;
		var mouseX = MouseManager.getX();
		var mouseY = MouseManager.getY();
		var right = left + Const.WIDTH * Const.BSIZE;
		var bottom = top + Const.HEIGHT * Const.BSIZE;
		if (mouseX < left || mouseX >= right || mouseY < top || mouseY >= bottom)
			return null;

		var x = Std.int(Math.floor((mouseX - left) / Const.BSIZE));
		var y = Std.int(Math.floor((mouseY - top) / Const.BSIZE));
		return y * Const.WIDTH + x;
	}

	function applyReplayEvent(event:Dynamic):Void {
		if (!Std.isOfType(event, Int))
			return;
		applyCellClick(cast event);
	}

	function applyCellClick(cell:Int):Void {
		if (cell < 0 || cell >= Const.WIDTH * Const.HEIGHT)
			return;

		var x = cell % Const.WIDTH;
		var y = Std.int(cell / Const.WIDTH);
		onSelect(level.tbl[x][y]);
	}

	public function destroy():Void {}

	public function flash(mc:ASprite):Void {
		fList.push({mc: mc, prc: 100});
	}

	public function newPart(link:String):Part {
		var p = new Part();
		var mc = dmanager.attach(link, Const.PLAN_PART);
		p.setSkin(mc);
		p.game = this;
		pList.push(p);
		p.init();
		mc.play();
		return p;
	}
}
