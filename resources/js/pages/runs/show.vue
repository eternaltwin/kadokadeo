<script setup>
import { ref } from 'vue'
import { useRoute } from 'vue-router'

import { useRuns } from '@/composables/useRuns'

import GameScript from '../../components/games/GameScript.vue'

const route = useRoute()
const { isLoading, fetchRun } = useRuns()
const runId = route.params.id
const run = ref(null)

fetchRun(runId).then((data) => {
  run.value = data.data
})
</script>

<template>
  <template v-if="isLoading || !run">Chargement...</template>
  <template v-else>
    <h1 class="text-center">Replay</h1>
    <h2 class="m-0!">Vous regardez {{ run.user?.display_name }}</h2>
    <h2 class="m-0!">Score: {{ run.score }}</h2>
    <h2 class="m-0!">Jeu: {{ run.game.name }}</h2>
    <div class="relative" :style="{ width: '600px', height: '640px' }">
      <GameScript
        :game="run.game"
        :args="[
          `--replay=${run.replay}`,
          `--seed=${run.seed}`,
          `--contract_score=${run.contract_score}`,
          `--contract_points=${run.contract_points}`,
        ]"
        :game-width="600"
        :game-height="640"
      />
    </div>
  </template>
</template>
