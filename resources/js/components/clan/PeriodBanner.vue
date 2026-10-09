<script setup>
// the tournament of the clans lasts the period: the scores start again from 0 on its first day
defineProps({
  tournament: { type: Object, default: null },
})
</script>

<template>
  <div v-if="tournament" class="flex items-center gap-2 border-l-4 border-kado-cyan-800 bg-kado-cyan-100 px-2 py-1 text-sm">
    <img src="/gfx/clan/cup.gif" alt="" class="size-6" />
    <div>
      <strong>Tournoi des clans - Période {{ tournament.period_id }}</strong> :
      les scores des clans seront remis à zéro dans <ClanCountdown :until="tournament.ends_at" class="font-bold" />.
    </div>
  </div>
</template>
