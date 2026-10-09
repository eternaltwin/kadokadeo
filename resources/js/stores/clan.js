import { defineStore } from 'pinia'
import { ref } from 'vue'

import { useApi } from '@/composables/useApi'

// what the menus need about the clans: the phase of the tournament, the clan of the player, the top 3
export const useClanStore = defineStore('clan', () => {
  const phase = ref(null)
  const clan = ref(null)
  const applications = ref([])
  const top = ref([])

  const { get } = useApi()

  const reload = () =>
    get('/clans/overview').then((response) => {
      const data = response.data.data
      phase.value = data.phase
      clan.value = data.clan
      applications.value = data.applications
      top.value = data.top
    }).catch(() => {})

  return {
    phase,
    clan,
    applications,
    top,
    reload,
  }
})
