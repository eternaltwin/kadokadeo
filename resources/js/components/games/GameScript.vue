<!-- eslint-disable no-undef -->
<script setup>
import 'public/gamesdata/godot.js'

import { onBeforeUnmount,ref } from 'vue'

const props = defineProps({
  game: { type: Object, required: true },
  gameWidth: { type: Number, default: 300 },
  gameHeight: { type: Number, default: 320 },
  args: { type: Array, default: () => [] },
})

const statusMode = ref('')
const statusProgress = ref(null)
const notices = ref([])

const GODOT_CONFIG = {
  args: [...props.args, `--server_url=${window.location.origin}`],
  canvasResizePolicy: 0,
  ensureCrossOriginIsolationHeaders: true,
  executable: '/gamesdata/godot',
  mainPack: props.game.gamedata.file,
  experimentalVK: false,
  fileSizes: {
    [props.game.gamedata.file]: props.game.gamedata.size,
    '/gamesdata/godot.wasm': 31000000,
  },
  focusCanvas: false,
  gdextensionLibs: [],
}
const GODOT_THREADS_ENABLED = false
const engine = new Engine(GODOT_CONFIG)

onBeforeUnmount(async() => {
  engine.requestQuit()
})

let initializing = true

function setStatusMode(mode) {
  console.log('Setting status mode to', mode, 'initializing=', initializing)
  if (statusMode.value === mode || !initializing) {
    return
  }
  if (mode === 'hidden') {
    initializing = false
  }
  statusMode.value = mode
}

function setStatusNotice(text) {
  const lines = text.split('\n')
  notices.value = lines
}

function displayFailureNotice(err) {
  console.error(err)
  if (err instanceof Error) {
    setStatusNotice(err.message)
  } else if (typeof err === 'string') {
    setStatusNotice(err)
  } else {
    setStatusNotice('An unknown error occurred.')
  }
  setStatusMode('notice')
  initializing = false
}

const missing = Engine.getMissingFeatures({
  threads: GODOT_THREADS_ENABLED,
})

if (missing.length !== 0) {
  if (
    GODOT_CONFIG['serviceWorker'] &&
    GODOT_CONFIG['ensureCrossOriginIsolationHeaders'] &&
    'serviceWorker' in navigator
  ) {
    let serviceWorkerRegistrationPromise
    try {
      serviceWorkerRegistrationPromise = navigator.serviceWorker.getRegistration()
    } catch(err) {
      serviceWorkerRegistrationPromise = Promise.reject(
        new Error('Service worker registration failed.', err),
      )
    }
    // There's a chance that installing the service worker would fix the issue
    Promise.race([
      serviceWorkerRegistrationPromise
        .then((registration) => {
          if (registration != null) {
            return Promise.reject(new Error('Service worker already exists.'))
          }
          return registration
        })
        .then(() => engine.installServiceWorker()),
      // For some reason, `getRegistration()` can stall
      new Promise((resolve) => {
        setTimeout(() => resolve(), 2000)
      }),
    ])
      .then(() => {
        // Reload if there was no error.
        window.location.reload()
      })
      .catch((err) => {
        console.error('Error while registering service worker:', err)
      })
  } else {
    // Display the message as usual
    const missingMsg =
      'Error\nThe following features required to run Godot projects on the Web are missing:\n'
    displayFailureNotice(missingMsg + missing.join('\n'))
  }
} else {
  setStatusMode('progress')
  engine
    .startGame({
      onProgress: function(current, total) {
        if (current > 0 && total > 0) {
          statusProgress.value = { value: current, max: total }
        } else {
          statusProgress.value = null
        }
      },
    })
    .then(() => {
      setStatusMode('hidden')
    }, displayFailureNotice)
}
</script>

<template>
  <!-- TO DO : Personnaliser la barre de chargement -->
  <div v-if="statusMode !== 'hidden'" style="position: absolute; top: 180px; left: 90px">
    <progress
      v-if="statusMode === 'progress'"
      :value="statusProgress?.value ?? undefined"
      :max="statusProgress?.total ?? undefined"
    ></progress>
    <div v-if="statusMode === 'notice'">
      <div v-for="line in notices" :key="line">{{ line }}</div>
    </div>
  </div>
  <canvas
    id="gameCanvas"
    :width="gameWidth"
    :height="gameHeight"
    :style="{ width: gameWidth + 'px', height: gameHeight + 'px' }"
  >
    <p>
      Votre navigateur ne supporte pas Canvas. Veuillez installer un navigateur plus moderne afin de
      jouer.
    </p>
  </canvas>
</template>
