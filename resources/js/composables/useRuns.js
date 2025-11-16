import { useApi } from './useApi'

export function useRuns() {
  const { isLoading, get } = useApi()

  function fetchRun(id) {
    return get(`/runs/${id}`).then((response) => response.data)
  }

  return {
    isLoading,
    fetchRun,
  }
}
