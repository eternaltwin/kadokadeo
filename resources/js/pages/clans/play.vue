<script setup>
// a clan run: an attack, a defense or a mission step. The next run of the game is bound to it on the server.
const route = useRoute()
const clanStore = useClanStore()
const { fetchAction, error } = useClans()
const { fetchGame } = useGames()

const action = ref(null)
const game = ref(null)
const result = ref(null)

fetchAction(route.params.action).then((data) => {
  action.value = data.data
  if (action.value.is_open) {
    fetchGame(action.value.game_id).then((gameData) => {
      game.value = gameData.data
    })
  }
})

const onGameFinished = (e) => {
  if (e.detail?.clan) {
    result.value = e.detail.clan
    clanStore.reload()
  }
}
onMounted(() => window.evts.addEventListener('gameFinished', onGameFinished))
onUnmounted(() => window.evts.removeEventListener('gameFinished', onGameFinished))

const backRoute = computed(() => {
  const id = action.value?.clan.id
  return action.value?.type === 'mission'
    ? { name: 'clans.missions', params: { id } }
    : { name: 'clans.status', params: { id } }
})
const isSuccess = computed(() => ['launched', 'repelled', 'completed'].includes(result.value?.result))
</script>

<template>
  <div class="relative min-h-48 px-2">
    <MessageError v-if="error">{{ error }}</MessageError>
    <Loader v-else-if="!action">Chargement ...</Loader>

    <template v-else>
      <h1 class="mt-0 text-center">{{ action.type_label }}</h1>

      <div class="flex items-center gap-2 border-l-4 px-2 py-1" :class="action.type === 'attack' ? 'border-[#ff6b9c] bg-[#ffe3ec] text-[#ff6b9c]' : 'border-kado-cyan-800 bg-kado-cyan-100'">
        <img :src="action.type === 'attack' ? '/assets/img/gfx/icons/atk.gif' : action.type === 'defense' ? '/assets/img/gfx/icons/def.gif' : '/assets/img/gfx/icons/clan_points.gif'" alt="" />
        <div>
          <template v-if="action.type === 'attack'">
            Votre score deviendra une attaque du clan <strong>{{ action.clan.name }}</strong> contre le clan
            <strong>{{ action.target.clan.name }}</strong>. Faites le meilleur score possible !
          </template>
          <template v-else-if="action.type === 'defense'">
            Battez le score de <strong>{{ action.target.score }} pts</strong> de {{ action.target.attacker }}
            (clan {{ action.target.clan.name }}) pour repousser son attaque.
            <template v-if="action.bonus"> Option <strong>{{ action.bonus }}</strong> : votre score comptera pour 120%.</template>
          </template>
          <template v-else>
            Mission {{ action.target.mission }} : atteignez <strong>{{ action.target.score }} pts</strong> pour réussir cette étape.
          </template>
        </div>
      </div>

      <template v-if="result">
        <MessageSuccess v-if="isSuccess">{{ result.message }}</MessageSuccess>
        <MessageError v-else>{{ result.message }}</MessageError>
      </template>
      <p class="text-center">
        <RouterLink :to="backRoute">Retour à la page du clan</RouterLink>
      </p>

      <MessageError v-if="!action.is_open && !result">
        Cette action de clan est terminée ou a expiré. Retournez sur la page de votre clan pour en lancer une nouvelle.
      </MessageError>
      <div v-else-if="!game && !result" class="relative min-h-48">
        <Loader>Chargement du jeu ...</Loader>
      </div>
      <div v-else-if="game" class="relative mx-auto max-w-[600px]">
        <h2>{{ game.name }}</h2>
        <GamesGameScript :game="game" />
      </div>
    </template>
  </div>
</template>
