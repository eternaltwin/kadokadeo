<script setup>
import { formatScore } from '@/composables/helpers'
import { useApi } from '@/composables/useApi'

const periodStore = usePeriodStore()
const { get, isLoading, error } = useApi()

const period = ref(null)
const ranking = ref([])
const games = ref([])
const search = ref('')
const showAllRows = ref(false)
const visibleRows = ref(50)
const expandedUsers = ref({})

const selectedGameId = ref(null)
const scoreInput = ref(0)
const resultPoints = ref(null)

const currentPeriodId = computed(() => periodStore.period?.id || null)
const filteredRanking = computed(() => {
  const normalizedSearch = search.value.trim().toLowerCase()
  const players = showAllRows.value ? ranking.value : ranking.value.slice(0, visibleRows.value)

  if (!normalizedSearch) {
    return players
  }

  return players.filter((player) => player.name.toLowerCase().includes(normalizedSearch))
})

const toggleDetails = (userId) => {
  expandedUsers.value[userId] = !expandedUsers.value[userId]
}

const loadGames = async() => {
  const response = await get('/games')
  games.value = response.data.data ?? response.data
  if (games.value.length > 0 && !selectedGameId.value) {
    selectedGameId.value = games.value[0].id
  }
}

const loadRanking = async() => {
  const response = await get('/challenge-1500/ranking', {
    params: {
      period: period.value,
    },
  })
  ranking.value = response.data
  expandedUsers.value = {}
}

const calculate = async() => {
  if (!selectedGameId.value && selectedGameId.value !== 0) {
    return
  }

  const response = await get('/challenge-1500/calculate', {
    params: {
      gameId: selectedGameId.value,
      score: scoreInput.value,
    },
  })
  resultPoints.value = response.data.points
}

watch(currentPeriodId, async(newPeriod) => {
  if (!newPeriod) {
    return
  }

  period.value = newPeriod

  await loadRanking()
}, { immediate: true })

loadGames()
</script>

<template>
  <div class="w-3/4">
    <h1 class="mt-0 text-center">Tournoi des 1500</h1>
    <p class="mb-4 text-sm text-slate-700">
      Les 12 meilleurs jeux de chaque joueur sont retenus, avec un maximum de 1 500 points par jeu (objectif 18 000).
    </p>

    <div class="my-4 flex flex-wrap gap-3 items-center">
      <span class="font-bold">Période en cours: {{ currentPeriodId || '-' }}</span>

      <input
        v-model="search"
        type="text"
        placeholder="Rechercher un joueur..."
        class="px-2 py-1 border border-slate-400"
      >

      <button
        class="text-orange-400 underline cursor-pointer hover:text-orange-500"
        @click="showAllRows = true"
      >
        Tout afficher
      </button>
    </div>

    <div class="my-4 p-4 border border-slate-400 bg-slate-100">
      <h3 class="font-bold mb-2">Calculateur</h3>
      <div class="flex flex-wrap gap-3 items-center">
        <label for="gameSelect">Jeu</label>
        <select id="gameSelect" v-model="selectedGameId">
          <option v-for="game in games" :key="game.id" :value="game.id">{{ game.name }}</option>
        </select>

        <label for="scoreInput">Score</label>
        <input id="scoreInput"
               v-model.number="scoreInput"
               type="number"
               min="0"
               class="px-2 py-1 border border-slate-400">

        <button class="text-orange-400 underline cursor-pointer hover:text-orange-500" @click="calculate">
          Calculer
        </button>

        <span v-if="resultPoints !== null" class="font-bold">{{ formatScore(resultPoints) }} pts</span>
      </div>
    </div>

    <Loader v-if="isLoading" />
    <MessageError v-else-if="error">{{ error }}</MessageError>

    <table v-else class="w-full text-sm">
      <thead>
        <tr>
          <th class="text-left">#</th>
          <th class="text-left">Joueur</th>
          <th class="text-left">Détails</th>
          <th class="text-right">Points</th>
        </tr>
      </thead>
      <tbody>
        <template v-for="player in filteredRanking" :key="player.userId">
          <tr>
            <td>{{ player.rank }}</td>
            <td>
              <RouterLink :to="{ name: 'profile.show', params: { id: player.userId } }" class="text-orange-700">
                {{ player.name }}
              </RouterLink>
            </td>
            <td>
              <button class="text-orange-400 underline cursor-pointer hover:text-orange-500" @click="toggleDetails(player.userId)">
                {{ expandedUsers[player.userId] ? 'Masquer' : 'Voir' }} ({{ player.bestGames.length }} jeux)
              </button>
            </td>
            <td class="text-right font-bold">{{ formatScore(player.totalPoints) }}</td>
          </tr>
          <tr v-if="expandedUsers[player.userId]">
            <td colspan="4" class="bg-slate-100">
              <div class="grid md:grid-cols-2 gap-1 py-2">
                <div v-for="game in player.bestGames" :key="`${player.userId}-${game.game}`">
                  {{ game.game }}: {{ formatScore(game.score) }} -> {{ formatScore(game.points) }} pts
                </div>
              </div>
            </td>
          </tr>
        </template>
      </tbody>
    </table>
  </div>
</template>
