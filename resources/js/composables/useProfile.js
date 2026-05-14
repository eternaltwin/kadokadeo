import { useApi } from './useApi'

export function useProfile() {
  const { isLoading, error, get } = useApi()
  const authStore = useAuthStore()

  function fetchProfile(id) {
    const url = id ? `/users/${id}` : `/users/${authStore.user.etwin_id}`
    return get(url).then((response) => response.data)
  }

  return {
    isLoading,
    error,
    fetchProfile,
  }
}
