<script setup>
import KadoPoints from '@svg/k.svg'

import { t } from '@/i18n'

// "Classement" of the clans of the period, and the creation of a clan
const route = useRoute()
const router = useRouter()
const clanStore = useClanStore()
const authStore = useAuthStore()
// (its own error)
const { createClan, isLoading: isCreating, error: createError } = useClans()

const tab = computed(() => ['war', 'missions', 'create'].includes(route.query.tab) ? route.query.tab : 'war')
const search = ref(route.query.q ?? '')
// (none on the tab of the creation)
const { items: clans, tournament, hasNextPage, loadMore, isLoading, error } = useClanRanking(
  () => (tab.value === 'create' ? null : { ranking: tab.value, q: route.query.q || undefined }),
)
clanStore.reload()

const doSearch = () => router.push({ query: { ...route.query, q: search.value || undefined } })

const name = ref('')
const description = ref('')
// a clan costs Kado points (ClanSettings::$creation_price)
const creationPrice = computed(() => clanStore.rules?.creation_price ?? 0)
const canPayCreation = computed(() => (authStore.user?.kado_points ?? 0) >= creationPrice.value)
const submit = () => {
  if (isCreating.value) {
    return
  }
  createClan({ name: name.value, description: description.value || null }).then((data) => {
    authStore.fetchUser()
    clanStore.reload()
    router.push({ name: 'clans.show', params: { id: data.data.id } })
  }).catch(() => {})
}

const tabs = computed(() => [
  { label: t('common.ranking'), value: 'war', route: { name: 'clans.index' } },
  { label: t('clans_index.missions'), value: 'missions', route: { name: 'clans.index', query: { tab: 'missions' } } },
  { label: t('clans_index.create_tab'), value: 'create', route: { name: 'clans.index', query: { tab: 'create' } } },
])
const selectedIndex = computed(() => tabs.value.findIndex((item) => item.value === tab.value))
</script>

<template>
  <NavTabs :items="tabs" :selected-index="selectedIndex" />

  <div class="px-2 space-y-4">
    <KadoPageTitle>{{ $t('clans_index.title') }}</KadoPageTitle>
    <ClanPeriodBanner :tournament="tournament ?? clanStore.tournament" />
    <p v-if="clanStore.debug" class="text-right text-xs">
      <RouterLink :to="{ name: 'clans.debug' }">{{ $t('clans_index.debug_tools') }}</RouterLink>
    </p>

    <p v-if="clanStore.clan">
      <img src="/assets/img/gfx/icons/clan.gif" alt="" />
      <i18n-t keypath="clans_index.your_clan">
        <template #clan>
          <RouterLink :to="{ name: 'clans.show', params: { id: clanStore.clan.id } }" class="font-bold">{{ clanStore.clan.name }}</RouterLink>
        </template>
      </i18n-t>
    </p>
    <!-- the maximum set in the admin (ClanSettings::$max_members) -->
    <i18n-t v-else-if="clanStore.rules?.max_members" keypath="clans_index.no_clan_with_max" tag="p">
      <template #max>{{ clanStore.rules.max_members }}</template>
      <template #create>
        <RouterLink :to="{ name: 'clans.index', query: { tab: 'create' } }">{{ $t('clans_index.create_link') }}</RouterLink>
      </template>
    </i18n-t>
    <i18n-t v-else keypath="clans_index.no_clan" tag="p">
      <template #create>
        <RouterLink :to="{ name: 'clans.index', query: { tab: 'create' } }">{{ $t('clans_index.create_link') }}</RouterLink>
      </template>
    </i18n-t>
    <p v-if="clanStore.applications.length" class="text-sm">
      {{ $t('clans_index.pending_applications') }}
      <template v-for="(a, i) in clanStore.applications" :key="a.id">
        <template v-if="i">, </template>
        <RouterLink :to="{ name: 'clans.show', params: { id: a.clan.id } }">{{ a.clan.name }}</RouterLink>
      </template>
    </p>

    <template v-if="tab === 'create'">
      <MessageError v-if="clanStore.clan">{{ $t('clans_index.already_member') }}</MessageError>
      <form v-else class="max-w-lg space-y-2" @submit.prevent="submit">
        <div>
          <label for="clanName" class="font-bold">{{ $t('clans_index.name_label') }}</label>
          <FormInput id="clanName"
                     v-model="name"
                     type="text"
                     minlength="3"
                     maxlength="32"
                     required
                     class="w-full" />
          <p class="m-0 text-xs text-kado-blue-800">{{ $t('clans_index.name_help') }}</p>
        </div>
        <div>
          <label for="clanDescription" class="font-bold">{{ $t('clans_index.description_label') }}</label>
          <FormTextarea id="clanDescription"
                        v-model="description"
                        rows="6"
                        maxlength="5000" />
        </div>
        <MessageError v-if="createError">{{ createError }}</MessageError>
        <FormButton type="submit"
                    size="lg"
                    :disabled="isCreating || !canPayCreation"
                    :title="canPayCreation ? '' : $t('account.not_enough_points')">
          <template v-if="!isCreating"><Number :value="creationPrice" color="green" /> <KadoPoints class="inline size-5" /></template>
          {{ isCreating ? $t('clans_index.creating') : $t('clans_index.create') }}
        </FormButton>
      </form>
    </template>

    <template v-else>
      <form class="flex items-center gap-2" @submit.prevent="doSearch">
        <FormInput v-model="search" type="search" :placeholder="$t('clans_index.search_placeholder')" />
        <FormButton type="submit" size="lg">{{ $t('clans_index.search') }}</FormButton>
      </form>

      <MessageError v-if="error">{{ error }}</MessageError>
      <div class="relative min-h-24 overflow-x-auto">
        <Loader v-if="isLoading && !clans.length" />
        <KadoTable class="w-full">
          <thead>
            <tr class="text-[10px] uppercase">
              <th>{{ $t('common.position') }}</th>
              <th class="min-w-28">{{ $t('clans_index.clan') }}</th>
              <th>{{ $t('clans_index.members') }}</th>
              <template v-if="tab === 'war'">
                <th><img src="/assets/img/gfx/icons/clan_points.gif"
                         :alt="$t('clans_index.score_alt')"
                         :title="$t('clans_index.attack_score')"
                         class="h-5" /></th>
                <th><img src="/assets/img/gfx/icons/atk.gif"
                         :alt="$t('clans_index.attacks_alt')"
                         :title="$t('clans_index.attacks_won')"
                         class="h-5" /></th>
                <th><img src="/assets/img/gfx/icons/def.gif"
                         :alt="$t('clans_index.defenses_alt')"
                         :title="$t('clans_index.defenses_won')"
                         class="h-5" /></th>
              </template>
              <template v-else>
                <th><img src="/gfx/clan/clan_mission_points.png"
                         :alt="$t('clans_index.score_alt')"
                         :title="$t('clans_index.mission_score')"
                         class="h-5" /></th>
                <th :title="$t('clans_index.missions_won')">{{ $t('clans_index.missions') }}</th>
                <th :title="$t('clans_index.steps_title')">{{ $t('clans_index.steps') }}</th>
              </template>
            </tr>
          </thead>
          <tbody>
            <tr v-for="(clan, index) in clans"
                :key="clan.id"
                :class="[index % 2 ? 'bg-white' : 'bg-kado-blue-100', { 'font-bold': clan.id === clanStore.clan?.id }]">
              <td><Number :value="clan.rank" :color="tab === 'war' ? 'green' : 'violet'" /></td>
              <td class="text-left">
                <RouterLink :to="{ name: 'clans.show', params: { id: clan.id } }">{{ clan.name }}</RouterLink>
              </td>
              <td>{{ clan.members_count }}</td>
              <template v-if="tab === 'war'">
                <td class="text-right"><Number :value="clan.war_score" color="orange" /></td>
                <td class="text-right"><Number :value="clan.attacks_won" color="pink" /></td>
                <td class="text-right"><Number :value="clan.defenses_won" color="blue" /></td>
              </template>
              <template v-else>
                <td class="text-right"><Number :value="clan.mission_score" color="violet" /></td>
                <td class="text-right">{{ clan.missions_completed }}</td>
                <td class="text-right whitespace-nowrap" :title="clan.mission ? $t('clans_index.mission_number', { number: clan.mission.number }) : ''">
                  <template v-if="clan.mission">{{ clan.mission.steps_done }} / {{ clan.mission.steps }}</template>
                  <template v-else>-</template>
                </td>
              </template>
            </tr>
            <tr v-if="!isLoading && !clans.length">
              <td colspan="6" class="italic">{{ $t('clans_index.empty') }}</td>
            </tr>
          </tbody>
        </KadoTable>
      </div>
      <p v-if="hasNextPage" class="mx-2.5 my-4 text-center">
        <FormButton size="lg" @click="loadMore()">{{ $t('clans_index.load_more') }}</FormButton>
      </p>
    </template>
  </div>
</template>
