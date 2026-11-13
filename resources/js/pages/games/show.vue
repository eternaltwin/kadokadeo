<script setup>
import { t } from '@/i18n'

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
  document.title = `${data.data.name} - ${t('common.site_name')}`
  scores.value = data.leaderboard
  personalBest.value = data.personalBest
  personalBestForPeriod.value = data.personalBestForPeriod
})
</script>

<template>
  <div class="relative min-h-48">
    <Loader v-if="isLoading">{{ $t('games.loading') }}</Loader>
    <template v-else-if="!game">
      <MessageError> {{ $t('games.not_found', { error }) }} </MessageError>
    </template>
    <template v-else>
      <KadoPageTitle class="mt-6.25 mb-5">{{ game.name }}</KadoPageTitle>
      <p class="mx-2.5 my-4" v-if="authStore.user?.kado_games >= 0">
        {{ $t('games.remaining_runs', { count: authStore.user.kado_games }, authStore.user.kado_games) }}
      </p>

      <GamesGamePlayer :game="game" />
    </template>
  </div>
</template>
