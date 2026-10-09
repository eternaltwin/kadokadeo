<script setup>
import KadoPoints from '@svg/k.svg'

defineProps({
  clan: { type: Object, required: true },
  tournament: { type: Object, default: null },
})
</script>

<template>
  <div class="space-y-4">

    <div id="clanPresentation" class="whitespace-pre-line break-words">
      <template v-if="clan.description">{{ clan.description }}</template>
      <p v-else class="italic text-kado-cyan-900">Bienvenue sur la page du clan {{ clan.name }}.</p>
    </div>

    <ul class="list-inside list-image-[url(/gfx/puce.jpg)] ml-4 space-y-1">
      <li v-if="clan.leader">
        Chef de clan :
        <img src="/gfx/clan/clanleader.gif" alt="Chef de Clan" title="Chef de Clan" />
        <RouterLink :to="{ name: 'profile.show', params: { id: clan.leader.etwin_id } }">{{ clan.leader.display_name }}</RouterLink>
      </li>
      <li>Ce clan comporte {{ clan.members_count }} joueur(s) sur {{ clan.max_members }}.</li>
      <li>{{ clan.is_recruiting ? 'Ce clan recrute de nouveaux membres.' : 'Ce clan ne recrute pas pour le moment.' }}</li>
    </ul>

    <template v-if="clan.history.length">
      <h2>Historique</h2>
      <ul class="list-inside list-image-[url(/gfx/puce.jpg)] ml-4 space-y-1">
        <li v-for="h in clan.history" :key="h.period_id">
          Période {{ h.period_id }} :
          <template v-if="h.war_rank">TOP {{ h.war_rank }} au classement des attaques ({{ h.war_score }})</template>
          <template v-if="h.war_rank && h.mission_rank">, </template>
          <template v-if="h.mission_rank">TOP {{ h.mission_rank }} au classement des missions ({{ h.mission_score }})</template>
          <template v-if="!h.war_rank && !h.mission_rank">non classé</template>
          <template v-if="h.reward > 0">
            — <Number :value="h.reward" color="green" /> <KadoPoints class="inline size-[17px]" />
          </template>
        </li>
      </ul>
    </template>
  </div>
</template>
