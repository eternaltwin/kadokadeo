import { computed, ref, watch } from 'vue'

import { useApi } from './useApi'

export function useGameRanking(gameId) {
  const { isLoading, error, get } = useApi()
  const period = ref(null)
  const meta = ref({
    current_page: 0,
    last_page: 0,
  })
  const results = ref([])
  const hasNextPage = computed(() => {
    return meta.value.current_page < meta.value.last_page
  })

  function fetchGameRanking() {
    const params = {
      page: meta.value.current_page + 1,
    }
    if (period.value) {
      params.period = period.value
    }
    return get(`/games/${gameId}/ranking`, {
      params,
    }).then((response) => {
      meta.value = response.data.meta
      if (meta.value.current_page === 1) {
        results.value = []
      }
      results.value = results.value.concat(response.data.data)
    })
  }

  watch(period, () => {
    meta.value.current_page = 0
    fetchGameRanking()
  })

  return {
    isLoading,
    error,
    period,
    meta,
    results,
    hasNextPage,
    fetchGameRanking,
  }
}
