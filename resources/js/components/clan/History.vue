<script setup>
import { formatDate } from '@/i18n/dates'
// "Historique": the finished attacks (A) and defenses (D) of the clan, without the cancelled attacks
const props = defineProps({
  clan: { type: Object, required: true },
})

const { items: rows, meta, hasNextPage, loadMore, reload, isLoading, error } = useClanHistory(() => props.clan.id)
// a new line: the first page again
onClanUpdated(() => props.clan.id, ['history'], reload)
const shownDate = (date) => (date ? formatDate(date, 'dateTime') : '—')
</script>

<template>
  <div class="relative space-y-4">
    <MessageError v-if="error">{{ error }}</MessageError>
    <Loader v-if="isLoading && !meta" />

    <div class="overflow-x-auto">
      <KadoTable v-if="meta" class="w-full text-sm [&_td]:px-2 [&_td]:py-1">
        <thead>
          <tr class="uppercase text-2xs">
            <th class="text-left">{{ $t('clan_history.date') }}</th>
            <th class="min-w-10" :title="$t('clan_history.type_title')">{{ $t('clan_history.type') }}</th>
            <th class="min-w-16 text-left">{{ $t('common.player') }}</th>
            <th class="min-w-20 text-left">{{ $t('clan_history.clan') }}</th>
            <th class="min-w-16 text-left">{{ $t('common.game') }}</th>
            <th class="text-right">{{ $t('common.score') }}</th>
            <th>{{ $t('clan_history.status') }}</th>
            <th class="text-center"><img src="/assets/img/gfx/icons/clan_points.gif" :alt="$t('clan_history.points')" class="w-5"></th>
          </tr>
        </thead>
        <tbody class="text-2xs">
          <tr v-if="!rows.length" class="bg-kado-blue-100">
            <td colspan="8" class="py-4 italic text-kado-blue-700">{{ $t('clan_history.empty') }}</td>
          </tr>
          <tr v-for="(row, index) in rows" :key="row.id" :class="index % 2 ? 'bg-white' : 'bg-kado-blue-100'">
            <td class="text-left whitespace-nowrap">{{ shownDate(row.date) }}</td>
            <td class="font-bold">
              <img :src="row.type === 'attack' ? '/gfx/clan/atksmall.gif' : '/gfx/clan/defsmall.gif'"
                   :alt="row.type === 'attack' ? $t('clan_history.attack') : $t('clan_history.defense')"
                   class="w-5" />
            </td>
            <td class="text-left small-caps">
              <RouterLink v-if="row.player" :to="{ name: 'profile.show', params: { id: row.player.etwin_id } }">{{ row.player.display_name }}</RouterLink>
              <template v-else>—</template>
            </td>
            <td class="text-left font-bold">
              <RouterLink :to="{ name: 'clans.show', params: { id: row.clan.id } }">{{ row.clan.name }}</RouterLink>
            </td>
            <td class="text-left">
              <RouterLink :to="{ name: 'games.show', params: { id: row.game.id } }" class="text-kado-blue-700">{{ row.game.name }}</RouterLink>
            </td>
            <td class="text-right whitespace-nowrap">
              <Number v-if="row.score !== null" :value="row.score" color="blue" />
            </td>
            <td class="whitespace-nowrap">
              {{ row.status_label }}
              <template v-if="row.other_player">
                {{ row.type === 'attack' ? $t('clan_history.by', { name: row.other_player.display_name }) : $t('clan_history.attack_of', { name: row.other_player.display_name }) }}
              </template>
              <template v-if="row.other_score !== null">
                (<Number :value="row.other_score" color="blue" />)
              </template>
            </td>
            <td class="text-center whitespace-nowrap font-bold"
                :title="row.type === 'defense' && row.points > 0 ? $t('clan_history.defender_points') : null">
              <Number v-if="row.points > 0"
                      :value="row.points"
                      color="pink"
                      signed />
              <Number v-else-if="row.points < 0"
                      :value="row.points"
                      color="blue"
                      signed />
              <template v-else>—</template>
            </td>
          </tr>
        </tbody>
      </KadoTable>
    </div>

    <div v-if="hasNextPage" class="text-center">
      <FormButton size="lg" :disabled="isLoading" @click="loadMore()">{{ $t('clan_history.load_more') }}</FormButton>
    </div>
  </div>
</template>
