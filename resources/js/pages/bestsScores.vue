<script setup>
import PlayButton from '@svg/playButton.svg'
const { isLoading, error, fetchSiteRecords } = useGames()
const siteRecords = ref([])

fetchSiteRecords()
  .then((data) => {
    siteRecords.value = data
  })
  .catch(() => null)
</script>

<template>
  <div>
    <KadoPageTitle class="mb-5">{{ $t('site_records.title') }}</KadoPageTitle>

    <Loader v-if="isLoading">{{ $t('site_records.loading') }}</Loader>
    <MessageError v-else-if="error">{{ $t('common.error_with', { error }) }}</MessageError>
    <div v-else class="px-8 sm:px-16">
      <KadoTable class="w-full">
        <thead>
          <tr class="text-kado-orange-500 uppercase text-sm *:px-2 *:text-center">
            <th>{{ $t('site_records.game') }}</th>
            <th>{{ $t('site_records.record') }}</th>
            <th>{{ $t('site_records.player') }}</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="siteRecord in siteRecords" :key="siteRecord.game.id">
            <td class="text-left">
              <RouterLink :to="{ name: 'games.show', params: { id: siteRecord.game.id } }">
                {{ siteRecord.game.name }}
              </RouterLink>
            </td>
            <td class="text-left">
              <div v-if="siteRecord.record !== null" class="inline-flex items-center gap-1">
                <RouterLink
                  v-if="siteRecord.has_replay"
                  :to="{ name: 'runs.show', params: { id: siteRecord.run_id } }"
                  :title="`Voir le replay du record de ${siteRecord.game.name}`"
                  :aria-label="`Voir le replay du record de ${siteRecord.game.name}`"
                  class="flex items-center gap-1 shrink-0"
                >
                  <PlayButton class="size-4 text-primary" />
                  <Number color="blue" :value="siteRecord.record" />
                </RouterLink>
                <Number v-else color="blue" :value="siteRecord.record" />
              </div>
              <span v-else>-</span>
            </td>
            <td class="text-left">
              <RouterLink v-if="siteRecord.user" :to="{ name: 'profile.show', params: { id: siteRecord.user.etwin_id } }">
                {{ siteRecord.user.display_name }}
              </RouterLink>
            </td>
          </tr>
        </tbody>
      </KadoTable>
    </div>
  </div>
</template>
