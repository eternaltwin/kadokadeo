/* eslint-disable no-undef */
import 'public/gamesdata/godot.js'

import { ref, shallowRef } from 'vue'

function onProgress(value, total) {
  console.log(`Godot loading progress: ${value} / ${total}`)
}

const engineInstance = shallowRef(
  new Engine({
    canvasResizePolicy: 0,
    ensureCrossOriginIsolationHeaders: true,
    executable: '/gamesdata/godot',
    experimentalVK: false,
    fileSizes: {
      '/gamesdata/godot.wasm': 29107076,
    },
    focusCanvas: false,
    gdextensionLibs: [],
    onProgress,
  }),
)
const isEngineLoaded = ref(false)
const currentPck = ref(null)

engineInstance.value.init('/gamesdata/godot').then(() => {
  isEngineLoaded.value = true
})

export function useGodot() {
  const loadPck = async(pckPath, canvasElement, args = []) => {
    if (!engineInstance.value || !isEngineLoaded.value) {
      throw new Error('Engine not initialized')
    }
    args = ['--main-pack', pckPath, ...args, `--server_url=${window.location.origin}`]

    // If a game is already running, quit it first
    if (currentPck.value) {
      // engineInstance.value.requestQuit()
      Engine.unload()
      // // Wait for cleanup
      await new Promise((resolve) => setTimeout(resolve, 1000))
    }

    // Load new PCK
    await engineInstance.value.init('/gamesdata/godot')
    await engineInstance.value.preloadFile(pckPath, pckPath, 17000000)
    await engineInstance.value.start({
      args,
      canvas: canvasElement.id,
      mainPack: pckPath,
    })

    currentPck.value = pckPath
  }

  const cleanup = () => {
    if (engineInstance.value && currentPck.value) {
      engineInstance.value.requestQuit()
      currentPck.value = null
    }
  }

  return {
    engineInstance,
    isEngineLoaded,
    currentPck,
    loadPck,
    cleanup,
  }
}
