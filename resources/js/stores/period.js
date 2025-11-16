import dayjs from 'dayjs'
import { defineStore } from 'pinia'
import { computed,ref } from 'vue'

import { useApi } from '@/composables/useApi'

export const usePeriodStore = defineStore('period', () => {
  const period = ref(null)
  const currentTime = ref(Date.now())

  const { get } = useApi()

  get('/period/current').then((response) => {
    period.value = response.data.data
  })

  const updateAtMidnight = () => {
    const now = new Date()
    const tomorrow = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1)
    const msUntilMidnight = tomorrow - now

    setTimeout(() => {
      currentTime.value = Date.now()
      get('/period/current').then((response) => {
        period.value = response.data.data
      })
      updateAtMidnight() // Schedule next midnight update
    }, msUntilMidnight)
  }

  updateAtMidnight()

  const dayCount = computed(() => {
    if (!period.value) {
      return 0
    }
    const startDate = dayjs(period.value.start_at)
    const now = dayjs(currentTime.value)

    return now.diff(startDate, 'day')
  })

  return {
    period,
    dayCount,
  }
})
