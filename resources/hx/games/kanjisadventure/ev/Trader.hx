package kanjisadventure.ev;

import kanjisadventure.*;
import common_haxe_avm1.KeyboardManager;
import common_haxe_avm1.MouseManager;
import mt.DepthManager;
import pixi.core.text.Text;

class SlotShopSprite extends ASprite {
	public var field:Text;
	public var fieldGold:Text;
	public var item:ASprite;
	public var id:Int;
	public var price:Int;
	public var flInv:Bool;
	public var index:Int;
	public var enabled:Bool;
}

class McPanelSprite extends ASprite {
	public var field:Text;
}

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

	public var flFirst:Bool;

	var bg:ASprite;
	var mcPanel:McPanelSprite;

	var slots:Array<SlotShopSprite>;
	var hoveredSlot:Int;

	// var dm:mt.DepthManager;

	public function new(?first) {
		flFirst = first;
		super();
		bg = Game.me.dm.empty(Game.DP_FADER);
		bg.getGraphics()
			.beginFill(0x000000)
			.drawRect(0, 0, KadoKadeoManager.I(Cs.mcw), KadoKadeoManager.I(Cs.mch))
			.endFill();
		bg._alpha = 0;

		spc = 0.1;
		slots = [];
		hoveredSlot = -1;
		Game.me.displayItems(false);
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
				updateInput();
			case 2:
				bg._alpha = (1 - coef) * 50;
				if (coef == 1) {
					bg.removeMovieClip();
					kill();
					step++;
				}
		}
	}

	public function attachPanel() {
		mcPanel = cast Game.me.dm.attach("mcPanel", Game.DP_INTER);
		mcPanel._x = (Cs.mcw - KadoKadeoManager.I(240)) * 0.5;
		mcPanel._y = Cs.bh + ((Cs.mch - Cs.bh) - KadoKadeoManager.I(100)) * 0.5;
		mcPanel.field = mcPanel.initTextField("field", {
			font: "verdana",
			size: 22,
			align: "center",
			color: 0xFFFFFF,
			stroke: "#1D2161",
			strokeThickness: KadoKadeoManager.I(2),
			x: KadoKadeoManager.I(120),
			y: KadoKadeoManager.I(80),
		});

		var seed = new mt.Rand(Game.me.did + Game.me.cfl.id);

		var dm = new DepthManager(mcPanel);
		var a = ITEMS_STD.copy();
		var list = [];
		for (i in 0...4) {
			var o = a[seed.random(a.length)];
			list.push(o);
			a.remove(o);
		}

		var id = 0;
		slots = [];
		hoveredSlot = -1;
		for (o in list) {
			var mc:SlotShopSprite = cast dm.attach("slotShop", 0);
			mc._x = KadoKadeoManager.I(8) + (id % 2) * KadoKadeoManager.I(115);
			mc._y = KadoKadeoManager.I(8) + Math.floor(id / 2) * KadoKadeoManager.I(35);
			mc.field = mc.initTextField("field", {
				font: "verdana",
				size: 18,
				color: 0xFFFFFF,
				stroke: "#1D2161",
				strokeThickness: KadoKadeoManager.I(2),
				x: KadoKadeoManager.I(30),
				y: KadoKadeoManager.I(-2),
			});
			mc.fieldGold = mc.initTextField("fieldGold", {
				font: "verdana",
				size: 18,
				color: 0xFFFFFF,
				stroke: "#1D2161",
				strokeThickness: KadoKadeoManager.I(2),
				x: KadoKadeoManager.I(41),
				y: KadoKadeoManager.I(11),
			});
			mc.field.text = Lang.ITEMS[o.id];
			mc.fieldGold.text = Std.string(o.price);
			mc.item = mc.attachMovie("mcItem", "item");
			mc.item.gotoAndStop(o.id + 1);
			mc.id = o.id;
			mc.flInv = o.flInv;
			mc.price = o.price;
			mc.index = id;
			mc.enabled = false;
			id++;
			slots.push(mc);
		}

		updateSlots();
	}

	public function updateSlots() {
		var flNoRoom = false;

		var str = Lang.TRADER[0];
		var n = 0;

		for (mc in slots) {
			var flOk = mc.price <= Game.me.gold;
			if (flOk) {
				if (mc.flInv && Game.me.inventory.length >= Game.me.bagSize) {
					flNoRoom = true;
					flOk = false;
				}
			}

			if (mc.id == 13 && Game.me.bagSize > 3)
				flOk = false; // BAGPACK
			mc.enabled = flOk;

			if (flOk) {
				mc._alpha = 100;
				n++;
			} else {
				mc._alpha = 20;
				unselect(mc);
			}
		}

		if (n == 0) {
			str = Lang.TRADER[1];
			if (flNoRoom)
				str = Lang.TRADER[2];
		}
		mcPanel.field.text = str;
	}

	function updateInput():Void {
		var slotIndex = getSlotAtMouse();
		if (slotIndex != hoveredSlot) {
			var itemId = slotIndex < 0 ? -1 : slots[slotIndex].id;
			applyHover(slotIndex, itemId);
		}

		if (MouseManager.isButtonJustPressed(MouseManager.BUTTON_LEFT)) {
			if (slotIndex >= 0)
				Game.me.queueTraderBuy(slotIndex, slots[slotIndex].id);
			else if (!isMouseOverPanel())
				Game.me.queueTraderLeave();
		}

		if (isExitKeyJustPressed())
			Game.me.queueTraderLeave();
	}

	function getSlotAtMouse():Int {
		var mouseX = MouseManager.getX();
		var mouseY = MouseManager.getY();
		for (mc in slots)
			if (mc.enabled && mc.getBounds().contains(mouseX, mouseY))
				return mc.index;
		return -1;
	}

	function isMouseOverPanel():Bool {
		return mcPanel != null && mcPanel.getBounds().contains(MouseManager.getX(), MouseManager.getY());
	}

	function isExitKeyJustPressed():Bool {
		return KeyboardManager.isJustDown(KeyboardManager.RIGHT)
			|| KeyboardManager.isJustDown(KeyboardManager.DOWN)
			|| KeyboardManager.isJustDown(KeyboardManager.LEFT)
			|| KeyboardManager.isJustDown(KeyboardManager.UP)
			|| KeyboardManager.isJustDown(KeyboardManager.D)
			|| KeyboardManager.isJustDown(KeyboardManager.S)
			|| KeyboardManager.isJustDown(KeyboardManager.Q)
			|| KeyboardManager.isJustDown(KeyboardManager.A)
			|| KeyboardManager.isJustDown(KeyboardManager.Z)
			|| KeyboardManager.isJustDown(KeyboardManager.W)
			|| KeyboardManager.isJustDown(KeyboardManager.SPACE)
			|| KeyboardManager.isJustDown(KeyboardManager.SHIFT)
			|| KeyboardManager.isJustDown(KeyboardManager.ENTER);
	}

	function select(mc:ASprite) {
		mc.blendMode = BlendModes.ADD;
	}

	function unselect(mc:ASprite) {
		mc.blendMode = BlendModes.NORMAL;
	}

	public function applyHover(slotIndex:Int, itemId:Int):Void {
		if (hoveredSlot >= 0 && hoveredSlot < slots.length)
			unselect(slots[hoveredSlot]);
		hoveredSlot = -1;

		if (step != 1 || slotIndex < 0 || slotIndex >= slots.length)
			return;
		var mc = slots[slotIndex];
		if (!mc.enabled || mc.id != itemId)
			return;
		select(mc);
		hoveredSlot = slotIndex;
	}

	public function applyBuy(slotIndex:Int, itemId:Int):Void {
		if (step != 1 || slotIndex < 0 || slotIndex >= slots.length)
			return;
		var mc = slots[slotIndex];
		if (!mc.enabled || mc.id != itemId)
			return;
		buy(mc);
	}

	public function applyLeave():Void {
		if (step == 1)
			leave();
	}

	function buy(mc:SlotShopSprite) {
		Game.me.flMute = true;
		Game.me.pickUp(mc.id);
		Game.me.flMute = false;
		Game.me.gold -= mc.price;
		Game.me.displayGold();
		updateSlots();
	}

	function leave() {
		coef = 0;
		step = 2;
		hoveredSlot = -1;
		if (mcPanel != null) {
			mcPanel.removeMovieClip();
			mcPanel = null;
		}
	}
}
