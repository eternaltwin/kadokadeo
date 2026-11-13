<script setup>
// the tournament of the clans lasts the period: the scores start again from 0 on its first day
defineProps({
  tournament: { type: Object, default: null },
})
</script>

<template>
  <div v-if="tournament" class="border-l-4 border-kado-teal-500 bg-kado-blue-50 px-2 py-1 text-sm">
    <i18n-t keypath="clan_period_banner.reset" tag="span">
      <template #title><strong>{{ $t('clan_period_banner.title', { period: tournament.period_id }) }}</strong></template>
      <template #countdown><ClanCountdown :until="tournament.ends_at" class="font-bold" /></template>
    </i18n-t>
  </div>
</template>
