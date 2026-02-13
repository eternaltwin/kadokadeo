<!-- eslint-disable no-undef -->
<script setup>
import { onBeforeUnmount, onMounted, ref } from 'vue'

const props = defineProps({
  game: { type: Object, required: true },
  gameWidth: { type: Number, default: 300 },
  gameHeight: { type: Number, default: 320 },
})

const canvas1 = ref(null)

onMounted(async() => {
  // await import('@/games/kanji_gaiden')
  await import('@/games/atlanteine')
  // await import('@/games/chocomouche')
  // const game1 = new window.KadoKadeo(canvas1.value, window.GameKanjiGaiden)
  const game1 = new window.KadoKadeo(canvas1.value, window.GameAtlanteine, {
    // replayData: 'eJxFjiEKAmEYRN+ISfAG1l0Xs2BetAkKFsFm8AKCZzAYBBE0eDuDtxBX+Jn5yvcYHsws28VaiD5jGipqRtDx/9R9TYxMCzZoZqQtWKG5kXPSS9JrwRrdjNzjPuI+477ivrPhkw3f7O3JeweyOzSykts2RrZy287IPu4h7jHpKekPCRsR7g==',
  })
  // const game1 = new window.KadoKadeo(canvas1.value, window.GameChocoMouche)
})

onBeforeUnmount(() => {
})
</script>

<template>
  <div class="relative" :style="{ width: props.gameWidth+'px', height: props.gameHeight+'px'}">
    <canvas
      ref="canvas1"
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
