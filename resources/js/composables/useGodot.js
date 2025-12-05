/* eslint-disable no-undef */
import { ref, shallowRef } from 'vue'

const engineInstance = shallowRef(null)
const engineLoadProgress = ref(0)
const isEngineLoaded = ref(false)
const isLoading = ref(false)
const currentPck = ref(null)
const firstLoadPromise = new Promise((resolve) => {
  const checkLoaded = () => {
    if (isEngineLoaded.value) {
      resolve()
    } else {
      setTimeout(checkLoaded, 100)
    }
  }
  checkLoaded()
})

function init() {
  engineInstance.value = new Engine({
    canvasResizePolicy: 0,
    ensureCrossOriginIsolationHeaders: true,
    executable: '/gamesdata/godot',
    experimentalVK: false,
    fileSizes: {
      '/gamesdata/godot.wasm': 29107076,
    },
    focusCanvas: false,
    gdextensionLibs: [],
    onProgress: (value, total) => {
      engineLoadProgress.value = value / total
      if (engineLoadProgress.value >= 1) {
        engineLoadProgress.value = 1
      }
    },
  })
  engineInstance.value.init('/gamesdata/godot').then(() => {
    isEngineLoaded.value = true
    engineLoadProgress.value = 1
  })
}

const script = document.createElement('script')
script.src = '/gamesdata/godot.js'
script.async = true
script.defer = true
script.onload = () => {
  init()
}
document.body.appendChild(script)

export function useGodot() {
  const loadPck = async(pckPath, pckSize, canvasElement, args = []) => {
    isLoading.value = true
    if (!engineInstance.value || !isEngineLoaded.value) {
      await firstLoadPromise
    }
    args = ['--main-pack', pckPath, ...args, `--server_url=${window.location.origin}`]

    // If a game is already running, quit it first
    if (currentPck.value) {
      await cleanup()
    }

    // Load new PCK
    if (!isEngineLoaded.value) {
      await engineInstance.value.init('/gamesdata/godot')
    }
    await engineInstance.value.preloadFile(pckPath, pckPath)
    await engineInstance.value.start({
      args,
      canvas: canvasElement.id,
      mainPack: pckPath,
      fileSizes: {
        [pckPath]: pckSize,
      },
      canvasResizePolicy: 0,
      ensureCrossOriginIsolationHeaders: true,
      executable: '/gamesdata/godot',
      experimentalVK: false,
      focusCanvas: false,
      gdextensionLibs: [],
    })

    currentPck.value = pckPath
    isLoading.value = false
  }

  const cleanup = async() => {
    if (engineInstance.value && currentPck.value) {
      engineInstance.value.requestQuit()
      // Wait for cleanup
      await new Promise((resolve) => setTimeout(resolve, 1000))
      Engine.unload()
      currentPck.value = null
      isEngineLoaded.value = false
    }
  }

  return {
    engineInstance,
    engineLoadProgress,
    isEngineLoaded,
    isLoading,
    currentPck,
    loadPck,
    cleanup,
  }
}
