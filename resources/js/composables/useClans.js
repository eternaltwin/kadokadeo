import { useApi } from './useApi'

// the clans (App\Http\Controllers\Api\Clan*Controller)
export function useClans() {
  const { isLoading, error, get, post, put, del } = useApi()

  const data = (response) => response.data

  return {
    isLoading,
    error,
    fetchRanking: (params = {}) => get('/clans', { params }).then(data),
    fetchOverview: () => get('/clans/overview').then(data),
    createClan: (payload) => post('/clans', payload).then(data),
    fetchClan: (id) => get(`/clans/${id}`).then(data),
    updateClan: (id, payload) => put(`/clans/${id}`, payload),
    fetchMembers: (id) => get(`/clans/${id}/members`).then(data),
    fetchStatus: (id) => get(`/clans/${id}/status`).then(data),
    fetchMissions: (id) => get(`/clans/${id}/missions`).then(data),
    fetchApplications: (id) => get(`/clans/${id}/applications`).then(data),
    apply: (id, message) => post(`/clans/${id}/applications`, { message }).then(data),
    cancelApplication: (applicationId) => del(`/clan-applications/${applicationId}`),
    acceptApplication: (applicationId) => post(`/clan-applications/${applicationId}/accept`),
    refuseApplication: (applicationId) => post(`/clan-applications/${applicationId}/refuse`),
    leave: () => post('/clans/leave'),
    kick: (id, etwinId) => post(`/clans/${id}/members/${etwinId}/kick`),
    promote: (id, etwinId) => post(`/clans/${id}/members/${etwinId}/leader`),
    attack: (id, gameId) => post(`/clans/${id}/attacks`, { game_id: gameId }).then(data),
    defend: (attackId, superDefense = false) => post(`/clan-attacks/${attackId}/defend`, { super_defense: superDefense }).then(data),
    cancelAttack: (attackId) => post(`/clan-attacks/${attackId}/cancel`),
    playStep: (stepId) => post(`/clan-mission-steps/${stepId}/play`).then(data),
    useBonus: (bonusId, payload = {}) => post(`/clan-bonuses/${bonusId}/use`, payload),
    assignBonus: (bonusId, etwinId) => post(`/clan-bonuses/${bonusId}/assign`, { user: etwinId }),
    fetchAction: (actionId) => get(`/clan-actions/${actionId}`).then(data),
  }
}
