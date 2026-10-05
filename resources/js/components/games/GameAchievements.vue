<script setup>
defineProps({
  game: { type: Object, required: true },
})

const achievementStore = useAchievementStore()
</script>

<template>
  <div class="flex flex-col gap-2">
    <AchievementsSmallBanner v-for="achievement in achievementStore.achievementsByGame[game.id] ?? []" :key="achievement.id" :achievement="achievement" />
  </div>
</template>
