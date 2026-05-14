import { computed, ref } from 'vue'

import { useApi } from './useApi'

export function useUserGameHistory(userId) {
  const { isLoading, error, get } = useApi()
  const meta = ref({
    current_page: 0,
    last_page: 0,
  })
  const results = ref([])
  const hasNextPage = computed(() => {
    return meta.value.current_page < meta.value.last_page
  })

  function fetchGameHistory() {
    const params = {
      page: meta.value.current_page + 1,
    }
    return get(`/users/${userId}/history`, {
      params,
    }).then((response) => {
      meta.value = response.data.meta
      if (meta.value.current_page === 1) {
        results.value = []
      }
      results.value = results.value.concat(response.data.data)
    })
  }

  return {
    isLoading,
    error,
    meta,
    results,
    hasNextPage,
    fetchGameHistory,
  }
}
