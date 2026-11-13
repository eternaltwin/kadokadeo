<script setup>
import KadoPoints from '@svg/k.svg'

import { t } from '@/i18n'

// the side panel of the daily game: its rules, its ranking of the day and the one of the period (tabs, all of them when
// zoomed, as GameSide.vue)
defineProps({
  game: { type: Object, required: true },
  isZoomed: { type: Boolean, default: false },
})
const dailyGameStore = useDailyGameStore()
const kadoPerPoint = window.Kado.daily_kado_per_point

const tabs = [
  { id: 'rules', label: t('games.rules'), icon: '/gfx/iconGameRules.png' },
  { id: 'day', label: t('games.day'), icon: '/gfx/iconGameRanking.png' },
  { id: 'period', label: t('games.period'), icon: '/gfx/iconGameStars.png' },
]
const selectedTab = ref('day')
</script>

<template>
  <div :class="{ 'grid @md:grid-cols-2': isZoomed }">
    <GamesGameSideTabs v-if="!isZoomed" v-model="selectedTab" :tabs="tabs" />

    <div>
      <GamesGameSideHeading v-if="isZoomed" class="my-2 text-center">{{ $t('games.rules') }}</GamesGameSideHeading>

      <article class="m-2" :class="{ hidden: !isZoomed && selectedTab !== 'rules' }">
        <p class="my-2">{{ game.description ?? $t('games.no_description') }}</p>
        <hr class="mx-auto my-2 w-[200px] border-t border-kado-blue-700" />
        <GamesGameControls :game="game" />
      </article>
    </div>

    <div>
      <GamesGameSideHeading v-if="isZoomed" class="my-2 text-center">{{ $t('games.day_ranking') }}</GamesGameSideHeading>

      <article class="relative m-2" :class="{ hidden: !isZoomed && selectedTab !== 'day' }">
        <Loader v-if="dailyGameStore.isScoresLoading">{{ $t('games.loading_scores') }}</Loader>
        <GamesGameScoreTable v-if="dailyGameStore.scores.length" :scores="dailyGameStore.scores" />
        <p v-else class="my-2 text-center italic">{{ $t('games.no_score_yet') }}</p>
      </article>
    </div>

    <div>
      <GamesGameSideHeading v-if="isZoomed" class="my-2 text-center">{{ $t('games.period_ranking') }}</GamesGameSideHeading>

      <article class="relative m-2" :class="{ hidden: !isZoomed && selectedTab !== 'period' }">
        <Loader v-if="dailyGameStore.isStandingsLoading">{{ $t('games.loading_ranking') }}</Loader>
        <i18n-t keypath="games.point_value" tag="p" class="my-2 text-center">
          <template #kado><Number :value="kadoPerPoint" color="green" /></template>
          <template #icon><KadoPoints class="inline size-4.25" /></template>
        </i18n-t>
        <GamesDailyStandingsTable v-if="dailyGameStore.standings.length" :standings="dailyGameStore.standings" />
        <p v-else class="my-2 text-center italic">{{ $t('games.no_point_yet') }}</p>
      </article>
    </div>
  </div>
</template>
