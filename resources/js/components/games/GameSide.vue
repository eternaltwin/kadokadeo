<script setup>
const props = defineProps({
  game: { type: Object, required: true },
  isZoomed: { type: Boolean, default: false },
})
const { isLoading, get } = useApi()
const authStore = useAuthStore()
const periodStore = usePeriodStore()
const leagueStore = useLeagueStore()
let intervalId = null

const scores = ref([])
const personalBestForPeriod = ref(null)
const personalBest = ref(null)
const worldsBest = ref(null)
const currentScore = ref(0)
const league = ref(null)
const leaguesScores = ref({})
const palliers = computed(() => {
  const s = []
  if (!personalBestForPeriod.value || personalBestForPeriod.value.score < props.game.stars[0]) {
    s.push({ score: props.game.stars[0], points: 0, img: '/gfx/iconGreenStar.gif', alt: 'Etoile verte' })
  }
  if (!personalBestForPeriod.value || personalBestForPeriod.value.score < props.game.stars[1]) {
    s.push({ score: props.game.stars[1], points: 0, img: '/gfx/iconOrangeStar.gif', alt: 'Etoile orange' })
  }
  if (!personalBestForPeriod.value || personalBestForPeriod.value.score < props.game.stars[2]) {
    s.push({ score: props.game.stars[2], points: 0, img: '/gfx/iconRedStar.gif', alt: 'Etoile rouge' })
  }
  if (personalBestForPeriod.value) {
    s.push({ score: personalBestForPeriod.value.score, points: null, img: '/gfx/iconBlueArrow.gif', alt: 'Record période' })
  }
  const bestScore = scores.value?.[0]
  if (bestScore && bestScore.user?.etwin_id !== authStore.user?.etwin_id && league.value?.level === leagueStore.paradiseLeagueId) {
    s.push({ score: bestScore.score + 1, points: null, img: '/gfx/iconFeather.gif', alt: 'Plume de Piou' })
  }
  const leagueScore = leaguesScores.value[league.value?.level]
  if (leagueScore && leagueScore.required_score > personalBestForPeriod.value?.score) {
    s.push({ score: leagueScore.required_score + 1, points: null, img: `/gfx/leagues/${league.value.level + 1}.png`, alt: 'Ligue supérieure' })
  }
  s.push({ score: 0, points: 0, img: '/gfx/iconContract.png', alt: 'Contrat' })
  s.sort((a, b) => b.score - a.score)
  return s
})
const nextPallierIndex = computed(() => {
  return palliers.value.findLastIndex((p) => currentScore.value < p.score)
})
const notZoomedHiddenState = computed(() => (props.isZoomed ? '' : 'hidden'))

const refreshScores = () => {
  return get(`/games/${props.game.id}/scores`).then((data) => {
    scores.value = data.data.scores
    worldsBest.value = data.data.worlds_best
    personalBest.value = data.data.personal_best
    personalBestForPeriod.value = data.data.personal_best_for_period
    league.value = data.data.league ?? null
    leaguesScores.value = data.data.leagues_scores ?? {}
  })
}

const updateCurrentScore = (evt) => {
  if (evt.detail?.score != null) {
    currentScore.value = evt.detail.score
  }
}

onMounted(() => {
  intervalId = setInterval(refreshScores, 1200000)
  window.evts.addEventListener('gameFinished', refreshScores)
  window.evts.addEventListener('score', updateCurrentScore)
})
onUnmounted(() => {
  clearInterval(intervalId)
  window.evts.removeEventListener('gameFinished', refreshScores)
  window.evts.removeEventListener('score', updateCurrentScore)
})

refreshScores()

const selectedTab = ref('gameRules')
</script>

<template>
  <div class="overflow-y-auto overflow-x-hidden text-xs absolute w-[303px] top-[23px] right-[23px]" :class="isZoomed ? 'h-[640px]' : 'h-[320px]'">
    <nav v-if="!isZoomed" class="gameNav">
      <ul>
        <li :class="{'showed': selectedTab === 'gameRules'}" @click="selectedTab = 'gameRules'">
          <a class="flex items-center justify-center gap-1"
             href="#"
             title="Présentation"
             @click.prevent="">
            <img src="/gfx/iconGameRules.png" alt="iconGameRules.png" />
            Règles
          </a>
        </li>
        <li :class="{'showed': selectedTab === 'gameStars'}" @click="selectedTab = 'gameStars'">
          <a class="flex items-center justify-center gap-1"
             href="#"
             title="Mon score / Mes paliers"
             @click.prevent="">
            <img src="/gfx/iconGameStars.png" alt="iconGameStars.png" />
            Paliers
            <img v-if="league" :src="`/gfx/leagues/${league.level}.png`" :alt="league.name" />
          </a>
        </li>
        <li :class="{'showed': selectedTab === 'gameRanking'}" @click="selectedTab = 'gameRanking'">
          <a class="flex items-center justify-center gap-1"
             href="#"
             title="Classement général"
             @click.prevent="">
            <img src="/gfx/iconGameRanking.png" alt="iconGameRanking.png" />
            Classement
          </a>
        </li>
      </ul>
    </nav>

    <h3 v-if="isZoomed" class="text-center">Règles</h3>

    <article id="gameRules" :class="selectedTab === 'gameRules' ? '' : notZoomedHiddenState">
      <p>{{ game.description ?? '[WIP description]' }}</p>
      <hr />
      <GamesGameControls :game="game" />
    </article>

    <h3 v-if="isZoomed" class="flex justify-center">Paliers <img  v-if="league" :src="`/gfx/leagues/${league.level}.png`" :alt="league.name" /></h3>

    <article id="gameStars" :class="selectedTab === 'gameStars' ? '' : notZoomedHiddenState">
      <table class="border-0 **:border-0 whiteFirst">
        <thead>
          <tr class="noBackground">
            <th scope="col">Record période</th>
            <th scope="col">Mon record</th>
            <th scope="col">Record du monde</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td scope="row">
              <Number :value="Math.max(personalBestForPeriod?.score ?? 0, currentScore)" color="orange" />
            </td>
            <td>
              <Number :value="Math.max(personalBest?.score ?? 0, currentScore)" color="orange" />
            </td>
            <td>
              <Number :value="Math.max(worldsBest?.score ?? 0, currentScore)" color="orange" />
            </td>
          </tr>
        </tbody>
      </table>

      <h3 class="text-right">Objectifs</h3>
      <table class="gameGoals border-0 **:border-0">
        <thead>
          <tr class="noBackground">
            <th scope="col" style="width:30px;"></th>
            <th scope="col" class="textLeft">Paliers</th>
            <th scope="col" class="textRight">Valeur</th>
          </tr>
        </thead>
        <tbody class="twoColoured">
          <tr v-for="(pallier, index) in palliers" :key="index" :class="{'opacity-35': nextPallierIndex < index}">
            <td scope="row">
              <img v-if="nextPallierIndex === index" src="/gfx/iconOrangeArrow.gif" alt="Prochain palier" />
            </td>
            <td class="textLeft">
              <img :src="pallier.img" :alt="pallier.alt" /> <Number :value="pallier.score" color="orange" />
            </td>
            <td class="textRight">
              <template v-if="pallier.points !== null">
                <Number :value="pallier.points" color="green" />
                <img src="/gfx/iconKadoPoints.gif" alt="Points Kado" />
              </template>
            </td>
          </tr>
        </tbody>
      </table>
    </article>

    <h3 v-if="isZoomed" class="text-center">Classement</h3>

    <article id="gameRanking" :class="selectedTab === 'gameRanking' ? '' : notZoomedHiddenState">
      <Loader v-if="isLoading">Chargement des scores...</Loader>
      <GamesGameScoreTable v-else :scores="scores" style="margin:0 auto" />
      <p class="center bold">
        <RouterLink :to="{ name: 'games.ranking', params: { id: game.id }, query: { period: periodStore.period?.id, league: league?.id } }">
          Classement de ce jeu
        </RouterLink>
      </p>
    </article>
  </div>
</template>

<style scoped>
article {
  width: 287px;
  margin: 8px;
}

hr {
  width: 200px;
  margin: 8px auto;
  border: 0;
  border-top: 1px solid var(--color-kado-blue);
}

p {
  margin: 8px 0;
}

h3 {
  width: 100%;
  margin: 8px 0 8px 0;
  font-weight: bold;
  font-size: 1.3em;
  color: var(--color-kado-blue);
  border-bottom: 3px double var(--color-kado-blue);
  letter-spacing: 1px;
}
</style>
