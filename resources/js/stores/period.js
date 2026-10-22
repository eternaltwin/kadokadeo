import dayjs from 'dayjs'
import { defineStore } from 'pinia'
import { computed,ref } from 'vue'

import { updateAtMidnight } from '@/composables/helpers'
import { useApi } from '@/composables/useApi'
import { onRealtimeReconnect, refetchSoon, useChannel } from '@/composables/useRealtime'

export const usePeriodStore = defineStore('period', () => {
  const period = ref(null)
  const currentTime = ref(Date.now())

  const { get } = useApi()

  const fetchPeriod = () => {
    currentTime.value = Date.now()
    return get('/period/current').then((response) => {
      period.value = response.data.data
    })
  }
  // (the day of the period changes at midnight)
  const reload = () => {
    fetchPeriod()
    updateAtMidnight().then(() => reload())
  }
  reload()
  // a new period (App\Events\PeriodStarted), not all the players at once
  useChannel('site', { 'period.started': refetchSoon(fetchPeriod, { delay: 0, jitter: 10000 }) }, { isPrivate: false })
  onRealtimeReconnect(fetchPeriod)

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
