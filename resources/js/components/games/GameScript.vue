<!-- eslint-disable no-undef -->
<script setup>
import { onBeforeUnmount, onMounted, ref, watch } from 'vue'

import { useGame } from '@/composables/useGame'

const props = defineProps({
  game: { type: Object, required: true },
  args: { type: Object, default: () => ({}) },
  gameWidth: { type: Number, default: 300 },
  gameHeight: { type: Number, default: 320 },
})

const canvas1 = ref(null)
const { mount, destroy, invalidate } = useGame(() => props.game)

async function mountGame() {
  await mount(canvas1.value, props.args)
}

onMounted(async() => {
  await mountGame()
})

watch(
  () => [props.game, props.args, props.gameWidth, props.gameHeight],
  async() => {
    if (!canvas1.value) {
      return
    }
    await mountGame()
  },
  { deep: true },
)

onBeforeUnmount(() => {
  invalidate()
  destroy()
})
</script>

<template>
  <div class="relative" :style="{ width: props.gameWidth + 'px', height: props.gameHeight + 'px' }">
    <canvas
      ref="canvas1"
      :width="gameWidth"
      :height="gameHeight"
      :style="{ width: gameWidth + 'px', height: gameHeight + 'px' }"
    >
      <p>
        Votre navigateur ne supporte pas Canvas. Veuillez installer un navigateur plus moderne afin
        de jouer.
      </p>
    </canvas>
  </div>
</template>
