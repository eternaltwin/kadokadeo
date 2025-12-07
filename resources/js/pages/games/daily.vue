<script setup>
import { ref } from 'vue'

import GameScoreTable from '@/components/games/GameScoreTable.vue'
import GameScript from '@/components/games/GameScript.vue'
import Loader from '@/components/Loader.vue'
import { useGames } from '@/composables/useGames'

const { isLoading, fetchDailyGame } = useGames()

const dailyGame = ref(null)
const game = ref(null)
const scores = ref([])

fetchDailyGame().then((data) => {
  game.value = data.data
  scores.value = data.leaderboard
  dailyGame.value = data.dailyGame
})
</script>

<template>
  <h1 class="text-center">Jeu du jour</h1>

  <p>
    Le jeu du jour est choisi aléatoirement chaque jour à minuit.<br />
    Le contrat est commun à tous les joueurs.<br />
    Vous n'avez qu'une seule tentative.
  </p>

  <div v-if="isLoading || !game" class="relative min-h-48">
    <Loader>Chargement ...</Loader>
  </div>
  <div v-else class="relative">
    <h2>{{ game.name }}</h2>
    <GameScript :game="game"
                :args="['--daily=true']"
                :game-width="600"
                :game-height="640" />
    <div>
      <h2>Scores</h2>
      <GameScoreTable :scores="scores" />
    </div>
  </div>
</template>
