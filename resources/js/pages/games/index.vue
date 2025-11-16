<script setup>
// import { useGodot } from '@/composables/useGodot'
import { computed, ref } from 'vue'
import { useRoute } from 'vue-router'

import { useGames } from '@/composables/useGames'

const { isLoading, fetchGames } = useGames()
const route = useRoute()
const games = ref([])
const categories = ref([])

fetchGames().then((data) => {
  games.value = data.data
  categories.value = data.categories
})

const gamesFiltered = computed(() => {
  if (route.query.category) {
    return games.value.filter(
      (game) =>
        game.category_id === categories.value.find((c) => c.name === route.query.category)?.id,
    )
  }
  return games.value
})
</script>

<template>
  <nav id="tabNav">
    <ul>
      <li :id="route.query.category === 'all' ? 'tabNavActive' : ''">
        <RouterLink :to="{ name: 'games.index' }">Tous les jeux</RouterLink>
      </li>
      <li v-for="cat in categories" :id="route.query.category === cat.name ? 'tabNavActive' : ''" :key="cat.id">
        <RouterLink :to="{ name: 'games.index', query: { category: cat.name } }">
          {{ cat.name }}
        </RouterLink>
      </li>
      <li>
        <RouterLink :to="{ name: 'games.daily' }">Jeu du jour</RouterLink>
      </li>
    </ul>
  </nav>

  <div id="gamesBoxes">
    <div v-if="isLoading">Chargement des jeux...</div>
    <template v-else>
      <RouterLink
        v-for="game in gamesFiltered"
        :key="`game-${game.id}`"
        class="gameBox"
        :to="{ name: 'games.show', params: { id: game.id } }"
        :title="`Jouer à ${game.name}`"
      >
        <div class="gameBoxBackground"></div>
        <div class="gameBoxImg">
          <img :src="game.image_path" :alt="game.name" />
        </div>
        <div class="gameBoxStar">
          <img :src="'/gfx/starGreenMedium.gif'" alt="green" />
        </div>
        <h3 class="gameBoxTitle">{{ game.name }}</h3>
      </RouterLink>
    </template>
  </div>
</template>
