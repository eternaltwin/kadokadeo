<script setup>
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
  <div class="relative min-h-48">
    <Loader v-if="isLoading">Chargement ...</Loader>
    <template v-else-if="!game">
      <MessageError> Jeu introuvable. ({{ error }}) </MessageError>
    </template>
    <template v-else>
      <h1 class="center">{{ game.name }}</h1>
      <p v-if="authStore.user?.kado_games >= 0">
        Il vous reste {{ authStore.user.kado_games }} parties à jouer aujourd'hui
      </p>
      <div :class="isZoomed ? 'w-full h-full fixed z-20 inset-0 bg-black/75' : 'gameZoomOut'">
        <div :class="isZoomed ? 'absolute w-[1024px] h-[690px] m-auto left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 gameInterfaceZoom' : 'relative w-[724px] h-[370px] mt-[30px] mb-[50px] mx-auto gameInterface'">
          <nav class="absolute -top-5 right-4 text-xs">
            <ul class="flex justify-end gap-2">
              <li class="game-interface-button h-5 hover:h-[18px] hover:mt-[2px]">
                <div class="pt-1 font-bold text-center hover:text-kado-orange cursor-pointer" title="Zoom / dézoom" @click.prevent="isZoomed = !isZoomed">
                  <img src="/gfx/iconGameZoom.gif" alt="zoom" class="size-4" />
                  Zoom
                </div>
              </li>
              <li class="game-interface-button h-5 hover:h-[18px] hover:mt-[2px]">
                <div class="pt-1 font-bold text-center hover:text-kado-orange cursor-pointer" title="Ajouter/retirer des jeux favoris">
                  <img src="/gfx/iconGameDisliked.gif" alt="favori" class="size-4" />
                  Favori
                </div>
              </li>
            </ul>
          </nav>

          <GamesGameScript :game="game"
                      :game-width="gameWidth"
                      :game-height="gameHeight"
                      :style="{ left: '22px', top: '22px'}"
          />

          <GamesGameSide :is-zoomed="isZoomed" :game="game" />
        </div>
        <p v-if="isZoomed" class="fixed right-2 top-0">
          <div class="text-white p-1 cursor-pointer bg-black/75 border border-solid border-black hover:bg-black hover:border-white" @click.prevent="isZoomed = false">
            Désactiver le zoom <span>❌</span>
          </div>
        </p>
      </div>
    </template>
  </div>
</template>

<style scoped>
</style>
