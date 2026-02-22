import Easing from './Easing'
import Tween from './Tween'
import TweenManager from './TweenManager'
import TweenPath from './TweenPath'

//extend pixi graphics to draw tweenPaths
window.PIXI.Graphics.prototype.drawPath = function(path) {
  path.parsePoints()
  this.drawShape(path.polygon)
  return this
}

let tween = {
  TweenManager: TweenManager,
  Tween: Tween,
  Easing: Easing,
  TweenPath: TweenPath,
}

if (!window.PIXI.tweenManager) {
  window.PIXI.tweenManager = new TweenManager()

  window.PIXI.tween = tween
}
export default tween
