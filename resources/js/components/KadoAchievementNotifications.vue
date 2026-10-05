<script setup>
const achievementStore = useAchievementStore()
</script>

<template>
  <div
    class="pointer-events-none fixed inset-x-4 bottom-4 z-50 sm:bottom-6 sm:left-auto sm:right-6 sm:w-[36rem]"
    aria-live="polite"
  >
    <TransitionGroup name="kado-achievement-list" tag="div" class="flex w-full flex-col gap-3">
      <div
        v-for="achievement in achievementStore.completedAchievements"
        :key="achievement.id"
        class="relative"
      >
        <Transition
          name="kado-achievement"
          appear
          @after-leave="achievementStore.removeCompletedAchievement(achievement.id)"
        >
          <div v-if="achievement.visible" class="pointer-events-auto">
            <KadoAchievementBanner
              :title="achievement.title"
              :description="achievement.description"
              :complete="achievement.complete"
              :level="achievement.level"
              :max-level="achievement.maxLevel"
              :current="achievement.current"
              :goal="achievement.goal"
              :achievement-level-icon="achievement.achievementLevelIcon"
            />
          </div>
        </Transition>
      </div>
    </TransitionGroup>
  </div>
</template>

<style scoped>
.kado-achievement-list-move,
.kado-achievement-list-enter-active,
.kado-achievement-list-leave-active,
.kado-achievement-enter-active,
.kado-achievement-leave-active {
  transition:
    transform 800ms cubic-bezier(0.22, 1, 0.36, 1),
    opacity 240ms ease;
}

.kado-achievement-list-enter-from,
.kado-achievement-list-leave-to,
.kado-achievement-enter-from,
.kado-achievement-leave-to {
  transform: translateX(120%) scale(0.96);
  opacity: 0;
}

.kado-achievement-list-leave-active {
  left: 0;
  position: absolute;
  right: 0;
}
</style>
