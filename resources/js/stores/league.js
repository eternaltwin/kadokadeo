import { defineStore } from 'pinia'

import { t } from '@/i18n'

export const useLeagueStore = defineStore('league', () => {
  const leagues = ref([
    {
      'level': 1,
      'name': t('leagues.beginner'),
      'promotion_max_slots': 50,
      'promotion_ratio': 33,
      'promotion_min_stars': 0,
      'promotion_reward': 100,
    }, {
      'level': 2,
      'name': t('leagues.bronze'),
      'promotion_max_slots': 20,
      'promotion_ratio': 20,
      'promotion_min_stars': 1,
      'promotion_reward': 500,
    }, {
      'level': 3,
      'name': t('leagues.silver'),
      'promotion_max_slots': 5,
      'promotion_ratio': 2,
      'promotion_min_stars': 2,
      'promotion_reward': 2000,
    }, {
      'level': 4,
      'name': t('leagues.gold'),
      'promotion_max_slots': 1,
      'promotion_ratio': null,
      'promotion_min_stars': 2,
      'promotion_reward': 5000,
    }, {
      'level': 5,
      'name': t('leagues.paradise'),
      'promotion_max_slots': null,
      'promotion_ratio': null,
      'promotion_min_stars': null,
      'promotion_reward': 10000,
    },
  ])

  return {
    leagues,
    paradiseLeagueId: computed(() => leagues.value[leagues.value.length - 1].level),
  }
})
