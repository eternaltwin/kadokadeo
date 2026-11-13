<script setup>
import KadoPoints from '@svg/k.svg'

const dailyGameStore = useDailyGameStore()
const dailyGame = toRef(dailyGameStore, 'dailyGame')
const game = toRef(dailyGameStore, 'game')
</script>

<template>
  <Loader v-if="dailyGameStore.isDailyGameLoading" />
  <div v-else-if="game" class="mx-auto mb-10 w-full max-w-[700px] md:h-[142px]">
    <RouterLink
      class="relative z-[2] flex w-full flex-col overflow-hidden md:h-full md:flex-row decoration-0"
      :class="{ grayscale: dailyGameStore.position !== null }"
      :to="{ name: 'games.daily' }"
      :title="$t('games.daily_play')"
    >
      <div class="relative w-full aspect-[113/71] bg-[url('/gfx/gameBoxDayLeft.png')] bg-no-repeat bg-[length:100%_100%] md:w-[226px] md:h-[142px] md:aspect-auto md:shrink-0">
        <div class="absolute left-[15.93%] top-[5.63%] w-[77.88%] md:left-9 md:top-2 md:w-[176px]">
          <img class="w-full h-auto" :src="game.image_path" :alt="game.name" />
          <h3 class="w-full text-center text-xl font-normal leading-5 text-kado-pink-900">
            {{ game.name }}
          </h3>
        </div>
      </div>
      <div class="relative min-h-[142px] flex-1 daily-game-frame text-sm font-normal text-kado-pink-900">
        <div class="absolute -top-8 text-kado-pink-100 font-junegull text-shadow-sm text-shadow-kado-pink-300 text-lg w-full text-center">{{ $t('games.daily_heading') }}</div>
        {{ $t('games.daily_intro') }}
        <i18n-t keypath="games.daily_contract" tag="div" class="flex items-center gap-1">
          <template #score><Number :value="dailyGame.contract_score" color="blue" /></template>
          <template #points><Number :value="dailyGame.contract_points" color="green" /></template>
          <template #icon><KadoPoints class="inline size-4" /></template>
        </i18n-t>
        <div v-if="!dailyGameStore.isScoresLoading" class="flex items-center gap-1">
          {{ $t('games.daily_remaining') }}
          <Number :value="dailyGameStore.position === null ? 1 : 0" color="orange" />
          <img class="size-4" src="/gfx/gemOrange.svg" :alt="$t('games.gem_alt')" />
        </div>
        <div v-if="dailyGameStore.position !== null" class="flex items-center gap-1">
          {{ $t('games.daily_position') }}
          <Number :value="dailyGameStore.position" color="green" />
        </div>
      </div>
    </RouterLink>
  </div>
</template>

