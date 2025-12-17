import dayjs from 'dayjs'
import { defineStore } from 'pinia'
import { computed,ref } from 'vue'

import { updateAtMidnight } from '@/composables/helpers'
import { useApi } from '@/composables/useApi'

export const usePeriodStore = defineStore('period', () => {
  const period = ref(null)
  const currentTime = ref(Date.now())

  const { get } = useApi()

  const reload = () => {
    currentTime.value = Date.now()
    get('/period/current').then((response) => {
      period.value = response.data.data
    })
    updateAtMidnight().then(() => reload())
  }
  reload()

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
