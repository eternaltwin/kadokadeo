import { defineStore } from 'pinia'
import { ref } from 'vue'

import { useApi } from '@/composables/useApi'

// what the menus need about the clans: the period of the tournament, the clan of the player, the top 3
export const useClanStore = defineStore('clan', () => {
  const tournament = ref(null)
  const clan = ref(null)
  const applications = ref([])
  const top = ref([])
  // the tools of /clans/debug are available (KADO_DEBUG_TOOLS)
  const debug = ref(false)

  const { get } = useApi()

  const reload = () =>
    get('/clans/overview').then((response) => {
      const data = response.data.data
      tournament.value = data.tournament
      clan.value = data.clan
      applications.value = data.applications
      top.value = data.top
      debug.value = data.debug
    }).catch(() => {})

  return {
    tournament,
    clan,
    applications,
    top,
    debug,
    reload,
  }
})
