<script setup>
import { ref } from 'vue'
import { computed } from 'vue'
import { useRoute } from 'vue-router'

import GameScript from '@/components/games/GameScript.vue'
import GameSide from '@/components/games/GameSide.vue'
import Loader from '@/components/Loader.vue'
import Error from '@/components/message/Error.vue'
import { useGames } from '@/composables/useGames'
import { useAuthStore } from '@/stores/auth'

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
const isZoomed = ref(false)
const gameWidth = computed(() => (isZoomed.value ? 600 : 300))
const gameHeight = computed(() => (isZoomed.value ? 640 : 320))
</script>

<template>
  <div class="withRightAside relative min-h-48">
    <Loader v-if="isLoading">Chargement ...</Loader>
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
          <GameScript :game="game"
                      :game-width="gameWidth"
                      :game-height="gameHeight"
          />

          <nav id="gameUpperButtons">
            <ul>
              <li>
                <a href="#" title="Zoom / dézoom" @click.prevent="isZoomed = !isZoomed">
                  <img src="/gfx/iconGameZoom.gif"
                       alt="iconGameZoom.gif"
                       width="15"
                       height="15" />
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

          <GameSide :game="game" />
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
</style>
