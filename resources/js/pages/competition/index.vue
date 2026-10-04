<script setup>
const { isLoading: isRankingV1Loading, error: leaderboardError, get: getLeaderboard } = useApi()
const { isLoading: isFeathersLoading, error: feathersError, get: getFeathersLeaderboard } = useApi()
const { isLoading: isGamesLoading, error: gamesError, fetchGames } = useGames()
const leaderboard = ref([])
const feathersLeaderboard = ref([])
const games = ref([])
const selectedGameId = ref('')
const scoreInput = ref('')

getLeaderboard('/competition')
  .then((response) => {
    leaderboard.value = response.data
  })
  .catch(() => null)

getFeathersLeaderboard('/competition/poids-plumes')
  .then((response) => {
    feathersLeaderboard.value = response.data
  })
  .catch(() => null)

fetchGames()
  .then((response) => {
    games.value = response.data
  })
  .catch(() => null)

const selectedGame = computed(() => games.value.find((game) => String(game.id) === selectedGameId.value))
const scoreOn1500 = computed(() => {
  if (!selectedGame.value || scoreInput.value === '') return ''

  const score = Number(scoreInput.value)
  const [green, orange, red] = (selectedGame.value.stars ?? []).slice(0, 3).map(Number)
  if (![score, green, orange, red].every(Number.isFinite) || green <= 0 || orange <= green || red <= orange || score <= 0) {
    return 0
  }

  let convertedScore
  if (score <= green) {
    convertedScore = (score / green) * 1150
  } else if (score <= orange) {
    convertedScore = 1150 + ((score - green) / (orange - green)) * 100
  } else if (score <= red) {
    convertedScore = 1250 + ((score - orange) / (red - orange)) * 100
  } else {
    convertedScore = 1350 + ((score - red) / (red - orange)) * 100
  }

  return Math.round(Math.min(convertedScore, 1500))
})
</script>

<template>
  <NavTabs :items="[
    { label: 'Ranking V1', value: 'rankingv1' },
    { label: 'Poids plumes', value: 'feathers' },
  ]">
    <template #panel="{ item }">
      <div v-if="item.value === 'rankingv1'">
        <h1 class="mt-0 text-center">Le classement V1</h1>
        <p class="mb-4 text-center">Période courante · 12 meilleurs jeux</p>

        <section class="mx-2 mb-4 grid gap-3 border border-kado-cyan-800 p-3 md:grid-cols-3">
          <h2 class="col-span-full m-0 p-0 text-base">Calculateur 1500</h2>
          <label for="score-game" class="flex flex-col gap-1">
            Jeu
            <select id="score-game" v-model="selectedGameId" :disabled="isGamesLoading || !!gamesError" class="min-h-10 border border-kado-cyan-800 bg-white px-2">
              <option value="">Sélectionner un jeu</option>
              <option v-for="game in games" :key="game.id" :value="String(game.id)">
                {{ game.name }}
              </option>
            </select>
          </label>
          <label for="score-input" class="flex flex-col gap-1">
            Votre score
            <input id="score-input" v-model="scoreInput" type="number" min="0" step="1" inputmode="numeric" class="min-h-10 border border-kado-cyan-800 bg-white px-2" />
          </label>
          <label for="score-1500" class="flex flex-col gap-1">
            Score en mode 1500
            <input id="score-1500" :value="scoreOn1500" type="text" readonly class="min-h-10 border border-kado-cyan-800 bg-kado-cyan-100 px-2" />
          </label>
          <MessageError v-if="gamesError" class="md:col-span-full">Error: {{ gamesError }}</MessageError>
        </section>

        <Loader v-if="isRankingV1Loading">Chargement du classement...</Loader>
        <MessageError v-else-if="leaderboardError">Error: {{ leaderboardError }}</MessageError>
        <div v-else class="px-2">
          <table class="w-full">
            <thead>
              <tr class="text-kado-orange uppercase text-sm *:px-2 *:text-right">
                <th>Rang</th>
                <th class="text-left">Joueur</th>
                <th>Points</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="player in leaderboard" :key="player.user.etwin_id">
                <td class="text-right">{{ player.rank }}</td>
                <td class="text-left">
                  <RouterLink :to="{ name: 'profile.show', params: { id: player.user.etwin_id } }">
                    {{ player.user.display_name }}
                  </RouterLink>
                </td>
                <td class="text-right"><Number color="blue" :value="player.score" /></td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <div v-else>
        <h1 class="mt-0 text-center">Poids plumes</h1>
        <p class="mb-4 text-center">Période courante</p>

        <Loader v-if="isFeathersLoading">Chargement du classement...</Loader>
        <MessageError v-else-if="feathersError">Error: {{ feathersError }}</MessageError>
        <div v-else class="px-2">
          <table class="w-full">
            <thead>
              <tr class="text-kado-orange uppercase text-sm *:px-2 *:text-right">
                <th>Rang</th>
                <th class="text-left">Joueur</th>
                <th>Plumes</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="player in feathersLeaderboard" :key="player.user.etwin_id">
                <td class="text-right">{{ player.rank }}</td>
                <td class="text-left">
                  <RouterLink :to="{ name: 'profile.show', params: { id: player.user.etwin_id } }">
                    {{ player.user.display_name }}
                  </RouterLink>
                </td>
                <td class="text-right">
                  <span class="inline-flex items-center justify-end gap-0.5">
                    <img
                      v-for="featherIndex in player.feathers_count"
                      :key="featherIndex"
                      src="/gfx/iconFeather.gif"
                      alt=""
                      aria-hidden="true"
                      class="size-4"
                    />
                    <span class="sr-only">{{ player.feathers_count }} plume(s)</span>
                  </span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </template>
  </NavTabs>
</template>