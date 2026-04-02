<script setup>
import { onBeforeUnmount, onMounted, ref } from 'vue'

import { useGame } from '@/composables/useGame'

const props = defineProps({
  game: { type: Object, required: true },
  args: { type: Object, default: () => ({}) },
  gameWidth: { type: Number, default: 300 },
  gameHeight: { type: Number, default: 320 },
  canvasStyle: { type: Object, default: () => ({}) },
})

const canvas = ref(null)
const { mount, destroy, invalidate } = useGame(() => props.game)

async function mountGame() {
  await mount(canvas.value, {
    ...props.args,
    // seed:'123',
    // replayData: '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',
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
  <div class="relative" :style="{ width: props.gameWidth + 'px', height: props.gameHeight + 'px' }">
    <canvas
      ref="canvas"
      :width="900"
      :height="960"
      :style="{ width: gameWidth + 'px', height: gameHeight + 'px', ...props.canvasStyle }"
    >
      <p>
        Votre navigateur ne supporte pas Canvas. Veuillez installer un navigateur plus moderne afin
        de jouer.
      </p>
    </canvas>
  </div>
</template>
