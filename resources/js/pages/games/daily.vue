<script setup>
import { onMounted, onUnmounted, toRef } from 'vue'

import DailyGameBlock from '@/components/games/DailyGameBlock.vue'
import GameScoreTable from '@/components/games/GameScoreTable.vue'
import GameScript from '@/components/games/GameScript.vue'
import Loader from '@/components/Loader.vue'
import { useDailyGameStore } from '@/stores/dailyGame'

const dailyGameStore = useDailyGameStore()
const game = toRef(dailyGameStore, 'game')

let intervalId = null


const waitAndRefresh = () => {
  setTimeout(() => {
    dailyGameStore.fetchScores()
  }, 2000)
}

onMounted(() => {
  intervalId = setInterval(dailyGameStore.fetchScores, 1200000)
  window.evts.addEventListener('gameFinished', waitAndRefresh)
  dailyGameStore.fetchDailyGameIfNecessary()
})
onUnmounted(() => {
  clearInterval(intervalId)
  window.evts.removeEventListener('gameFinished', waitAndRefresh)
})
</script>

<template>
  <div class="withRightAside">
    <DailyGameBlock class="mt-4" />

    <div class="relative">
      <Loader v-if="dailyGameStore.isScoresLoading">Chargement des scores...</Loader>
      <h2>Scores</h2>
      <GameScoreTable :scores="dailyGameStore.scores" />
    </div>

    <div v-if="dailyGameStore.isDailyGameLoading || !game" class="relative min-h-48">
      <Loader>Chargement ...</Loader>
    </div>
    <div v-else class="relative">
      <h2>{{ game.name }}</h2>
      <GameScript :game="game"
                  :args="['--daily=true']"
                  :game-width="600"
                  :game-height="640" />
    </div>
  </div>
</template>
