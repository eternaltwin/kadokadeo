<script setup>
import { onMounted, onUnmounted, ref } from 'vue'

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

const refreshScores = () => {
  return get(`/games/${props.game.id}/scores`).then((data) => {
    scores.value = data.data.scores
    worldsBest.value = data.data.worldsBest
    personalBest.value = data.data.personalBest
    personalBestForPeriod.value = data.data.personalBestForPeriod
  })
}

onMounted(() => intervalId = setInterval(refreshScores, 30000))
onUnmounted(() => clearInterval(intervalId))

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
              <Number :value="personalBestForPeriod?.score ?? 0" color="orange" />
            </td>
            <td>
              <Number :value="personalBest?.score ?? 0" color="orange" />
            </td>
            <td>
              <Number :value="worldsBest?.score ?? 0" color="orange" />
            </td>
          </tr>
        </tbody>
      </table>

      <h3>Objectifs</h3>
      <table class="gameGoals noBorder">
        <thead>
          <tr class="noBackground">
            <th scope="col">Paliers</th>
            <th scope="col">Valeur</th>
          </tr>
        </thead>
        <tbody class="twoColoured">
          <tr>
            <td scope="row">
              <img src="/assets/img/gfx/greenStar.gif" alt="Etoile verte" />
            </td>
            <td>
              <Number :value="game.stars[0]" color="orange" />
            </td>
          </tr>
          <tr>
            <td scope="row">
              <img src="/assets/img/gfx/orangeStar.gif" alt="Etoile orange" />
            </td>
            <td>
              <Number :value="game.stars[1]" color="orange" />
            </td>
          </tr>
          <tr>
            <td scope="row">
              <img src="/assets/img/gfx/redStar.gif" alt="Etoile rouge" />
            </td>
            <td>
              <Number :value="game.stars[2]" color="orange" />
            </td>
          </tr>
        </tbody>
      </table>
    </article>

    <article id="gameRanking" :class="selectedTab === 'gameRanking' ? '' : 'hidden'">
      <Loader v-if="isLoading">Chargement des scores...</Loader>
      <GameScoreTable v-else :scores="scores" />
      <RouterLink :to="{ name: 'games.ranking', params: { id: game.id }, query: { period: periodStore.period?.id } }" class="block mt-4 text-center underline">
        Voir le classement complet
      </RouterLink>
    </article>
  </div>
</template>
