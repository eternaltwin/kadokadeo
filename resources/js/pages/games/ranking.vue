<script setup>
import { ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'

import GameScoreTable from '@/components/games/GameScoreTable.vue'
import Loader from '@/components/Loader.vue'
import Error from '@/components/message/Error.vue'
import { useGameRanking } from '@/composables/useGameRanking'
import { useGames } from '@/composables/useGames'
import { usePeriodStore } from '@/stores/period'

const route = useRoute()
const router = useRouter()
const gameId = route.params.id
const { isLoading: isGameLoading, error: gameError, fetchGame } = useGames()
const { isLoading, error, period, results, hasNextPage, fetchGameRanking } = useGameRanking(gameId)
const periodStore = usePeriodStore()
const game = ref(null)

fetchGame(gameId).then((data) => {
  game.value = data.data
})

period.value = route.query.period || null

watch(period, (newVal) => {
  router.push({ query: { ...route.query, period: newVal || undefined } })
})

fetchGameRanking()
</script>

<template>
  <Loader v-if="isGameLoading" />
  <div v-else-if="game" class="relative w-3/4">
    <h2>Classement général de {{ game.name }}</h2>

    <div class="mb-4 text-center">
      <select id="period" v-model="period">
        <option :value="null">Toutes les périodes</option>
        <option v-for="periodOption in periodStore.period?.id" :key="periodOption" :value="periodOption">
          Période {{ periodOption }}
        </option>
      </select>
    </div>

    <GameScoreTable :scores="results" />
    <div v-if="hasNextPage" class="mt-4 text-center">
      <button
        @click="fetchGameRanking()"
        :disabled="isLoading"
        class="text-orange-400 underline cursor-pointer hover:text-orange-500"
      >
        Charger plus de résultats
      </button>
      <Loader v-if="isLoading" />
      <Error v-else-if="error">{{ error }}</Error>
    </div>
    <Error v-else-if="gameError">{{ gameError }}</Error>
  </div>
</template>
