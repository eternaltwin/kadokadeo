<script setup>
import { t } from '@/i18n'
// the page of a clan as on the old site: the tabs, the "Infos" and "Actions" menu on the left, the name of the clan
const props = defineProps({
  clan: { type: Object, required: true },
  tab: { type: String, required: true },
})
const tabs = computed(() => {
  const id = props.clan.id
  return [
    { label: t('clan_layout.presentation'), value: 'show', route: { name: 'clans.show', params: { id } } },
    { label: t('clan_layout.status'), value: 'status', route: { name: 'clans.status', params: { id } } },
    // (the missions of another clan: without the reservations nor the options)
    { label: t('clan_layout.mission'), value: 'missions', route: { name: 'clans.missions', params: { id } } },
    // 4 tabs at most, as on the old site (the management is in the "Actions" menu)
    { label: t('clan_layout.members'), value: 'members', route: { name: 'clans.members', params: { id } } },
  ]
})
const selectedIndex = computed(() => Math.max(0, tabs.value.findIndex((t) => t.value === props.tab)))

const stats = computed(() => props.clan.stats)
const authStore = useAuthStore()
// the free attack and defense games of the player left today
const freeGames = computed(() => authStore.user?.clan_attack_games ?? 0)
const paidGames = computed(() => authStore.user?.clan_games ?? 0)
</script>

<template>
  <NavTabs :items="tabs" :selected-index="selectedIndex" />

  <div class="flex flex-col gap-2 px-2 md:flex-row">
    <!-- mobile: the whole width, "Infos" and "Actions" side by side; tablet and more: a column beside the content -->
    <div class="grid grid-cols-2 gap-x-2 py-2.5 md:block md:w-[161px] md:shrink-0">
      <div class="min-w-0">
        <ClanMenuTitle>{{ $t('clan_layout.infos') }}</ClanMenuTitle>
        <ul class="m-0 mb-2.5 ml-1 list-none border border-solid border-kado-slate-500 bg-[url(/gfx/clan/greyBg.jpg)] bg-[position:-650px_-8px] bg-no-repeat p-0">
          <div class="flex justify-around items-center gap-2 border-b border-solid border-white">
            <ClanMenuStat icon="/gfx/clan/clan_rank.svg" :title="$t('clan_layout.war_rank')">
              <Number :value="stats.war_rank ?? 0" color="green" />
            </ClanMenuStat>
            <ClanMenuStat icon="/assets/img/gfx/icons/clan_points.gif" :title="$t('clan_layout.war_score')">
              <Number :value="stats.war_score" color="orange" />
            </ClanMenuStat>
          </div>
          <div class="flex justify-around items-center gap-2 border-b border-solid border-white">
            <ClanMenuStat icon="/gfx/clan/clan_rank_missions.svg" :title="$t('clan_layout.mission_rank')">
              <Number :value="stats.mission_rank ?? 0" color="violet" />
            </ClanMenuStat>
            <ClanMenuStat icon="/gfx/clan/clan_mission_points.png" :title="$t('clan_layout.mission_score')">
              <Number :value="stats.mission_score" color="violet" />
            </ClanMenuStat>
          </div>
          <div v-if="clan.viewer.is_member" class="flex justify-around items-center gap-2 border-b border-solid border-white">
            <ClanMenuStat icon="/gfx/gemGreen.svg" :title="$t('clan_layout.free_games')">
              <Number :value="freeGames" color="green" />
            </ClanMenuStat>
            <ClanMenuStat icon="/gfx/gemOrange.svg" :title="$t('clan_layout.paid_games')">
              <Number :value="paidGames ?? 0" color="orange" />
            </ClanMenuStat>
          </div>
          <div v-if="clan.viewer.is_member" class="grayscale flex justify-around items-center gap-2 border-b border-solid border-white">
            <ClanMenuStat icon="/gfx/gemOrange.svg" :title="$t('clan_layout.chest_title')">
              {{ $t('clan_layout.chest') }} <Number :value="clan.clan_games ?? 0" color="orange" />
            </ClanMenuStat>
          </div>
        </ul>
      </div>
      <div class="min-w-0">
        <ClanMenuTitle>{{ $t('clan_layout.actions') }}</ClanMenuTitle>
        <ul class="m-0 mb-2.5 ml-1 list-none p-0">
          <slot name="actions" />
        </ul>
      </div>
    </div>

    <div class="min-w-0 flex-1">
      <h1 class="mb-4 flex items-center gap-2 font-junegull text-3xl text-kado-blue-500">
        <img src="/gfx/clan/h1_tristar.gif" alt="" class="shrink-0" />
        <ClanName :name="clan.name" />
      </h1>
      <slot />
    </div>
  </div>
</template>
