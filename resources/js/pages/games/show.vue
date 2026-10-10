<script setup>
const { isLoading, error, fetchGame } = useGames()
const { isLoading: isFavoriteLoading, error: favoriteError, put } = useApi()
const authStore = useAuthStore()
const route = useRoute()

const gameId = route.params.id

const game = ref(null)
const scores = ref([])
const personalBest = ref(null)
const personalBestForPeriod = ref(null)

function toggleFavorite() {
  if (!game.value || isFavoriteLoading.value) return

  put(`/games/${game.value.id}/favorite`, { is_favorite: !game.value.is_favorite })
    .then((response) => {
      game.value.is_favorite = response.data.is_favorite
    })
    .catch(() => null)
}

fetchGame(gameId).then((data) => {
  game.value = data.data
  scores.value = data.leaderboard
  personalBest.value = data.personalBest
  personalBestForPeriod.value = data.personalBestForPeriod
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
      <MessageError v-if="favoriteError">{{ favoriteError }}</MessageError>

      <GamesGamePlayer :game="game" />
    </template>
  </div>
</template>
