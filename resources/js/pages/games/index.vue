<script setup>
/*
TO DO LIST :
- qualifArrow à utiliser pour voir si qualifié sur le jeu ou pas (ici défini sur false)
*/

const { isLoading, fetchGames } = useGames()
const route = useRoute()
const games = ref([])
const categories = ref([])
const qualifArrow = ref(false)

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

function getStarImage(game) {
  const star = game.user_star
  switch (star) {
    case 0:
      return '/gfx/starGreenMedium.gif'
    case 1:
      return '/gfx/starOrangeMedium.gif'
    case 2:
      return '/gfx/starRedMedium.gif'
    default:
      return null
  }
}
</script>

<template>
  <nav id="tabNav">
    <ul>
    </ul>
  </nav>
  <NavTabs
    :items="[
      { label: 'Tous les jeux', value: 'all', route: { name: 'games.index' } },
      ...categories.map((cat) => ({ label: cat.name, value: cat.name, route: { name: 'games.index', query: { category: cat.name } } })),
    ]"
    :selected-index="route.query.category ? categories.findIndex((c) => c.name === route.query.category) + 1 : 0"
  />

  <div class="-ml-5 -mr-5">
    <GamesDailyGameBlock />

    <div id="gamesBoxes" class="relative min-h-48 flex flex-wrap justify-around px-2">
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
          
          <div v-show="qualifArrow" class="absolute top-1.25 left-3.25 z-2">
            <img src="/gfx/iconGameQualifGreenArrow.gif" alt="iconGameQualifGreenArrow.gif" title="Qualifié !" />
          </div>

          <div class="gameBoxImg">
            <img :src="game.image_path" :alt="game.name" />
          </div>
          
          <div class="gameBoxStar">
            <img v-if="game.user_star !== null" :src="getStarImage(game)" :alt="`star ${game.user_star}`" />
          </div>
          <h3 class="font-normal text-center text-kado-cyan-900 w-44 text-xl absolute top-28 left-[55%] -translate-x-1/2 z-10">{{ game.name }}</h3>
        </RouterLink>
      </template>
    </div>
  </div>
</template>
