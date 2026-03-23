<script setup>
import { computed, onMounted, onUnmounted, ref } from 'vue'

import GameControls from '@/components/games/GameControls.vue'
import GameScoreTable from '@/components/games/GameScoreTable.vue'
import Loader from '@/components/Loader.vue'
import Number from '@/components/Number.vue'
import { useApi } from '@/composables/useApi'
import { usePeriodStore } from '@/stores/period'

const props = defineProps({
  game: { type: Object, required: true },
})
const { isLoading, get } = useApi()
const periodStore = usePeriodStore()
let intervalId = null

const scores = ref([])
const personalBestForPeriod = ref(null)
const personalBest = ref(null)
const worldsBest = ref(null)
const currentScore = ref(0)
const palliers = ref([
  { score: props.game.stars[0], points: 0, img: '/gfx/iconGreenStar.gif', alt: 'Etoile verte' },
  { score: props.game.stars[1], points: 0, img: '/gfx/iconOrangeStar.gif', alt: 'Etoile orange' },
  { score: props.game.stars[2], points: 0, img: '/gfx/iconRedStar.gif', alt: 'Etoile rouge' },
])
const nextPallierIndex = computed(() => {
  return palliers.value.findIndex((p) => Math.max(personalBest.value, currentScore.value) < p.score)
})

const refreshScores = () => {
  return get(`/games/${props.game.id}/scores`).then((data) => {
    scores.value = data.data.scores
    worldsBest.value = data.data.worldsBest
    personalBest.value = data.data.personalBest
    personalBestForPeriod.value = data.data.personalBestForPeriod
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
  <div class="gameSide relative">
    <nav class="gameNav">
      <ul>
        <li :class="selectedTab === 'gameRules' ? 'showed' : ''" @click="selectedTab = 'gameRules'">
          <a href="#" title="Présentation" @click.prevent="">
            <img src="/gfx/iconGameRules.png" alt="iconGameRules.png" />
            Règles
          </a>
        </li>
        <li :class="selectedTab === 'gameStars' ? 'showed' : ''" @click="selectedTab = 'gameStars'">
          <a href="#" title="Mon score / Mes paliers" @click.prevent="">
            <img src="/gfx/iconGameStars.png" alt="iconGameStars.png" />
            Paliers
          </a>
        </li>
        <li :class="selectedTab === 'gameRanking' ? 'showed' : ''" @click="selectedTab = 'gameRanking'">
          <a href="#" title="Classement général" @click.prevent="">
            <img src="/gfx/iconGameRanking.png" alt="iconGameRanking.png" />
            Classement
          </a>
        </li>
      </ul>
    </nav>

    <article id="gameRules" :class="selectedTab === 'gameRules' ? '' : 'hidden'">
      <p>{{ game.description ?? '[WIP description]' }}</p>
      <hr />
      <GameControls :game="game" />
    </article>

    <article id="gameStars" :class="selectedTab === 'gameStars' ? '' : 'hidden'">
      <table class="noBorder whiteFirst">
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

      <h3>Objectifs</h3>
      <table class="gameGoals noBorder">
        <thead>
          <tr class="noBackground">
            <th scope="col" style="width:30px;"></th>
            <th scope="col" class="textLeft">Paliers</th>
            <th scope="col" class="textRight">Valeur</th>
          </tr>
        </thead>
        <tbody class="twoColoured">
          <tr v-for="(pallier, index) in palliers" :key="index">
            <td scope="row">
              <img v-if="nextPallierIndex === index" src="/gfx/iconOrangeArrow.gif" alt="Prochain palier" />
            </td>
            <td class="textLeft">
              <img :src="pallier.img" :alt="pallier.alt" /> <Number :value="pallier.score" color="orange" />
            </td>
            <td class="textRight">
              <Number :value="pallier.points" color="green" /> <img src="/gfx/iconKadoPoints.gif" alt="Points Kado" />
            </td>
          </tr>
        </tbody>
      </table>
    </article>

    <article id="gameRanking" :class="selectedTab === 'gameRanking' ? '' : 'hidden'">
      <Loader v-if="isLoading">Chargement des scores...</Loader>
      <GameScoreTable v-else :scores="scores" style="margin:0 auto" />
      <p class="center bold">
        <RouterLink :to="{ name: 'games.ranking', params: { id: game.id }, query: { period: periodStore.period?.id } }">
          Classement de ce jeu
        </RouterLink>
      </p>
    </article>
  </div>
</template>
