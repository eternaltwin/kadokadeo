<script setup>
import Number from '@/components/Number.vue'
import { formatTime } from '@/composables/helpers'

defineProps({
  scores: { type: Array, required: true },
})
</script>

<template>
  <table class="w-full">
    <thead>
      <tr>
        <!-- <th>Période</th> -->
        <th>Position</th>
        <th>Joueur</th>
        <th>Score</th>
        <th>Temps</th>
      </tr>
    </thead>
    <tbody>
      <tr v-for="(score, index) in scores" :key="score.id">
        <!-- <td>{{ score.period_id }}</td> -->
        <td>{{ index + 1 }}</td>
        <td>{{ score.user.display_name }}</td>
        <td><Number :value="score.score" color="orange" /></td>
        <td>
          <RouterLink
            v-if="score.has_replay"
            :to="{ name: 'runs.show', params: { id: score.id } }"
          >
            {{ formatTime(score.play_time_seconds) }}
          </RouterLink>
          <span v-else>
            {{ formatTime(score.play_time_seconds) }}
          </span>
        </td>
      </tr>
    </tbody>
  </table>
</template>
