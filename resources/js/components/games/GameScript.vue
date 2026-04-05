<script setup>
import { onBeforeUnmount, onMounted, ref, useAttrs } from 'vue'

import { useGame } from '@/composables/useGame'

const props = defineProps({
  game: { type: Object, required: true },
  args: { type: Object, default: () => ({}) },
  gameWidth: { type: Number, default: 300 },
  gameHeight: { type: Number, default: 320 },
  canvasStyle: { type: Object, default: () => ({}) },
})

const canvas = ref(null)
const attrs = useAttrs()
const { mount, destroy, invalidate } = useGame(() => props.game)

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
