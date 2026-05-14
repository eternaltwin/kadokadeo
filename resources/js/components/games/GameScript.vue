<script setup>
const props = defineProps({
  game: { type: Object, required: true },
  args: { type: Object, default: () => ({}) },
  gameWidth: { type: Number, default: 300 },
  gameHeight: { type: Number, default: 320 },
  canvasStyle: { type: Object, default: () => ({}) },
})

const canvas = ref(null)
const attrs = useAttrs()
const { mount, destroy, invalidate, crash } = useGame(() => props.game)
const showTechnicalDetails = ref(false)
const copyFeedback = ref('')

const technicalDetails = computed(() => {
  if (!crash.value) {
    return ''
  }

  const details = [
    'KadoKadeo runtime crash',
    `message: ${crash.value.message ?? 'Unknown error'}`,
    `state: ${crash.value.runState ?? 'unknown'}`,
    `score: ${crash.value.score ?? 'n/a'}`,
    `timestamp: ${crash.value.timestamp ?? new Date().toISOString()}`,
    '',
    'stack:',
    crash.value.stack ?? '(no stack trace available)',
  ]

  return details.join('\n')
})

watch(crash, (value) => {
  if (value) {
    showTechnicalDetails.value = false
  }
  copyFeedback.value = ''
})

async function copyTechnicalDetails() {
  const text = technicalDetails.value
  if (!text) {
    return
  }

  try {
    if (navigator?.clipboard?.writeText) {
      await navigator.clipboard.writeText(text)
      copyFeedback.value = 'Détails techniques copiés.'
      return
    }
  } catch {
    copyFeedback.value = 'Copie impossible. Veuillez copier manuellement.'
  }
}

async function mountGame() {
  await mount(canvas.value, {
    ...props.args,
    // seed:'123',
    // replayData: '',
  })
}

onMounted(async() => {
  await mountGame()
})

onBeforeUnmount(() => {
  invalidate()
  destroy()
})
</script>

<template>
  <div class="relative" :style="{ width: props.gameWidth + 'px', height: props.gameHeight + 'px', ...attrs.style ?? {} }">
    <div v-if="crash" class="error absolute top-2 right-2 left-2 z-20">
      <div class="text-xs">
        <p>Un problème technique est survenu pendant la partie.</p>
        <p>Vous pouvez nous envoyer les détails techniques pour faciliter le diagnostic.</p>
        <div class="mt-2 flex flex-wrap gap-2">
          <button
            type="button"
            class="cursor-pointer border border-pink-400 bg-white px-2.5 py-1.5 text-xs leading-none font-bold text-pink-700"
            @click="showTechnicalDetails = !showTechnicalDetails"
          >
            {{ showTechnicalDetails ? 'Masquer les détails techniques' : 'Voir les détails techniques' }}
          </button>
          <button
            type="button"
            class="cursor-pointer border border-pink-400 bg-white px-2.5 py-1.5 text-xs leading-none font-bold text-pink-700"
            @click="copyTechnicalDetails"
          >
            Copier les détails techniques
          </button>
          <div v-if="copyFeedback">{{ copyFeedback }}</div>
          <button
            type="button"
            class="cursor-pointer border border-pink-400 bg-white px-2.5 py-1.5 text-xs leading-none font-bold text-pink-700"
            @click="crash = null"
          >
            Fermer ce message
          </button>
        </div>
        <textarea
          v-if="showTechnicalDetails"
          class="mt-2.5 max-h-[280px] min-h-[140px] w-full resize-y font-mono text-xs"
          readonly
          :value="technicalDetails"
        />
      </div>
    </div>
    <canvas
      ref="canvas"
      :width="900"
      :height="960"
      :style="{
        width: gameWidth + 'px',
        height: gameHeight + 'px',
        touchAction: 'none',
        userSelect: 'none',
        ...props.canvasStyle,
      }"
    >
      <p>
        Votre navigateur ne supporte pas Canvas. Veuillez installer un navigateur plus moderne afin
        de jouer.
      </p>
    </canvas>
  </div>
</template>
