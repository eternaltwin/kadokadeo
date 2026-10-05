<script setup>
const { isLoading, error, fetchGame } = useGames()
const authStore = useAuthStore()
const route = useRoute()

const gameId = route.params.id

const game = ref(null)
const scores = ref([])
const personalBest = ref(null)
const personalBestForPeriod = ref(null)
const isArkadeo = computed(() => game.value?.is_arkadeo ?? false)

fetchGame(gameId).then((data) => {
  game.value = data.data
  scores.value = data.leaderboard
  personalBest.value = data.personalBest
  personalBestForPeriod.value = data.personalBestForPeriod
})
const _zoomed = ref(localStorage.getItem('isZoomed') === 'true')
const isZoomed = computed({
  get() {
    return _zoomed.value
  },
  set(value) {
    _zoomed.value = value
    localStorage.setItem('isZoomed', value)
  },
})
const gameWidth = computed(() => isArkadeo.value ? 600 :  (isZoomed.value ? 600 : 300))
const gameHeight = computed(() => isArkadeo.value ? 460 :  (isZoomed.value ? 640 : 320))

const surfaceWidth = computed(() => gameWidth.value + 46)
const surfaceHeight = computed(() => gameHeight.value + 50)

const gameInterfaceStyle = computed(() => {
  return {
    '-webkit-user-select': 'none',
    '-webkit-touch-callout': 'none',
  }
})

watchEffect((onInvalidate) => {
  const cb = (e) => {
    if (e.keyCode === 27) {
      isZoomed.value = false
    }
  }
  window.addEventListener('keydown', cb)
  onInvalidate(() => window.removeEventListener('keydown', cb))
})
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


      <div :class="{'w-full h-full fixed z-20 inset-0 bg-black/75': isZoomed}">
        <div :class="isZoomed ? 'fixed w-screen h-dvh flex flex-col overflow-hidden' : 'relative w-full mt-[30px] mb-[50px] mx-auto'" :style="gameInterfaceStyle">
          <div v-if="isZoomed" class="w-full text-center tracking-widest">
            <div class="text-white p-1 cursor-pointer bg-black/75 border border-solid border-black hover:bg-black hover:border-white" @click.prevent="isZoomed = false">
              Désactiver le zoom <span>❌</span>
            </div>
          </div>

          <div :class="isZoomed ? 'flex-1 flex lg:items-center min-h-0' : 'max-h-full h-fit'" class="max-w-full w-fit m-auto overflow-y-auto pt-5">
            <div class="flex flex-col lg:flex-row" :class="{ 'w-full': isZoomed, 'lg:flex-col': game.is_arkadeo }">
              <div class="relative gameint1 mx-auto max-w-full! shrink-0" :class="[game.is_arkadeo ? 'aspect-arkadeo' : 'aspect-kadokado', {'order-2 mt-4 lg:order-1 lg:mt-0': isZoomed}]" :style="{ width: surfaceWidth + 'px' }">
                <nav class="absolute -top-10 right-0 text-xs">
                  <ul class="flex justify-end gap-2">
                    <li class="game-interface-button h-5 hover:h-[18px] hover:mt-0.5 grayscale">
                      <div class="pt-1 font-bold text-center hover:text-kado-orange cursor-pointer" title="Ajouter/retirer des jeux favoris">
                        <img src="/gfx/iconGameDisliked.gif" alt="favori" class="size-4" />
                        Favori
                      </div>
                    </li>
                    <li v-if="!isArkadeo" class="game-interface-button h-5 hover:h-[18px] hover:mt-0.5">
                      <div class="pt-1 font-bold text-center hover:text-kado-orange cursor-pointer"
                           title="Zoom / dézoom"
                           @click.prevent="isZoomed = !isZoomed">
                        <img src="/gfx/iconGameZoom.gif" alt="zoom" class="size-4" />
                        Zoom
                      </div>
                    </li>
                  </ul>
                </nav>
                <GamesGameScript :game="game" />
              </div>
              <div class="gameint2 hidden" :class="{ 'lg:block': !isZoomed, 'hidden': game.is_arkadeo }" :style="{ height: surfaceHeight + 'px' }"></div>
              <div class="gameint3 @container min-w-[345px]" :class="{ 'w-full lg:max-w-sm flex-1 order-1 lg:order-2': isZoomed, 'w-full': game.is_arkadeo }" :style="{ height: surfaceHeight + 'px' }">
                <GamesGameSide class="overflow-y-auto overflow-x-hidden text-xs h-full" :is-zoomed="isZoomed" :game="game" />
              </div>
            </div>

          </div>
        </div>
      </div>

    </template>
  </div>
</template>

<style scoped>
</style>
