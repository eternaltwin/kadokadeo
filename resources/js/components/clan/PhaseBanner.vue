<script setup>
// where the tournament of the clans is: missions, then attacks and defenses
const props = defineProps({
  phase: { type: Object, default: null },
})

const date = (iso) => new Date(iso).toLocaleString('fr-FR', { weekday: 'long', day: 'numeric', month: 'long', hour: '2-digit', minute: '2-digit' })
const isWar = computed(() => props.phase?.phase === 'war')
</script>

<template>
  <div v-if="phase" class="flex items-center gap-2 border-l-4 px-2 py-1 text-sm" :class="isWar ? 'border-[#ff6b9c] bg-[#ffe3ec] text-[#ff6b9c]' : 'border-kado-cyan-800 bg-kado-cyan-100'">
    <img :src="isWar ? '/assets/img/gfx/icons/atk.gif' : '/gfx/clan/cup.gif'" alt="" class="size-6" />
    <div>
      <strong>{{ phase.label }}</strong> —
      <template v-if="isWar">
        les clans peuvent s'attaquer jusqu'au {{ date(phase.attacks_locked_at) }}. Fin du tournoi le {{ date(phase.ends_at) }}.
      </template>
      <template v-else>
        les clans remplissent leurs missions et les joueurs peuvent changer de clan. Début des attaques le {{ date(phase.war_starts_at) }}.
      </template>
    </div>
  </div>
</template>
