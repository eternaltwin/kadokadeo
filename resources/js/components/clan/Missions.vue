<script setup>
// "Mission": the mission in progress (a score to reach on several games), the previous ones and the options of the clan
const props = defineProps({
  clan: { type: Object, required: true },
})

const router = useRouter()
const { fetchMissions, fetchMembers, playStep, useBonus, assignBonus, isLoading, error } = useClans()
const { fetchGames } = useGames()
const data = ref(null)
const tournament = ref(null)
const members = ref([])
const games = ref([])
const selectedBonus = ref(null)
const bonusGame = ref(null)
const bonusStep = ref(null)
const bonusMember = ref(null)
const isLeader = computed(() => props.clan.viewer.is_leader)

const load = () =>
  fetchMissions(props.clan.id).then((response) => {
    data.value = response.data
    tournament.value = response.tournament
  })
watchEffect(load)
if (props.clan.viewer.is_leader) {
  fetchMembers(props.clan.id).then((response) => {
    members.value = response.data
  })
  fetchGames().then((response) => {
    games.value = response.data.filter((game) => !game.is_arkadeo)
  })
}

const mission = computed(() => data.value?.mission)
const statusLabels = { completed: 'Réussie', failed: 'Échouée', skipped: 'Passée' }

const play = (step) => playStep(step.id).then((response) => router.push({ name: 'clans.play', params: { action: response.data.id } }))

const openBonus = (bonus) => {
  selectedBonus.value = bonus
  bonusGame.value = null
  bonusStep.value = null
  bonusMember.value = bonus.assigned_user?.etwin_id ?? null
}
const confirmBonus = () => {
  const bonus = selectedBonus.value
  const request = bonus.assignable
    ? assignBonus(bonus.id, bonusMember.value)
    : useBonus(bonus.id, { game_id: bonusGame.value ?? undefined, step_id: bonusStep.value ?? undefined })
  request.then(() => {
    selectedBonus.value = null
    load()
  })
}
</script>

<template>
  <div class="relative space-y-4">
    <ClanPeriodBanner :tournament="tournament" />
    <MessageError v-if="error">{{ error }}</MessageError>
    <Loader v-if="isLoading && !data" />

    <template v-if="data">
      <p class="mx-0">
        Score de mission du clan : <Number :value="data.mission_score" color="orange" />
        ({{ data.missions_completed }} mission(s) réussie(s))
      </p>

      <template v-if="mission">
        <h2 class="normal-case">
          Mission {{ mission.number }}
          <span v-if="mission.double_points" class="text-[#ff6b9c]">x2</span>
        </h2>
        <p class="mx-0">
          Chaque étape réussie rapporte des points à votre clan. Réussissez toutes les étapes avant la fin du temps
          imparti (<ClanCountdown :until="mission.expires_at" class="font-bold" @done="load" />) pour doubler vos points
          (<Number :value="mission.max_points" color="orange" /> points), sinon vous perdrez les points de la mission !
          Points déjà gagnés : <Number :value="mission.points" color="orange" />.
        </p>
        <div class="overflow-x-auto">
          <table class="w-full">
            <thead>
              <tr class="text-[10px] uppercase">
                <th>Jeu</th>
                <th>Score à atteindre</th>
                <th>Points</th>
                <th>Étape</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(step, index) in mission.steps" :key="step.id" :class="index % 2 ? 'oddfalse' : 'oddtrue'">
                <td class="text-left font-bold">
                  <RouterLink :to="{ name: 'games.show', params: { id: step.game.id } }">{{ step.game.name }}</RouterLink>
                </td>
                <td class="font-bold">{{ step.target_score }} pts</td>
                <td><Number :value="step.points" color="green" /></td>
                <td>
                  <template v-if="step.skipped">Étape passée</template>
                  <template v-else-if="step.done">
                    <img src="/gfx/clan/clan_home.gif" alt="" class="h-4" />
                    Réussie par {{ step.completed_by?.display_name }} ({{ step.score }})
                  </template>
                  <button v-else
                          type="button"
                          class="clanButton"
                          @click="play(step)">Jouer</button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </template>
      <p v-else class="italic mx-0">
        Aucune mission en cours : une nouvelle mission sera proposée à la prochaine période.
      </p>

      <p v-if="data.next_mission_double || data.banned_game || data.forced_game" class="text-sm mx-0">
        <span v-if="data.next_mission_double">La prochaine mission rapportera deux fois plus de points. </span>
        <span v-if="data.banned_game">Jeu caca : <strong>{{ data.banned_game.name }}</strong>. </span>
        <span v-if="data.forced_game">Jeu cool : <strong>{{ data.forced_game.name }}</strong>.</span>
      </p>

      <h2 class="normal-case">Options du clan</h2>
      <p v-if="!data.bonuses.length" class="italic mx-0">
        Votre clan n'a aucune option. Plus vous réussissez de missions, plus vous avez de chances d'en remporter !
      </p>
      <div class="relative flex flex-wrap gap-2">
        <div v-for="bonus in data.bonuses" :key="bonus.id" class="optClan text-center w-[81px]">
          <button type="button"
                  class="border-0 bg-transparent p-0.5 hover:p-0 hover:border-2 hover:border-solid hover:border-[#ffffaf] hover:bg-[#ff9a00] cursor-pointer"
                  :title="bonus.label"
                  @click="openBonus(bonus)">
            <img :src="bonus.icon" :alt="bonus.label" class="w-[77px] h-[68px]" />
          </button>
          <div class="text-[10px] leading-tight">
            {{ bonus.label }}
            <template v-if="bonus.assigned_user"><br />({{ bonus.assigned_user.display_name }})</template>
          </div>
        </div>

        <div v-if="selectedBonus" id="optPopup" class="absolute z-20 left-5 -top-6 w-[470px] max-w-full min-h-[150px] border-2 border-solid border-[#1d2024] bg-[#3d4045] text-[#f0feff]">
          <h3 class="m-0 h-[35px] bg-[#1d2024] px-2 text-[26px] leading-[35px] text-[#f0feff]">{{ selectedBonus.label }}</h3>
          <img :src="selectedBonus.icon" :alt="selectedBonus.label" class="float-left py-0.5 pr-2.5 pl-0.5" />
          <p class="m-1 text-xs">{{ selectedBonus.description }}</p>

          <template v-if="!isLeader">
            <p class="m-1 text-xs italic">C'est le chef de clan qui décide de l'utilisation des options.</p>
          </template>
          <template v-else-if="selectedBonus.assignable">
            <p class="m-1 text-xs">Donnez cette option à un joueur : il pourra l'utiliser quand il le voudra pour attaquer ou défendre, jusqu'à la fin de la période.</p>
            <select v-model="bonusMember" class="m-1 text-kado-blue bg-white">
              <option :value="null" disabled>Choisir un joueur</option>
              <option v-for="m in members" :key="m.user.etwin_id" :value="m.user.etwin_id">{{ m.user.display_name }}</option>
            </select>
          </template>
          <template v-else>
            <select v-if="['ban_game', 'force_game'].includes(selectedBonus.type)" v-model="bonusGame" class="m-1 text-kado-blue bg-white">
              <option :value="null" disabled>Choisir un jeu</option>
              <option v-for="g in games" :key="g.id" :value="g.id">{{ g.name }}</option>
            </select>
            <select v-if="selectedBonus.type === 'skip_step'" v-model="bonusStep" class="m-1 text-kado-blue bg-white">
              <option :value="null" disabled>Choisir une étape</option>
              <option v-for="s in (mission?.steps ?? []).filter((s) => !s.done)" :key="s.id" :value="s.id">{{ s.game.name }} ({{ s.target_score }})</option>
            </select>
          </template>

          <div class="clear-both flex justify-end gap-2 p-1">
            <button v-if="isLeader"
                    type="button"
                    class="clanButton"
                    @click="confirmBonus">
              {{ selectedBonus.assignable ? 'Donner' : 'Utiliser' }}
            </button>
            <button type="button" class="clanButton pink" @click="selectedBonus = null">Fermer</button>
          </div>
        </div>
      </div>

      <template v-if="data.missions.length">
        <h2 class="normal-case">Missions de la période</h2>
        <ul class="list-inside list-image-[url(/gfx/puce.jpg)] ml-4 space-y-1">
          <li v-for="m in data.missions" :key="m.id">
            Mission {{ m.number }} : {{ statusLabels[m.status] ?? m.status }}
            <template v-if="m.status === 'completed'">(+{{ m.points }} points)</template>
            <template v-else-if="m.status === 'failed' && m.points > 0">({{ m.points }} points perdus)</template>
          </li>
        </ul>
      </template>
    </template>
  </div>
</template>
