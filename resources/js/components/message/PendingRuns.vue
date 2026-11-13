<script setup>
import { storeToRefs } from 'pinia'

import Error from '@/components/message/Error.vue'
import { formatScore } from '@/composables/helpers'
import { t } from '@/i18n'
import { intlLocale } from '@/i18n/locale'
import { useAuthStore } from '@/stores/auth'
import { usePendingRunsStore } from '@/stores/pendingRuns'

const authStore = useAuthStore()
const pendingRunsStore = usePendingRunsStore()
const { runs, isSending } = storeToRefs(pendingRunsStore)
const showDetails = ref(false)

const formatDate = (iso) => (iso ? new Date(iso).toLocaleString(intlLocale()) : '?')

function discard(run) {
  if (confirm(t('pending_runs.confirm_delete', { game: run.game_name, score: formatScore(run.request?.score ?? 0) }))) {
    pendingRunsStore.discard(run.run_id)
  }
}

// sent again as soon as the player is logged in
watch(
  () => authStore.isAuthenticated,
  (isAuthenticated) => {
    if (isAuthenticated) {
      pendingRunsStore.retryAll({ auto: true })
    }
  },
  { immediate: true },
)
</script>

<template>
  <Error v-if="authStore.isAuthenticated && runs.length">
    <span class="text-xs">
      {{ $t('pending_runs.not_sent', { count: runs.length }, runs.length) }}
    </span>
    <span class="mt-2 flex flex-wrap gap-2">
      <button
        type="button"
        class="cursor-pointer border border-kado-pink-400 bg-white px-2.5 py-1.5 text-xs leading-none font-bold text-kado-pink-600 disabled:cursor-wait disabled:opacity-60"
        :disabled="isSending"
        @click="pendingRunsStore.retryAll()"
      >
        {{ isSending ? $t('pending_runs.sending') : $t('pending_runs.retry') }}
      </button>
      <button
        type="button"
        class="cursor-pointer border border-kado-pink-400 bg-white px-2.5 py-1.5 text-xs leading-none font-bold text-kado-pink-600"
        @click="showDetails = !showDetails"
      >
        {{ showDetails ? $t('pending_runs.hide_details') : $t('pending_runs.show_details') }}
      </button>
    </span>
    <span v-if="showDetails" class="mt-2 block text-xs">
      <span v-for="run in runs" :key="run.run_id" class="mt-1 flex items-center gap-2">
        <span class="flex-1">
          <b>{{ run.game_name }}</b>{{ $t('pending_runs.detail', { score: formatScore(run.request?.score ?? 0), date: formatDate(run.saved_at) })  }}
          <br>
          {{ $t('pending_runs.error', { error: run.error?.status === 0 ? $t('pending_runs.unreachable') : `${run.error?.status} ${run.error?.message ?? ''}` }) }}
          {{ $t('pending_runs.attempts', { count: run.attempts ?? 1 }, run.attempts ?? 1) }}
        </span>
        <button
          type="button"
          class="cursor-pointer border border-kado-pink-400 bg-white px-2.5 py-1.5 text-xs leading-none font-bold text-kado-pink-600"
          :disabled="isSending"
          @click="discard(run)"
        >
          {{ $t('common.delete') }}
        </button>
      </span>
    </span>
  </Error>
</template>
