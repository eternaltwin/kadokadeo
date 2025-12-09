<script setup>
import Number from '@/components/Number.vue'
import { formatTime } from '@/composables/helpers'

defineProps({
  scores: { type: Array, required: true },
})
</script>

<template>
  <table class="fullWidth">
    <thead>
      <tr>
        <!-- <th scope="col">Période</th> -->
        <th scope="col">Pos</th>
        <th scope="col">Joueur</th>
        <th scope="col">Score</th>
        <th scope="col">Temps</th>
      </tr>
    </thead>
    <tbody class="smallPadding">
      <tr v-for="(score, index) in scores" :key="score.id">
        <!-- <td>{{ score.period_id }}</td> -->
        <td><Number :value="index + 1" color="orange" /></td>
        <td>{{ score.user.display_name }}</td>
        <td><Number :value="score.score" color="blue" /></td>
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
