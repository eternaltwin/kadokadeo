import { ref, toValue } from 'vue'

const scriptRegistry = {}

// ANTI CHEAT: a game bundle doesn't put its classes on window (resources/js/games/build-games.mjs): it gives them
// to this hook, which it deletes. Kept installed only while a bundle is loading.
function installRegisterHook() {
  window.__kadoRegisterGame = (exports, script) => {
    const entry = Object.values(scriptRegistry).find((e) => e.node === script)
    if (entry) {
      entry.exports = exports
    }
    // another bundle still loading
    if (Object.values(scriptRegistry).some((e) => !e.loaded && e !== entry)) {
      installRegisterHook()
    }
  }
}

function removeRegisterHookWhenIdle() {
  if (Object.values(scriptRegistry).every((e) => e.loaded)) {
    delete window.__kadoRegisterGame
  }
}

function loadScript(url) {
  const existing = scriptRegistry[url]
  if (existing) {
    existing.refCount += 1
    return existing.promise
  }

  const script = document.createElement('script')
  script.src = url
  script.dataset.kadoGameScript = url

  const entry = {
    node: script,
    promise: null,
    refCount: 1,
    loaded: false,
    exports: null,
  }
  entry.promise = new Promise((resolve, reject) => {
    script.addEventListener('load', () => {
      entry.loaded = true
      removeRegisterHookWhenIdle()
      resolve()
    })
    script.addEventListener('error', () => {
      entry.loaded = true
      removeRegisterHookWhenIdle()
      reject(new Error(`Failed to load game script: ${url}`))
    })
  })
  scriptRegistry[url] = entry

  installRegisterHook()
  document.body.appendChild(script)
  return entry.promise
}

// the classes given by the bundle: KadoKadeo and Game<Name>
function getGameClasses(url, globalName) {
  const entry = scriptRegistry[url]
  if (!entry) {
    return {}
  }
  if (!entry.exports) {
    // bundles built before the classes were hidden (old versions, played for their replays) put them on window
    entry.exports = { KadoKadeo: window.KadoKadeo, [globalName]: window[globalName] }
    delete window.KadoKadeo
    delete window[globalName]
  }
  return { KadoKadeo: entry.exports.KadoKadeo, gameClass: entry.exports[globalName] }
}

function unloadScript(url) {
  const entry = scriptRegistry[url]
  if (!entry) {
    return
  }

  entry.refCount -= 1
  if (entry.refCount > 0) {
    return
  }

  entry.node?.remove()
  delete scriptRegistry[url]
}

export function useGame(game) {
  let gameInstance = null
  let activeScript = null
  let loadToken = 0
  let crashListenerAttached = false

  const crash = ref(null)

  function onGameCrash(event) {
    crash.value = event?.detail ?? {
      message: 'Unknown game crash',
      phase: 'updatePhysics',
    }
  }

  function attachCrashListener() {
    if (crashListenerAttached || !window?.evts?.addEventListener) {
      return
    }
    window.evts.addEventListener('gameCrash', onGameCrash)
    crashListenerAttached = true
  }

  function detachCrashListener() {
    if (!crashListenerAttached || !window?.evts?.removeEventListener) {
      return
    }
    window.evts.removeEventListener('gameCrash', onGameCrash)
    crashListenerAttached = false
  }

  function clearCrash() {
    crash.value = null
  }

  function destroy() {
    detachCrashListener()
    if (gameInstance && typeof gameInstance.destroy === 'function') {
      gameInstance.destroy(true)
    }
    gameInstance = null

    if (activeScript) {
      unloadScript(activeScript.src)
    }
    activeScript = null
    PIXI.utils.destroyTextureCache()
    PIXI.utils.clearTextureCache()
    PIXI.Loader.shared.resources = {}
  }

  async function mount(canvas, args = {}) {
    const token = ++loadToken
    destroy()
    clearCrash()
    attachCrashListener()

    const currentGame = toValue(game)
    const config = {
      src: currentGame?.gamedata?.url ?? currentGame?.gamedata?.file,
      global: currentGame?.pascal_name,
    }

    if (!canvas || !config.src || !config.global) {
      return
    }

    await loadScript(config.src)

    if (token != loadToken) {
      unloadScript(config.src)
      return
    }

    const { KadoKadeo, gameClass } = getGameClasses(config.src, config.global)
    if (typeof KadoKadeo !== 'function' || typeof gameClass !== 'function') {
      console.error('Game classes are missing:', { kadoKadeo: KadoKadeo, gameClass })
      unloadScript(config.src)
      throw new Error(`Game classes are missing for ${config.src} - ${config.global}`)
    }

    activeScript = config
    gameInstance = new KadoKadeo(canvas, gameClass, {
      ...args,
      name: currentGame.name.toLowerCase().replaceAll(/\W/g, ''),
      gameId: currentGame.id,
      // version of the bundle: sent with the run, its replay is played with the same version
      build: currentGame?.gamedata?.hash ?? null,
    })
  }

  function invalidate() {
    loadToken += 1
  }

  return {
    mount,
    destroy,
    invalidate,
    crash,
    clearCrash,
  }
}
