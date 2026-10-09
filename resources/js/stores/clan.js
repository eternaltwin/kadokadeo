import { defineStore } from 'pinia'
import { ref } from 'vue'

import { useApi } from '@/composables/useApi'

// what the menus need about the clans: the period of the tournament, the clan of the player, the top 3
export const useClanStore = defineStore('clan', () => {
  const tournament = ref(null)
  const clan = ref(null)
  const applications = ref([])
  const top = ref([])

  const { get } = useApi()

  const reload = () =>
    get('/clans/overview').then((response) => {
      const data = response.data.data
      tournament.value = data.tournament
      clan.value = data.clan
      applications.value = data.applications
      top.value = data.top
    }).catch(() => {})

  return {
    tournament,
    clan,
    applications,
    top,
    reload,
  }
})
