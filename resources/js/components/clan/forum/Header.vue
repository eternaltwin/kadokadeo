<script setup>
import { t } from '@/i18n'
// the top of the pages of the forum of a clan: the tabs (the forum, back to the clan) and the title, a link to the
// list of the topics from a topic
const props = defineProps({
  clanId: { type: [Number, String], required: true },
  linked: { type: Boolean, default: false },
})

const forumRoute = computed(() => ({ name: 'clans.forum', params: { id: props.clanId } }))
const tabs = computed(() => [
  { label: t('clan_forum.forum'), value: 'forum', route: forumRoute.value },
  { label: t('clan_forum.clan'), value: 'clan', route: { name: 'clans.show', params: { id: props.clanId } } },
])
</script>

<template>
  <NavTabs :items="tabs" :selected-index="0" />
  <KadoSectionTitle class="mb-3">
    <RouterLink v-if="linked" :to="forumRoute">{{ $t('clan_forum.title') }}</RouterLink>
    <template v-else>{{ $t('clan_forum.title') }}</template>
  </KadoSectionTitle>
</template>
