import { toValue } from 'vue'

const scriptRegistry = {}

function loadScript(url) {
  const existing = scriptRegistry[url]
  if (existing) {
    existing.refCount += 1
    return existing.promise
  }

  const script = document.createElement('script')
  script.src = url
  script.dataset.kadoGameScript = url

  const promise = new Promise((resolve, reject) => {
    script.addEventListener('load', () => resolve())
    script.addEventListener('error', () => reject(new Error(`Failed to load game script: ${url}`)))
  })

  scriptRegistry[url] = {
    node: script,
    promise,
    refCount: 1,
  }

  document.body.appendChild(script)
  return promise
}

function unloadScript(url, globalName) {
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

  if (globalName && window[globalName]) {
    delete window[globalName]
  }
  delete window.KadoKadeo
}

export function useGame(game) {
  let gameInstance = null
  let activeScript = null
  let loadToken = 0

  function destroy() {
    if (gameInstance && typeof gameInstance.destroy === 'function') {
      gameInstance.destroy(true)
    }
    gameInstance = null

    if (activeScript) {
      unloadScript(activeScript.src, activeScript.global)
    }
    activeScript = null
    PIXI.utils.destroyTextureCache()
    PIXI.utils.clearTextureCache()
    PIXI.Loader.shared.resources = {}
  }

  async function mount(canvas, args = {}) {
    const token = ++loadToken
    destroy()

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
      unloadScript(config.src, config.global)
      return
    }

    const gameClass = window[config.global]
    if (typeof window.KadoKadeo !== 'function' || typeof gameClass !== 'function') {
      console.error('Game globals are missing:', {
        kadoKadeo: window.KadoKadeo,
        gameClass,
      })
      unloadScript(config.src, config.global)
      throw new Error(`Game globals are missing for ${config.src} - ${config.global}`)
    }

    activeScript = config
    gameInstance = new window.KadoKadeo(canvas, gameClass, {
      ...args,
      name: currentGame.name.toLowerCase().replaceAll(/\W/g, ''),
      gameId: currentGame.id,
    })
  }

  function invalidate() {
    loadToken += 1
  }

  return {
    mount,
    destroy,
    invalidate,
  }
}
