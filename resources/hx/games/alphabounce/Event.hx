package alphabounce;

class Event {
	public function new() {
		Game.me.events.push(this);
	}

	public function update() {}

	public function kill() {
		Game.me.events.remove(this);
	}
}
