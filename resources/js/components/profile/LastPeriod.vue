<script setup>
import GreenStar from '@svg/greenStar.svg'
import KadoPoints from '@svg/k.svg'
import OrangeStar from '@svg/orangeStar.svg'
import RedStar from '@svg/redStar.svg'

import { t } from '@/i18n'
import { formatDate } from '@/i18n/dates'
import { intlLocale } from '@/i18n/locale'

// the last finished period of a player, as on KadoKado: the Kado points it brought at its close, the promotions in the
// leagues, the rankings; the buttons go through the older finished periods (App\Services\PeriodSummaryService)
const props = defineProps({
  // the etwin_id of the player and their name
  playerId: { type: String, required: true },
  playerName: { type: String, required: true },
  isMe: { type: Boolean, default: false },
})

const { fetchPeriodSummary, isLoading, error } = useProfile()
const summary = ref(null)
// the period shown: null, the last finished one
const periodId = ref(null)

// the last request: an answer to an older one (another player, another period) is dropped
let request = 0
function load() {
  const current = ++request
  fetchPeriodSummary(props.playerId, periodId.value).then((data) => {
    if (current === request) {
      summary.value = data
    }
  }).catch(() => {}) // (shown by error)
}
watch(() => props.playerId, () => {
  periodId.value = null
  summary.value = null
})
watch([() => props.playerId, periodId], load, { immediate: true })

const stars = computed(() => [
  { count: summary.value?.stars.green, icon: GreenStar, label: t('last_period.star_green') },
  { count: summary.value?.stars.orange, icon: OrangeStar, label: t('last_period.star_orange') },
  { count: summary.value?.stars.red, icon: RedStar, label: t('last_period.star_red') },
].filter((star) => star.count > 0))
const rankings = computed(() => [...(summary.value?.rankings ?? [])].sort((a, b) => a.game.name.localeCompare(b.game.name)))
// 1er, 2e / 1st, 2nd, 3rd, 4th: the ordinal categories of the language
const ORDINALS = {
  one: () => t('last_period.ordinal_one'),
  two: () => t('last_period.ordinal_two'),
  few: () => t('last_period.ordinal_few'),
  other: () => t('last_period.ordinal_other'),
}
const ordinal = (rank) => (ORDINALS[new Intl.PluralRules(intlLocale(), { type: 'ordinal' }).select(rank)] ?? ORDINALS.other)()
// (the periods are in UTC: they end at 23:59:59 UTC)
const shownDate = (date) => formatDate(dayjs.utc(date))

// the tables of the summary: thin uppercase headers, cells without borders
const thinTitles = '[&_th]:px-2 [&_th]:text-xs [&_th]:font-normal [&_th]:uppercase [&_td]:border-0 [&_td]:px-2'
</script>

<template>
  <KadoPageTitle class="mb-5">{{ isMe ? $t('last_period.title_me') : $t('last_period.title_other', { player: playerName }) }}</KadoPageTitle>

  <Loader v-if="isLoading && !summary">{{ $t('last_period.loading') }}</Loader>
  <MessageError v-else-if="error">{{ error }}</MessageError>
  <p v-else-if="!summary" class="mx-2.5 my-4 text-center italic">{{ $t('last_period.none_finished') }}</p>

  <div v-else class="relative">
    <Loader v-if="isLoading" />

    <KadoSectionTitle>{{ isMe ? $t('last_period.summary_me') : $t('last_period.summary_other') }}</KadoSectionTitle>
    <p class="mx-2.5 mt-2 text-center text-sm">
      {{ $t('last_period.dates', { start: shownDate(summary.period.start_at), end: shownDate(summary.period.end_at) }) }}
    </p>
    <ul class="mt-4 mb-6 ml-10 list-inside list-kado space-y-1">
      <template v-if="summary.clan?.reward">
        <i18n-t v-if="isMe" keypath="last_period.clan_me" tag="li">
          <template #clan><RouterLink v-if="summary.clan.id" :to="{ name: 'clans.show', params: { id: summary.clan.id } }">{{ summary.clan.name }}</RouterLink></template>
          <template #reward><Number :value="summary.clan.reward" color="green" /></template>
          <template #icon><KadoPoints class="inline size-4.25" /></template>
        </i18n-t>
        <i18n-t v-else keypath="last_period.clan_other" tag="li">
          <template #clan><RouterLink v-if="summary.clan.id" :to="{ name: 'clans.show', params: { id: summary.clan.id } }">{{ summary.clan.name }}</RouterLink></template>
          <template #reward><Number :value="summary.clan.reward" color="green" /></template>
          <template #icon><KadoPoints class="inline size-4.25" /></template>
        </i18n-t>
      </template>
      <template v-if="summary.promotions_reward">
        <i18n-t v-if="isMe" keypath="last_period.progress_me" tag="li">
          <template #reward><Number :value="summary.promotions_reward" color="green" /></template>
          <template #icon><KadoPoints class="inline size-4.25" /></template>
        </i18n-t>
        <i18n-t v-else keypath="last_period.progress_other" tag="li">
          <template #reward><Number :value="summary.promotions_reward" color="green" /></template>
          <template #icon><KadoPoints class="inline size-4.25" /></template>
        </i18n-t>
      </template>
      <template v-if="summary.feathers?.reward">
        <i18n-t v-if="isMe" keypath="last_period.feathers_me" tag="li">
          <template #count>{{ summary.feathers.count }}</template>
          <template #reward><Number :value="summary.feathers.reward" color="green" /></template>
          <template #icon><KadoPoints class="inline size-4.25" /></template>
        </i18n-t>
        <i18n-t v-else keypath="last_period.feathers_other" tag="li">
          <template #count>{{ summary.feathers.count }}</template>
          <template #reward><Number :value="summary.feathers.reward" color="green" /></template>
          <template #icon><KadoPoints class="inline size-4.25" /></template>
        </i18n-t>
      </template>
      <template v-if="summary.daily_ranking?.reward">
        <i18n-t v-if="isMe"
                keypath="last_period.daily_me"
                tag="li"
                :plural="summary.daily_ranking.points">
          <template #rank>{{ summary.daily_ranking.rank }}{{ ordinal(summary.daily_ranking.rank) }}</template>
          <template #count>{{ summary.daily_ranking.points }}</template>
          <template #reward><Number :value="summary.daily_ranking.reward" color="green" /></template>
          <template #icon><KadoPoints class="inline size-4.25" /></template>
        </i18n-t>
        <i18n-t v-else
                keypath="last_period.daily_other"
                tag="li"
                :plural="summary.daily_ranking.points">
          <template #rank>{{ summary.daily_ranking.rank }}{{ ordinal(summary.daily_ranking.rank) }}</template>
          <template #count>{{ summary.daily_ranking.points }}</template>
          <template #reward><Number :value="summary.daily_ranking.reward" color="green" /></template>
          <template #icon><KadoPoints class="inline size-4.25" /></template>
        </i18n-t>
      </template>
      <li v-for="star in stars" :key="star.label">
        {{ $t('last_period.times', { count: star.count }) }} <component :is="star.icon" class="inline size-4" :aria-label="star.label" />
      </li>
      <li class="font-bold">{{ $t('last_period.total') }} <Number :value="summary.total" color="green" /> <KadoPoints class="inline size-4.25" /></li>
    </ul>

    <KadoSectionTitle>{{ $t('last_period.improvements') }}</KadoSectionTitle>
    <KadoTable v-if="summary.promotions.length" :class="thinTitles" class="mx-auto my-4 w-3/4">
      <thead>
        <tr>
          <th></th>
          <th>{{ $t('common.game') }}</th>
          <th>{{ $t('common.position') }}</th>
          <th>{{ $t('last_period.levels_short') }}</th>
          <th>{{ $t('common.score') }}</th>
          <th>{{ $t('last_period.gains') }}</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="promotion in summary.promotions" :key="promotion.game.id">
          <td><img src="/gfx/greenArrowUp.png" :alt="$t('last_period.qualified')" :title="$t('common.promotion_qualified')" /></td>
          <td><RouterLink :to="{ name: 'games.show', params: { id: promotion.game.id } }">{{ promotion.game.name }}</RouterLink></td>
          <td><Number :value="promotion.rank_position" color="orange" /><sup> {{ ordinal(promotion.rank_position) }}</sup></td>
          <td><img :src="`/gfx/leagues/${promotion.from_league_id}s.svg`" :alt="$t('common.level')" class="mx-auto h-auto w-6" /></td>
          <td><Number :value="promotion.score" color="blue" /></td>
          <td class="whitespace-nowrap"><Number :value="promotion.reward" color="green" /> <KadoPoints class="inline size-4.25" /></td>
        </tr>
      </tbody>
    </KadoTable>
    <p v-else class="mx-2.5 my-4 text-center italic">{{ $t('last_period.no_promotions') }}</p>

    <KadoSectionTitle>{{ $t('common.ranking') }}</KadoSectionTitle>
    <KadoTable v-if="rankings.length" :class="thinTitles" class="mx-auto my-4 w-3/5">
      <thead>
        <tr>
          <th>{{ $t('common.game') }}</th>
          <th>{{ $t('common.position') }}</th>
          <th>{{ $t('last_period.levels_short') }}</th>
          <th>{{ $t('common.score') }}</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="run in rankings" :key="run.id">
          <td class="text-left"><RouterLink :to="{ name: 'games.show', params: { id: run.game.id } }">{{ run.game.name }}</RouterLink></td>
          <td><Number :value="run.league_rank" color="orange" /><sup> {{ ordinal(run.league_rank) }}</sup></td>
          <td><img v-if="run.league_id"
                   :src="`/gfx/leagues/${run.league_id}s.svg`"
                   :alt="$t('common.level')"
                   class="mx-auto h-auto w-6" /></td>
          <td class="text-right"><Number :value="run.score" color="blue" /></td>
        </tr>
      </tbody>
    </KadoTable>
    <p v-else class="mx-2.5 my-4 text-center italic">{{ $t('last_period.no_runs') }}</p>

    <CompetitionPeriodNavigator
      :label="$t('competition.period', { period: summary.period.id })"
      :can-go-previous="!!summary.previous_period_id"
      :can-go-next="!!summary.next_period_id"
      :disabled="isLoading"
      class="mt-6"
      @previous="periodId = summary.previous_period_id"
      @next="periodId = summary.next_period_id"
    />
  </div>
</template>
