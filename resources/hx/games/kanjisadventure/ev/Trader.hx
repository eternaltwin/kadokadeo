package kanjisadventure.ev;

import pixi.core.text.Text;

typedef SlotShop = {mc:ASprite, hi:ASprite, field:Text, fieldGold:Text, id:Int, price:Int, flInv:Bool, flOk:Bool};

// the shop of the trader: the player clicks the items to buy them, clicks outside (or presses a key) to leave.
// Clicks are replay events (see Game.applyEvent)
class Trader extends Event {
	static var ITEMS_STD = [
		{id: 5, price: 150, flInv: false}, // LEATHER ARMOR
		{id: 6, price: 400, flInv: false}, // IRON ARMOR
		{id: 7, price: 80, flInv: false}, // KNIFE
		{id: 8, price: 180, flInv: false}, // KATANA
		{id: 10, price: 25, flInv: false}, // FOOD
		{id: 14, price: 35, flInv: true}, // POTION
		{id: 11, price: 15, flInv: false}, // SHURIKEN x3
		{id: 13, price: 15, flInv: false}, // SAC-A-DOS
		{id: 25, price: 30, flInv: true}, // SCROLL FIRE
		{id: 26, price: 30, flInv: true}, // SCROLL ICE
		{id: 29, price: 30, flInv: true}, // SCROLL CHAOS
		{id: 30, price: 30, flInv: true}, // SCROLL TELEPORT
		{id: 32, price: 40, flInv: true}, // OS
	];

	// slot click areas (1x): the highlight of slotShop
	static var SLOT_W = 116.5;
	static var SLOT_H = 33;

	public var flFirst:Bool;

	var bg:ASprite;
	var mcPanel:ASprite;
	var panelText:Text;
	var panelX:Float;
	var panelY:Float;

	var slots:Array<SlotShop>;

	public function new(?first:Bool) {
		flFirst = first;
		super();
		bg = Game.me.dm.empty(Game.DP_FADER);
		var g = bg.getGraphics();
		g.beginFill(0x000000);
		g.drawRect(0, 0, Cs.mcw, Cs.mch);
		g.endFill();
		bg._alpha = 0;

		spc = 0.1;
		slots = [];
		Game.me.displayItems(false);
		// taps go to the shop, not to the joystick
		KadoKadeoManager.kkm.setTouchJoystickEnabled(false);
	}

	override function update() {
		super.update();

		switch (step) {
			case 0:
				bg._alpha = coef * 50;
				if (coef == 1) {
					attachPanel();
					step++;
				}

			case 1:
				if (KeyboardManager.isDown(KeyboardManager.LEFT) || KeyboardManager.isDown(KeyboardManager.RIGHT)
					|| KeyboardManager.isDown(KeyboardManager.UP) || KeyboardManager.isDown(KeyboardManager.DOWN)
					|| KeyboardManager.isDown(KeyboardManager.SPACE))
					leave();
				else
					hover(MouseManager.getX(), MouseManager.getY());
			case 2:
				bg._alpha = (1 - coef) * 50;
				if (coef == 1) {
					bg.removeMovieClip();
					KadoKadeoManager.kkm.setTouchJoystickEnabled(true);
					kill();
					step++;
				}
		}
	}

	public function attachPanel() {
		mcPanel = Game.me.dm.attach("panel", Game.DP_INTER);
		var pw = KadoKadeoManager.S(Data.PANEL_SIZE[0]);
		var ph = KadoKadeoManager.S(Data.PANEL_SIZE[1]);
		panelX = (Cs.mcw - pw) * 0.5;
		panelY = Cs.bh + ((Cs.mch - Cs.bh) - ph) * 0.5;
		mcPanel._x = panelX;
		mcPanel._y = panelY;
		mcPanel.updateState();

		var tp = Data.TEXT_PANEL;
		panelText = Txt.make(KadoKadeoManager.S(tp[3]), Txt.VERDANA, "center", 0x1D2161, 4);
		panelText.x = KadoKadeoManager.S(tp[0] + tp[2] * 0.5);
		panelText.y = KadoKadeoManager.S(tp[1]);
		mcPanel.addChild(panelText);

		var seed = new mt.Rand(Game.me.did + Game.me.cfl.id);
		var a = ITEMS_STD.copy();
		var list = [];
		for (i in 0...4) {
			var o = a[seed.random(a.length)];
			list.push(o);
			a.remove(o);
		}

		var id = 0;
		slots = [];
		for (o in list) {
			var mc = mcPanel.attachMovie("slotShop", "slot" + id, 1);
			mc._x = KadoKadeoManager.S(8 + (id % 2) * 115);
			mc._y = KadoKadeoManager.S(8 + Math.floor(id / 2) * 35);
			var item = mc.attachMovie("mcItem", "item", 2);
			item.gotoAndStop(o.id + 1);
			var tn = Data.TEXT_SHOPNAME;
			var field = Txt.make(KadoKadeoManager.S(tn[3]), Txt.VERDANA, "left", 0x1D2161, 4);
			field.x = KadoKadeoManager.S(tn[0]);
			field.y = KadoKadeoManager.S(tn[1]);
			field.text = Lang.ITEMS[o.id];
			mc.addChild(field);
			var tg = Data.TEXT_SHOPGOLD;
			var fieldGold = Txt.make(KadoKadeoManager.S(tg[3]), Txt.VERDANA, "left", 0x1D2161, 4);
			fieldGold.x = KadoKadeoManager.S(tg[0]);
			fieldGold.y = KadoKadeoManager.S(tg[1]);
			fieldGold.text = Std.string(o.price);
			mc.addChild(fieldGold);
			var hi = mc.attachMovie("slotShopHi", "smc", 3);
			hi.blendMode = BlendModes.ADD;
			hi._alpha = 0;
			slots.push({
				mc: mc,
				hi: hi,
				field: field,
				fieldGold: fieldGold,
				id: o.id,
				price: o.price,
				flInv: o.flInv,
				flOk: false
			});
			id++;
		}

		updateSlots();
	}

	public function updateSlots() {
		var flNoRoom = false;
		var str = Lang.TRADER[0];
		var n = 0;

		for (s in slots) {
			var flOk = s.price <= Game.me.gold;
			if (flOk) {
				if (s.flInv && Game.me.inventory.length >= Game.me.bagSize) {
					flNoRoom = true;
					flOk = false;
				}
			}

			if (s.id == 13 && Game.me.bagSize > 3)
				flOk = false; // BAGPACK

			s.flOk = flOk;
			if (flOk) {
				s.mc._alpha = 100;
				n++;
			} else {
				s.mc._alpha = 20;
				s.hi._alpha = 0;
			}
		}

		if (n == 0) {
			str = Lang.TRADER[1];
			if (flNoRoom)
				str = Lang.TRADER[2];
		}
		panelText.text = str;
	}

	// slot under a point of the screen
	function slotAt(mx:Float, my:Float):Null<Int> {
		if (step != 1)
			return null;
		for (i in 0...slots.length) {
			var s = slots[i];
			var x0 = panelX + s.mc._x;
			var y0 = panelY + s.mc._y;
			if (mx >= x0 && mx < x0 + KadoKadeoManager.S(SLOT_W) && my >= y0 && my < y0 + KadoKadeoManager.S(SLOT_H))
				return i;
		}
		return null;
	}

	function hover(mx:Float, my:Float) {
		var over = slotAt(mx, my);
		for (i in 0...slots.length) {
			var s = slots[i];
			s.hi._alpha = s.flOk && over == i ? 20 : 0;
		}
	}

	// click of the player: [event kind, slot] or null
	public function getClick(mx:Float, my:Float):Null<Array<Int>> {
		if (step != 1)
			return null;
		var i = slotAt(mx, my);
		if (i != null)
			return slots[i].flOk ? [Game.EV_BUY, i] : null;
		var pw = KadoKadeoManager.S(Data.PANEL_SIZE[0]);
		var ph = KadoKadeoManager.S(Data.PANEL_SIZE[1]);
		if (mx >= panelX && mx < panelX + pw && my >= panelY && my < panelY + ph)
			return null;
		if (my >= 0 && my < Cs.mch)
			return [Game.EV_LEAVE, 0];
		return null;
	}

	public function buyAt(i:Int) {
		if (step != 1 || slots[i] == null || !slots[i].flOk)
			return;
		var s = slots[i];
		Game.me.flMute = true;
		Game.me.pickUp(s.id);
		Game.me.flMute = false;
		Game.me.gold -= s.price;
		Game.me.displayGold();
		updateSlots();
	}

	public function leave() {
		if (step != 1)
			return;
		coef = 0;
		step = 2;
		mcPanel.removeMovieClip();
	}
}
