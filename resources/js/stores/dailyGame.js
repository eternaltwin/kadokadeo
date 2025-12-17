import dayjs from 'dayjs'
import { defineStore } from 'pinia'
import { ref } from 'vue'

import { updateAtMidnight } from '@/composables/helpers'
import { useApi } from '@/composables/useApi'

export const useDailyGameStore = defineStore('dailyGame', () => {
  const dailyGame = ref(null)
  const game = ref(null)
  const scores = ref([])
  const position = ref(null)

  const { get, isLoading } = useApi()
  const { get: getScores, isLoading: isScoresLoading } = useApi()

  const fetchDailyGameIfNecessary = () => {
    const dgLocal = localStorage.getItem('dailyGame')
    if (dgLocal) {
      const tmp = JSON.parse(dgLocal)
      if (tmp) {
        if (tmp.date === dayjs().utc().format('YYYY-MM-DD')) {
          dailyGame.value = tmp.game
          game.value = tmp.game.game
        }
      }
    }

    if (!dailyGame.value) {
      get('/daily/game').then((response) => {
        dailyGame.value = response.data.dailyGame
        dailyGame.value.game = response.data.data
        game.value = response.data.data
        localStorage.setItem(
          'dailyGame',
          JSON.stringify({
            date: dayjs().utc().format('YYYY-MM-DD'),
            game: dailyGame.value,
          }),
        )
      })
    }
  }

  const fetchScores = () => {
    getScores('/daily/scores').then((response) => {
      scores.value = response.data.data
      position.value = response.data.position
    })
  }

  const reload = () => {
    fetchDailyGameIfNecessary()
    fetchScores()
    updateAtMidnight().then(() => reload())
  }
  reload()

  return {
    dailyGame,
    game,
    isDailyGameLoading: isLoading,
    scores,
    position,
    isScoresLoading,
    fetchScores,
  }
})
