<script setup>
import GreenStar from '@svg/greenStar.svg'
import OrangeStar from '@svg/orangeStar.svg'
import RedStar from '@svg/redStar.svg'

const route = useRoute()
const userId = computed(() => route.params.id)
const authSore = useAuthStore()
const { isLoading: isHistoryLoading, error: historyError, results: historyResults, hasNextPage: historyHasNextPage, fetchGameHistory } = useUserGameHistory(userId.value ?? authSore.user.etwin_id)

const { fetchProfile, isLoading, error } = useProfile()
const leagueStore = useLeagueStore()

const profile = ref(null)

watchEffect(() => {
  fetchProfile(userId.value).then((data) => {
    profile.value = data
  })
})

const starsByColor = computed(() => {
  return Object.values(profile.value.best_period_runs).reduce((acc, run) => {
    const star = getStarId(run)
    acc[star] = (acc[star] || 0) + 1
    return acc
  }, {})
})
const myStars = computed(() => {
  if (!profile.value) return 0
  return Object.values(profile.value.best_stars).reduce((sum, stars) => sum + (stars + 1), 0)
})
const barWidth = computed(() => {
  const maxStars = profile.value?.max_stars ?? 0.001
  return (myStars.value / maxStars) * 355
})

const gameCount = computed(() => profile.value?.max_stars / 3)
const leagueCount = computed(() => {
  if (!profile.value) return 0
  return Object.values(profile.value.current_leagues).reduce((acc, league) => {
    acc[league.id] = (acc[league.id] || 0) + 1
    return acc
  }, {})
})
const beginnerLeagueCount = computed(() => (leagueCount.value[1] || 0) + gameCount.value - Object.values(leagueCount.value).reduce((sum, count) => sum + count, 0))
const feathersCount = computed(() => {
  if (!profile.value) return 0
  return profile.value.best_period_runs.reduce((count, run) => run.league_rank === 1 && run.league_id === leagueStore.paradiseLeagueId ? count + 1 : count, 0)
})

fetchGameHistory()

function getStarImage(run) {
  const { getStarFromScore } = useGameModel(run.game)
  return getStarFromScore(run.score)
}

function getStarId(run) {
  const { getStarIdFromScore } = useGameModel(run.game)
  return getStarIdFromScore(run.score)
}
</script>

<template>
  <NavTabs
    :items="[
      { label: 'moi', value: 'me' },
      { label: 'dernière période', value: 'last', disabled: true },
      { label: 'stats', value: 'stats', disabled: true },
    ]"
  >
    <template #panel="{ item }">
      <div>
        <div v-if="isLoading">Loading...</div>
        <MessageError v-else-if="error">Error: {{ error }}</MessageError>
        <div v-else-if="profile">
          <div v-if="item.value === 'me'">
            <h1 class="mt-0 text-center">Profil de {{ profile.data.display_name }}</h1>
            <div v-if="feathersCount > 0" class="flex justify-center items-center gap-1 mb-4">
              <img v-for="i in feathersCount"
                   :key="i"
                   src="/gfx/iconFeather.gif"
                   alt="Plume de Piou"
                   class="inline-block" />
            </div>
            <h2>Statut</h2>

            <div class="grid md:grid-cols-2 ">
              <div class="grid grid-cols-3 justify-items-center">
                <div class="flex items-end">
                  <GreenStar class="size-20" />
                  <Number :value="`x${starsByColor[0] ?? 0}`" color="green" />
                </div>
                <div class="flex items-end">
                  <OrangeStar class="size-20" />
                  <Number :value="`x${starsByColor[1] ?? 0}`" color="orange" />
                </div>
                <div class="flex items-end">
                  <RedStar class="size-20" />
                  <Number :value="`x${starsByColor[2] ?? 0}`" color="pink" />
                </div>
              </div>
              <div class="grid grid-cols-3 justify-items-stretch items-center">
                <div class="col-span-3 grid grid-cols-2 gap-4 justify-items-center items-center">
                  <div class="text-center">
                    <img src="/gfx/leagues/5.png" />
                    <Number :value="leagueCount[5] || '.'" />
                  </div>
                  <div class="text-center">
                    <img src="/gfx/leagues/4.png" />
                    <Number :value="leagueCount[4] || '.'" />
                  </div>
                </div>
                <div class="text-center">
                  <img src="/gfx/leagues/3.png" />
                  <Number :value="leagueCount[3] || '.'" />
                </div>
                <div class="text-center">
                  <img src="/gfx/leagues/2.png" />
                  <Number :value="leagueCount[2] || '.'" />
                </div>
                <div class="text-center">
                  <img src="/gfx/leagues/1.png" />
                  <Number :value="beginnerLeagueCount || '.'" />
                </div>
              </div>

              <div class="md:col-span-2 flex">
                <div class="mx-auto relative">
                  <img src="/gfx/maxiuser_bar_bg_disabled.gif" alt="Barre de progression du profil" class="w-[355px] h-[18px]" />
                  <div class="absolute top-0.5 h-[18px] overflow-hidden" :style="{ width: barWidth + 'px' }">
                    <div class="w-[355px] h-[18px] contrast-200 bg-gradient-to-r from-[#A500CD] to-[#84FF7A] via-[#F6941E] mask-[url('/gfx/maxiuser_bar_mask.png')]"></div>
                  </div>
                  <div class="absolute right-1.5 top-1.5 text-white text-2xs">{{ Math.floor(myStars / profile.max_stars * 100) }}</div>
                </div>
              </div>
            </div>

            <h2>Classements</h2>

            <table>
              <thead>
                <tr class="text-kado-orange uppercase text-sm *:px-2 *:text-right">
                  <th>Niveau</th>
                  <th>Position</th>
                  <th>Jeu</th>
                  <th>Score</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="run in profile.best_period_runs.sort((a, b) => a.game.name.localeCompare(b.game.name))" :key="run.id">
                  <td>
                    <img v-if="run.league_id" :src="`/gfx/leagues/${run.league_id}.png`" />
                  </td>
                  <td class="text-right">
                    <Number color="orange" :value="run.league_rank" />
                  </td>
                  <td class="text-left">
                    <div class="flex items-center gap-2">
                      <component :is="getStarImage(run)" class="size-4" />
                      <RouterLink :to="{ name: 'games.show', params: { id: run.game.id } }">
                        {{ run.game.name }}
                      </RouterLink>
                    </div>
                  </td>
                  <td class="text-right">
                    <Number color="blue" :value="run.score" />
                  </td>
                </tr>
              </tbody>
            </table>

            <h2>Historique</h2>

            <GamesGameScoreTable :show-pos="false"
                                 :show-player="false"
                                 show-game
                                 :scores="historyResults" />
            <div v-if="historyHasNextPage" class="mt-4 text-center">
              <button
                @click="fetchGameHistory()"
                :disabled="isHistoryLoading"
                class="text-orange-400 underline cursor-pointer hover:text-orange-500"
              >
                Charger plus de résultats
              </button>
              <Loader v-if="isHistoryLoading" />
              <MessageError v-else-if="historyError">{{ historyError }}</MessageError>
            </div>
          </div>
          <div v-else-if="item.value === 'last'">
            <ProfileLastPeriod :profile="profile" />
          </div>
          <div v-else-if="item.value === 'stats'">Stats</div>
        </div>
      </div>
    </template>
  </NavTabs>
</template>
