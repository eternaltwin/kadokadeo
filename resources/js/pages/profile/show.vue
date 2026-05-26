<script setup>
/*
TO DO LIST :
- qualifOK à utiliser pour voir si qualifié sur le jeu ou pas (ici défini sur false)
- mettre le lien vers les replay (colonne temps)
- trier le tableau quand on clique sur le titre d'une colonne (exple : si je clique sur "Position", ça affiche d'abord les jeux où je suis premier ; si je reclique ceux où je suis dernier)
*/
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
const qualifOk = ref(false);

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
            
            <div class="w-full flex">
              <div class="w-32/100 border border-solid border-white mr-5">
                <h2 class="m-0">Clan</h2>
                <p class="italic text-center">Les clans ne sont pas encore disponibles.</p>
              </div>
              <div class="w-68/100 border border-solid border-white">
                <h2 class="m-0">
                  Statut 
                  <span v-if="feathersCount > 0">
                    <img v-for="i in feathersCount"
                      :key="i"
                      src="/gfx/iconFeather.gif"
                      alt="Plume de Piou" />
                  </span>
                </h2>
                <div class="flex flex-wrap items-center">
                  <div class="flex items-baseline ml-2 mr-2 text-nowrap">
                    <GreenStar class="size-11" />
                    <Number :value="`x${starsByColor[0] ?? 0}`" color="green" class="-ml-4" />
                  </div>
                  <div class="flex items-baseline ml-2 mr-2 text-nowrap">
                    <OrangeStar class="size-11" />
                    <Number :value="`x${starsByColor[1] ?? 0}`" color="orange" class="-ml-4" />
                  </div>
                  <div class="flex items-baseline ml-2 mr-2 text-nowrap">
                    <RedStar class="size-11" />
                    <Number :value="`x${starsByColor[2] ?? 0}`" color="pink" class="-ml-4" />
                  </div>
                  <p class="flex items-center mt-0 mb-0 ml-4 mr-2 text-nowrap w-8">
                    <img src="/gfx/leagues/5.png" />
                    <Number :value="leagueCount[5] || '.'" />
                  </p>
                  <p class="flex items-center mt-0 mb-0 ml-2 mr-2 text-nowrap w-8">
                    <img src="/gfx/leagues/4.png" />
                    <Number :value="leagueCount[4] || '.'" />
                  </p>
                  <p class="flex items-center mt-0 mb-0 ml-2 mr-2 text-nowrap w-8">
                    <img src="/gfx/leagues/3.png" />
                    <Number :value="leagueCount[3] || '.'" />
                  </p>
                  <p class="flex items-center mt-0 mb-0 ml-2 mr-2 text-nowrap w-8">
                    <img src="/gfx/leagues/2.png" />
                    <Number :value="leagueCount[2] || '.'" />
                  </p>
                  <p class="flex items-center mt-0 mb-0 ml-2 mr-2 text-nowrap w-8">
                    <img src="/gfx/leagues/1.png" />
                    <Number :value="beginnerLeagueCount || '.'" />
                  </p>
                </div>

                <div class="flex">
                  <!-- Lien à créer vers la page de complétion -->
                  <RouterLink :to="'#'" class="mx-auto relative">
                    <img src="/gfx/maxiuser_bar_bg_disabled.gif" alt="Barre de progression du profil" class="w-[355px] h-[18px]" />
                    <div class="absolute top-0.5 h-[18px] overflow-hidden" :style="{ width: barWidth + 'px' }">
                      <div class="w-[355px] h-[18px] contrast-200 bg-gradient-to-r from-[#A500CD] to-[#84FF7A] via-[#F6941E] mask-[url('/gfx/maxiuser_bar_mask.png')]"></div>
                    </div>
                    <div class="absolute right-1.5 top-1.25 text-white text-2xs">{{ Math.floor(myStars / profile.max_stars * 100) }}</div>
                  </Routerlink>
                </div>
              </div>
            </div>

            <h2 class="mt-5">Classements</h2>

            <table class="thinTitles tableOneBackground">
              <thead>
                <tr>
                  <th class="w-10/100">Qualif</th>
                  <th class="w-10/100">Niveau</th>
                  <th class="w-15/100">Position</th>
                  <th class="w-30/100">Jeu</th>
                  <th class="w-20/100">Score</th>
                  <th class="w-15/100">Temps</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="run in profile.best_period_runs.sort((a, b) => a.game.name.localeCompare(b.game.name))" :key="run.id">
                  <td>
                    <img v-show="qualifOk" src="/gfx/iconQualifOk.gif" alt="iconQualifOk.gif" title="Qualif OK !" />
                  </td>
                  <td>
                    <img v-if="run.league_id" :src="`/gfx/leagues/${run.league_id}.png`" :alt="`${run.league_id}.png`" />
                  </td>
                  <td>
                    <Number color="orange" :value="run.league_rank" />
                  </td>
                  <td class="text-left">
                    <div class="flex items-center gap-2">
                      <component :is="getStarImage(run)" class="size-5" />
                      <RouterLink :to="{ name: 'games.show', params: { id: run.game.id } }">
                        {{ run.game.name }}
                      </RouterLink>
                    </div>
                  </td>
                  <td>
                    <Number color="blue" :value="run.score" />
                  </td>
                </tr>
              </tbody>
            </table>

            <h2 class="mt-10">Historique</h2>

            <GamesGameScoreTable :show-pos="false"
                                 :show-player="false"
                                 show-game
                                 :scores="historyResults" />
            <div v-if="historyHasNextPage" class="mt-4 text-center">
              <p class="text-center">
                <input
                  type="button" 
                  value="Charger plus de résultats"
                  @click="fetchGameHistory()"
                  :disabled="isHistoryLoading"
                  class="h-6 w-auto pt-px ml-4" /> 
              </p>
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
