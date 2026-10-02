import { defineStore } from 'pinia'
import { ref } from 'vue'

import { useApi } from '@/composables/useApi'

export const useAnnouncementStore = defineStore('announcement', () => {
  const announcement = ref(null)

  const { get, isLoading } = useApi()

  const fetchAnnouncement = async() => {
    if (isLoading.value) {
      return
    }
    try {
      const { data } = await get('/announcement')
      announcement.value = data.data
    } catch {
      // Keep the last known announcement on network/server errors
    }
  }

  return {
    announcement,
    isLoading,
    fetchAnnouncement,
  }
})
