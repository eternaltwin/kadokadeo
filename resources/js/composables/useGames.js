import { useApi } from './useApi'

export function useGames() {
  const { isLoading, error, get } = useApi()

  function fetchGames() {
    return get('/games').then((response) => response.data)
  }

  function fetchGame(id) {
    return get(`/games/${id}`).then((response) => response.data)
  }

  return {
    isLoading,
    error,
    fetchGames,
    fetchGame,
  }
}
