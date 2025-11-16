<script setup>
import { useGames } from '@/composables/useGames'
import { useAuthStore } from '@/stores/auth'
import { ref } from 'vue'
import { useRoute } from 'vue-router'
import { formatScore, formatTime } from '@/composables/helpers'
import Number from '@/components/Number.vue'
import { computed } from 'vue'
import GameScript from '@/components/games/GameScript.vue'
import Error from '@/components/message/Error.vue'

const { isLoading, error, fetchGame } = useGames()
const authStore = useAuthStore()
const route = useRoute()

const gameId = route.params.id

const game = ref(null)
const scores = ref([])
const personalBest = ref(null)
const personalBestForPeriod = ref(null)

fetchGame(gameId).then((data) => {
  game.value = data.data
  scores.value = data.leaderboard
  personalBest.value = data.personalBest
  personalBestForPeriod.value = data.personalBestForPeriod
})
const selectedTab = ref('gameRules')
const isZoomed = ref(false)
const gameWidth = computed(() => (isZoomed.value ? 600 : 300))
const gameHeight = computed(() => (isZoomed.value ? 640 : 320))
</script>

<template>
  <div class="withRightAside">
    <template v-if="isLoading">Chargement ...</template>
    <template v-else-if="!game">
      <Error> Jeu introuvable. ({{ error }}) </Error>
    </template>
    <template v-else>
      <h1 class="center">{{ game.name }}</h1>
      <p v-if="authStore.user?.kado_games >= 0">
        Il vous reste {{ authStore.user.kado_games }} parties à jouer aujourd'hui
      </p>
      <div :id="isZoomed ? 'gameZoomIn' : 'gameZoomOut'">
        <div id="gameInterface">
          <GameScript :game="game" :game-width="gameWidth" :game-height="gameHeight" />

          <nav id="gameUpperButtons">
            <ul>
              <li>
                <a href="#" title="Zoom / dézoom" @click.prevent="isZoomed = !isZoomed">
                  <img src="/gfx/iconGameZoom.gif" alt="iconGameZoom.gif" width="15" height="15" />
                  Zoom
                </a>
              </li>
              <li>
                <a href="#" title="Ajouter/retirer des jeux favoris">
                  <img src="/gfx/iconGameDisliked.gif" alt="iconGameDisliked.gif" />
                  Favori
                </a>
              </li>
            </ul>
          </nav>

          <div class="gameSide">
            <nav class="gameNav">
              <ul>
                <li
                  :class="selectedTab === 'gameRules' ? 'showed' : ''"
                  id="gameNavRules"
                  @click="selectedTab = 'gameRules'"
                >
                  <a href="#" title="Présentation">
                    <img src="/gfx/iconGameRules.png" alt="iconGameRules.png" />
                    Règles
                  </a>
                </li>
                <li
                  :class="selectedTab === 'gameStars' ? 'showed' : ''"
                  id="gameNavStars"
                  @click="selectedTab = 'gameStars'"
                >
                  <a href="#" title="Mon score / Mes paliers">
                    <img src="/gfx/iconGameStars.png" alt="iconGameStars.png" />
                    Paliers
                  </a>
                </li>
                <li
                  :class="selectedTab === 'gameRanking' ? 'showed' : ''"
                  id="gameNavRanking"
                  @click="selectedTab = 'gameRanking'"
                >
                  <a href="#" title="Classement général">
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
                    <td>123456</td>
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
        </div>
        <p id="gameZoomClose">
          <a href="#" title="Désactiver le zoom" @click.prevent="isZoomed = false">
            Désactiver le zoom <span>❌</span>
          </a>
        </p>
      </div>
    </template>
  </div>
</template>

<style scoped>
:deep(canvas#gameCanvas) {
  position: absolute;
  top: 22px;
  left: 22px;
  display: block;
  margin: 0;
  padding: 0;
  border: 1px solid #56b7c1;
  outline: none;
  box-sizing: content-box;
}
</style>
