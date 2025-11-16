<script setup>
import Number from '@/components/Number.vue'
import GameScript from '@/components/games/GameScript.vue'
import { formatTime } from '@/composables/helpers'
import { useGames } from '@/composables/useGames'
import { ref } from 'vue'

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

  <template v-if="isLoading || !game">Chargement ...</template>
  <div v-else class="relative">
    <h2>{{ game.name }}</h2>
    <GameScript :game="game" :args="['--daily=true']" :game-width="600" :game-height="640" />
    <div>
      <h2>Scores</h2>
      <table>
        <thead>
          <tr>
            <th>Position</th>
            <th>Joueur</th>
            <th>Score</th>
            <th>Temps</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="(score, k) in scores" :key="score.id">
            <td>{{ k + 1 }}</td>
            <td>{{ score.user?.display_name ?? 'Inconnu' }}</td>
            <td><Number :value="score.score" color="orange" /></td>
            <td>
              <RouterLink
                v-if="score.has_replay"
                :to="{ name: 'runs.show', params: { id: score.id } }"
              >
                {{ formatTime(score.play_time_seconds) }}
              </RouterLink>
              <template v-else>
                {{ formatTime(score.play_time_seconds) }}
              </template>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
