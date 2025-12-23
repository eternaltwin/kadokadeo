<!-- eslint-disable no-undef -->
<script setup>

import { onBeforeUnmount, onMounted, ref } from 'vue'

const props = defineProps({
  gameWidth: { type: Number, default: 300 },
  gameHeight: { type: Number, default: 320 },
})

const canvas = ref(null)

onMounted(() => {
  const game = new window.KadoKadeo(canvas.value, window.GameChocoMouche)
  console.log(game)
})

onBeforeUnmount(() => {
})
</script>

<template>
  <div class="relative" :style="{ width: props.gameWidth+'px', height: props.gameHeight+'px'}">
    <canvas
      id="gameCanvas"
      ref="canvas"
      :width="gameWidth"
      :height="gameHeight"
      :style="{ width: gameWidth + 'px', height: gameHeight + 'px' }"
    >
      <p>
        Votre navigateur ne supporte pas Canvas. Veuillez installer un navigateur plus moderne afin de
        jouer.
      </p>
    </canvas>
  </div>
</template>
