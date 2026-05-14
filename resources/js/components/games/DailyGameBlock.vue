<script setup>
const dailyGameStore = useDailyGameStore()
const dailyGame = toRef(dailyGameStore, 'dailyGame')
const game = toRef(dailyGameStore, 'game')
</script>

<template>
  <Loader v-if="dailyGameStore.isDailyGameLoading" />
  <div v-else-if="game" class="gameOfTheDay mx-auto mb-10 h-36">
    <RouterLink
      class="gameBoxDay block z-[2] relative h-full w-full"
      :class="{ 'grayscale': dailyGameStore.position !== null }"
      :to="{ name: 'games.daily' }"
      :title="`Jouer au jeu du jour`"
    >
      <div class="__bg z-[1] h-full w-full"></div>
      <div class="gameBoxImg">
        <img :src="game.image_path" :alt="game.name" />
        <h3 class="font-normal text-kado-pink-900 text-xl w-full text-center leading-5">{{ game.name }}</h3>
      </div>
      <div class="gameBoxDayText">
        Le jeu du jour est choisi aléatoirement chaque jour à minuit (UTC). La partie est identique pour tous les joueurs.
        <div class="flex gap-1 items-center">
          Contrat : <Number :value="dailyGame.contract_score" color="blue" /> pts pour gagner <Number :value="dailyGame.contract_points" color="green" /> <img class="size-4" src="/gfx/iconKadoPoints.gif" alt="icone points Kado" />
        </div>
        <div v-if="!dailyGameStore.isScoresLoading" class="flex gap-1 items-center">
          Nombre de parties restantes : <Number :value="dailyGameStore.position === null ? 1 : 0" color="orange" /> <img class="size-4" src="/gfx/iconGemOrange.gif" alt="icone gemme orange" />
        </div>
        <div v-if="dailyGameStore.position !== null" class="flex gap-1 items-center">
          Votre position actuelle : <Number :value="dailyGameStore.position" color="green" />
        </div>
      </div>
    </RouterLink>
  </div>
</template>

<style scoped>
div.gameOfTheDay {
    width: 700px;
}

.__bg {
    background: url("/gfx/gameBoxDay.png") no-repeat;
}
</style>
