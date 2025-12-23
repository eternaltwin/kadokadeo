package kado;

import js.Browser;
import pixi.core.ticker.Ticker;

class FixedFramerate {
  public static inline var STEP = 1 / 60; // 16.666 ms

  var accumulator:Float = 0;
  var update:Float->Void;

  public function new(update) {
    this.update = update;
  }

  public function onTick(deltaTime:Float):Void {
    // deltaTime = frames @ 60fps
    var dt = deltaTime * STEP;

    accumulator += dt;

    // éviter la spirale de la mort
    if (accumulator > 0.25)
      accumulator = 0.25;

    while (accumulator >= STEP) {
      update(Browser.window.performance.now());
      accumulator -= STEP;
    }
  }
}
