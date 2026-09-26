package kanjisadventure;

import mt.Timer;

class Event {
	var coef:Float;
	var spc:Float;
	var step:Int;

	public function new() {
		Game.me.event = this;
		Game.me.step = Event;
		coef = 0;
		step = 0;
		spc = 0;
		Game.me.displayItems(false);
	}

	public function update() {
		coef = Math.min(coef + spc * Timer.tmod, 1);
	}

	public function kill() {
		Game.me.event = null;
		Game.me.checkEvents();
	}
}
