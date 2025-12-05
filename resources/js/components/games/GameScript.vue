<!-- eslint-disable no-undef -->
<script setup>

import { onBeforeUnmount, onMounted, ref } from 'vue'

import Loader from '@/components/Loader.vue'
import { useGodot } from '@/composables/useGodot'

const props = defineProps({
  game: { type: Object, required: true },
  gameWidth: { type: Number, default: 300 },
  gameHeight: { type: Number, default: 320 },
  args: { type: Array, default: () => [] },
})

const { loadPck, cleanup, engineLoadProgress, isLoading } = useGodot()

const canvas = ref(null)

onMounted(() => {
  loadPck(props.game.gamedata.file, props.game.gamedata.size, canvas.value, props.args)
})

onBeforeUnmount(() => {
  cleanup()
})
</script>

<template>
  <div class="relative" :style="{ width: props.gameWidth+'px', height: props.gameHeight+'px'}">
    <div v-if="engineLoadProgress < 1" class="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2">
      <progress
        :value="engineLoadProgress * 1000"
        :max="1000"
      ></progress>
    </div>
    <Loader v-else-if="isLoading" />
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
