<script setup>
// "Mission": the mission in progress (a score to reach on several games), the previous ones and the options of the clan
const props = defineProps({
  clan: { type: Object, required: true },
})

const router = useRouter()
const { fetchMissions, playStep, useBonus, isLoading, error } = useClans()
const { fetchGames } = useGames()
const data = ref(null)
const tournament = ref(null)
const games = ref([])
const selectedBonus = ref(null)
const bonusGame = ref(null)
const bonusStep = ref(null)
// the leader and the right hands use the options
const canManage = computed(() => props.clan.viewer.can_manage)

const load = () =>
  fetchMissions(props.clan.id).then((response) => {
    data.value = response.data
    tournament.value = response.tournament
  })
watchEffect(load)
if (props.clan.viewer.can_manage) {
  fetchGames().then((response) => {
    games.value = response.data.filter((game) => !game.is_arkadeo)
  })
}

const mission = computed(() => data.value?.mission)
const statusLabels = { completed: 'Réussie', failed: 'Échouée', skipped: 'Remplacée' }

const play = (step) => playStep(step.id).then((response) => router.push({ name: 'clans.play', params: { action: response.data.id } }))

const openBonus = (bonus) => {
  selectedBonus.value = bonus
  bonusGame.value = null
  bonusStep.value = null
}
const confirmBonus = () => {
  const bonus = selectedBonus.value
  useBonus(bonus.id, { game_id: bonusGame.value ?? undefined, step_id: bonusStep.value ?? undefined }).then(() => {
    selectedBonus.value = null
    load()
  })
}
</script>

<template>
  <div class="relative space-y-4">
    <MessageError v-if="error">{{ error }}</MessageError>
    <Loader v-if="isLoading && !data" />

    <template v-if="data">
      <p class="mx-0">
        Score de mission du clan : <Number :value="data.mission_score" color="blue" />
        ({{ data.missions_completed }} mission(s) réussie(s))
      </p>

      <template v-if="mission">
        <h2 class="normal-case">Mission {{ mission.number }}</h2>
        <p class="mx-0">
          Réussissez toutes les étapes avant la fin du temps imparti
          (<ClanCountdown :until="mission.expires_at" class="font-bold" @done="load" />) : votre clan remportera
          <Number :value="mission.reward" color="orange" /> points et passera à la mission suivante. Sinon, il perdra un
          point par étape non réussie, moins une. Les parties des missions sont gratuites !
        </p>
        <div class="overflow-x-auto">
          <table class="w-full">
            <thead>
              <tr class="text-[10px] uppercase">
                <th class="min-w-24">Jeu</th>
                <th>Score à atteindre</th>
                <th>Étape</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(step, index) in mission.steps" :key="step.id" :class="index % 2 ? 'bg-white' : 'bg-kado-cyan-200'">
                <td class="text-left font-bold">
                  <RouterLink :to="{ name: 'games.show', params: { id: step.game.id } }">{{ step.game.name }}</RouterLink>
                </td>
                <td class="font-bold"><Number color="blue" :value="step.target_score" /></td>
                <td>
                  <template v-if="step.skipped">Étape passée</template>
                  <template v-else-if="step.done">
                    <img src="/gfx/clan/clan_home.gif" alt="" class="h-4" />
                    Réussie par {{ step.completed_by?.display_name }} ({{ step.score }})
                  </template>
                  <FormButton v-else @click="play(step)">Jouer</FormButton>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </template>
      <p v-else class="italic mx-0">
        Aucune mission en cours : une nouvelle mission sera proposée à la prochaine période.
      </p>

      <p v-if="data.banned_game || data.forced_game" class="text-sm mx-0">
        <span v-if="data.banned_game">Jeu caca : <strong>{{ data.banned_game.name }}</strong>. </span>
        <span v-if="data.forced_game">Jeu cool : <strong>{{ data.forced_game.name }}</strong>.</span>
      </p>

      <h2 class="normal-case">Options du clan</h2>
      <p v-if="!data.bonuses.length" class="italic mx-0">
        Votre clan n'a aucune option. Chaque mission réussie peut vous en faire gagner une !
      </p>
      <div class="relative flex flex-wrap gap-2">
        <div v-for="bonus in data.bonuses" :key="bonus.id" class="w-[81px] text-center">
          <button type="button"
                  class="border-0 bg-transparent p-0.5 hover:p-0 hover:border-2 hover:border-solid hover:border-[#ffffaf] hover:bg-[#ff9a00] cursor-pointer"
                  :title="bonus.label"
                  @click="openBonus(bonus)">
            <img :src="bonus.icon" :alt="bonus.label" class="w-[77px] h-[68px]" />
          </button>
          <div class="text-[10px] leading-tight">{{ bonus.label }}</div>
        </div>

        <div v-if="selectedBonus" class="absolute z-20 left-5 -top-6 w-[470px] max-w-full min-h-[150px] border-2 border-solid border-[#1d2024] bg-[#3d4045] text-[#f0feff]">
          <h3 class="m-0 h-[35px] bg-[#1d2024] px-2 text-[26px] leading-[35px] text-[#f0feff]">{{ selectedBonus.label }}</h3>
          <img :src="selectedBonus.icon" :alt="selectedBonus.label" class="float-left py-0.5 pr-2.5 pl-0.5" />
          <p class="m-1 text-xs">{{ selectedBonus.description }}</p>

          <template v-if="!canManage">
            <p class="m-1 text-xs italic">C'est le chef de clan ou un bras droit qui décide de l'utilisation des options.</p>
          </template>
          <template v-else>
            <FormSelect v-if="['ban_game', 'force_game'].includes(selectedBonus.type)" v-model="bonusGame" class="m-1">
              <option :value="null" disabled>Choisir un jeu</option>
              <option v-for="g in games" :key="g.id" :value="g.id">{{ g.name }}</option>
            </FormSelect>
            <FormSelect v-if="selectedBonus.type === 'skip_step'" v-model="bonusStep" class="m-1">
              <option :value="null" disabled>Choisir une étape</option>
              <option v-for="s in (mission?.steps ?? []).filter((s) => !s.done)" :key="s.id" :value="s.id">{{ s.game.name }} ({{ s.target_score }})</option>
            </FormSelect>
          </template>

          <div class="clear-both flex justify-end gap-2 p-1">
            <FormButton v-if="canManage" @click="confirmBonus">Utiliser</FormButton>
            <FormButton variant="pink" @click="selectedBonus = null">Fermer</FormButton>
          </div>
        </div>
      </div>

      <template v-if="data.missions.length">
        <h2 class="normal-case">Missions de la période</h2>
        <ul class="list-inside list-image-[url(/gfx/puce.jpg)] ml-4 space-y-1">
          <li v-for="m in data.missions" :key="m.id">
            Mission {{ m.number }} : {{ statusLabels[m.status] ?? m.status }}
            <template v-if="m.status === 'completed'">(+{{ m.points }} points)</template>
            <template v-else-if="m.status === 'failed' && m.points < 0">({{ -m.points }} points perdus)</template>
          </li>
        </ul>
      </template>
    </template>
  </div>
</template>
