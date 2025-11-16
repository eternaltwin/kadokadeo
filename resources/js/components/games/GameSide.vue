<script setup>
import { onMounted, onUnmounted, ref } from 'vue'

import Loader from '@/components/Loader.vue'
import Number from '@/components/Number.vue'
import { formatScore, formatTime } from '@/composables/helpers'
import { useApi } from '@/composables/useApi'

const props = defineProps({
  game: { type: Object, required: true },
})
const { isLoading, get } = useApi()
let intervalId = null

const scores = ref([])
const personalBestForPeriod = ref(null)
const personalBest = ref(null)

const refreshScores = () => {
  return get(`/games/${props.game.id}/scores`).then((data) => {
    scores.value = data.data.scores
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
      <table class="gameCommands noBorder noBackground">
        <thead>
          <tr>
            <th style="width: 70px" scope="col">Commande</th>
            <th scope="col">Fonction</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td scope="row">
              <img
                src="/gfx/gameCommandLeftClic.png"
                title="Clic gauche"
                alt="Clic gauche"
              />
            </td>
            <td>Sauter</td>
          </tr>
        </tbody>
      </table>
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
            <td>123456</td>
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
            <td scope="row">Img</td>
            <td>123456</td>
          </tr>
          <tr>
            <td scope="row">Img</td>
            <td>123456</td>
          </tr>
          <tr>
            <td scope="row">Img</td>
            <td>123456</td>
          </tr>
        </tbody>
      </table>
    </article>

    <article id="gameRanking" :class="selectedTab === 'gameRanking' ? '' : 'hidden'">
      <Loader v-if="isLoading">Chargement des scores...</Loader>
      <table class="w-full">
        <tr>
          <th>Position</th>
          <th>Joueur</th>
          <th>Score</th>
          <th>Temps</th>
        </tr>
        <tr v-for="(score, index) in scores" :key="score.id">
          <td>{{ index + 1 }}</td>
          <td>{{ score.user.display_name }}</td>
          <td>{{ formatScore(score.score) }}</td>
          <td>
            <RouterLink
              v-if="score.has_replay"
              :to="{ name: 'runs.show', params: { id: score.id } }"
            >
              {{ formatTime(score.play_time_seconds) }}
            </RouterLink>
            <span v-else>
              {{ formatTime(score.play_time_seconds) }}
            </span>
          </td>
        </tr>
      </table>
    </article>
  </div>
</template>
