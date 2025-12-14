<script setup>
// import { useGodot } from '@/composables/useGodot'
import { computed, ref } from 'vue'
import { useRoute } from 'vue-router'

import Loader from '@/components/Loader.vue'
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
      <li :id="!route.query.category ? 'tabNavActive' : ''">
        <RouterLink :to="{ name: 'games.index' }">Tous les jeux</RouterLink>
      </li>
      <li v-for="cat in categories" :id="route.query.category === cat.name ? 'tabNavActive' : ''" :key="cat.id">
        <RouterLink :to="{ name: 'games.index', query: { category: cat.name } }">
          {{ cat.name }}
        </RouterLink>
      </li>
    </ul>
  </nav>

  <div class="withRightAside">
    <div class="gameOfTheDay">
        <RouterLink
            class="gameBoxDay"
            :to="{ name: 'games.daily' }"
            :title="`Jouer au jeu du jour`"
        >
            <div class="gameBoxDayBackground"></div>
            <div class="gameBoxImg">
              <img src="/assets/img/games/Interwheel.png" alt="Nom" />
            </div>
            <h3 class="gameBoxTitle">Kaskade 2</h3>
            <div class="gameBoxDayText">
              Le jeu du jour est choisi aléatoirement chaque jour à minuit.
              Le contrat est commun à tous les joueurs.
              Vous n'avez qu'une seule tentative.
            </div>
        </RouterLink>
        <!-- Mettre en gris si déjà joué, indiquer le contrat (score, points kado) et le classement et le nombre de parties restantes -->
    </div>

    <div id="gamesBoxes" class="relative min-h-48">
        <Loader v-if="isLoading">Chargement des jeux...</Loader>
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
  </div>
</template>
