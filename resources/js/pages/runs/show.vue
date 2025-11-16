<script setup>
import { useRuns } from '@/composables/useRuns'
import { ref } from 'vue'
import { useRoute } from 'vue-router'
import GameScript from '../../components/games/GameScript.vue'

const route = useRoute()
const { isLoading, fetchRun } = useRuns()
const runId = route.params.id
const run = ref(null)

fetchRun(runId).then((data) => {
  console.log(data)
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
  </template>
</template>
