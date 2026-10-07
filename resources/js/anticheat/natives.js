// ANTI CHEAT: functions of the browser and of PIXI taken when the page loads (first import of main.js), before a script
// pasted in the console can replace them. Given to the games (useGame.js -> KadoKadeo params.natives, read by
// kac.Natives in resources/hx/lib/common_haxe_avm1): the time of the inputs is read with them (it stirs the RNG of the
// game, kado.ReplayManager), and kac.Integrity compares PIXI with this state during a game.
const getDescriptor = Object.getOwnPropertyDescriptor

// PIXI classes of the games: their prototype methods must stay the ones of the page (PIXI is global, a script could
// wrap them to reach the game)
const PIXI_CLASSES = [
  'Application',
  'Container',
  'DisplayObject',
  'Sprite',
  'Graphics',
  'Text',
  'Ticker',
  'Renderer',
  'AbstractRenderer',
  'InteractionManager',
]

function freezeAll(list) {
  list.forEach((entry) => Object.freeze(entry))
  return Object.freeze(list)
}

function snapshotPixi(PIXI) {
  if (!PIXI) {
    return null
  }
  const classes = []
  const methods = []
  for (const name of PIXI_CLASSES) {
    const C = PIXI[name]
    if (typeof C !== 'function') {
      continue
    }
    classes.push([name, C])
    for (const key of Object.getOwnPropertyNames(C.prototype)) {
      const descriptor = getDescriptor(C.prototype, key)
      if (descriptor && typeof descriptor.value === 'function') {
        methods.push([C.prototype, key, descriptor.value])
      }
    }
  }
  return Object.freeze({ PIXI, classes: freezeAll(classes), methods: freezeAll(methods) })
}

const getRandomValues = crypto.getRandomValues
const apply = Reflect.apply

export const natives = Object.freeze({
  // crypto.getRandomValues
  randomValues: (array) => apply(getRandomValues, crypto, [array]),
  timeStamp: getDescriptor(Event.prototype, 'timeStamp').get,
  addEventListener: EventTarget.prototype.addEventListener,
  removeEventListener: EventTarget.prototype.removeEventListener,
  fnToString: Function.prototype.toString,
  apply: Reflect.apply,
  getOwnPropertyDescriptor: Object.getOwnPropertyDescriptor,
  getOwnPropertyNames: Object.getOwnPropertyNames,
  getPrototypeOf: Object.getPrototypeOf,
  isFrozen: Object.isFrozen,
  freeze: Object.freeze,
  defineProperty: Object.defineProperty,
  pixi: snapshotPixi(window.PIXI),
})
