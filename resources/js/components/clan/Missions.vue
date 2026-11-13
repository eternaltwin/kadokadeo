<script setup>
// "Mission": the mission in progress (a score to reach on several games), the previous ones and the options of the clan.
// Another clan sees the missions only: no buttons, no reservations, no options (the API does not give them)
import { t } from '@/i18n'

const props = defineProps({
  clan: { type: Object, required: true },
})

const router = useRouter()
const { fetchMissions, playStep, reserveStep, useBonus, isLoading, error } = useClans()
const { fetchGames } = useGames()
const data = ref(null)
const tournament = ref(null)
const games = ref([])
const selectedBonus = ref(null)
const bonusGame = ref(null)
// a game is in the "Jeux caca" or in the "Jeux cool", once: it can't be chosen again
const gameTag = (id) => {
  if (data.value?.banned_games?.some((g) => g.id === id)) {
    return t('clan_missions.tag_banned')
  }
  return data.value?.forced_games?.some((g) => g.id === id) ? t('clan_missions.tag_forced') : null
}
const gameNames = (list) => list.map((g) => g.name).join(', ')
const bonusStep = ref(null)
// the leader and the right hands use the options
const canManage = computed(() => props.clan.viewer.can_manage)
const isMember = computed(() => props.clan.viewer.is_member)

const load = () =>
  fetchMissions(props.clan.id).then((response) => {
    data.value = response.data
    tournament.value = response.tournament
  })
watchEffect(load)
// a step done, reserved, an option used, the mission over (by any member): at once
onClanUpdated(() => props.clan.id, ['missions'], load)
if (props.clan.viewer.can_manage) {
  fetchGames().then((response) => {
    games.value = response.data.filter((game) => !game.is_arkadeo)
  })
}

const mission = computed(() => data.value?.mission)
// the star of the score to reach of a step (-1: under the green star), a "+" above the red one
const stars = computed(() => ({
  '-1': { img: '/gfx/iconGreyStar.gif', alt: t('clan_missions.star_below_green') },
  0: { img: '/gfx/iconGreenStar.gif', alt: t('clan_missions.star_green') },
  1: { img: '/gfx/iconOrangeStar.gif', alt: t('clan_missions.star_orange') },
  2: { img: '/gfx/iconRedStar.gif', alt: t('clan_missions.star_red') },
}))
const statusLabels = computed(() => ({
  completed: t('clan_missions.status_completed'),
  failed: t('clan_missions.status_failed'),
  skipped: t('clan_missions.status_skipped'),
}))
// the options of the same kind shown once with their count ("x3"): the first one is used
const stackedBonuses = computed(() => {
  const byType = new Map()
  for (const bonus of data.value?.bonuses ?? []) {
    const stack = byType.get(bonus.type)
    if (stack) {
      stack.count++
    } else {
      byType.set(bonus.type, { ...bonus, count: 1 })
    }
  }
  return [...byType.values()]
})

// "Je m'en occupe": reserve the step, take the place of another member, or give it up
const reserve = (step) => reserveStep(step.id).then(load)
const reserveLabel = (step) => (step.reserved_by_me ? t('clan_missions.release') : step.reserved_by ? t('clan_missions.take') : t('clan_missions.reserve'))
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
      <i18n-t keypath="clan_missions.score" tag="p" :plural="data.missions_completed">
        <template #score><Number :value="data.mission_score" color="violet" /></template>
        <template #count>{{ data.missions_completed }}</template>
      </i18n-t>

      <template v-if="mission">
        <KadoSectionTitle>{{ $t('clan_missions.mission', { number: mission.number }) }}</KadoSectionTitle>
        <i18n-t v-if="isMember" keypath="clan_missions.rules_member" tag="p">
          <template #countdown><ClanCountdown :until="mission.expires_at" class="font-bold" @done="load" /></template>
          <template #reward><Number :value="mission.reward" color="violet" /></template>
          <template #double><template v-if="mission.double_points">
            (<img src="/gfx/clan/opt/optDoublePoints.gif" alt="" class="inline h-4 align-middle" /> {{ $t('clan_missions.double_points') }})</template></template>
          <template #next><strong>{{ formatMinutes(mission.next_minutes) }}</strong></template>
        </i18n-t>
        <i18n-t v-else keypath="clan_missions.rules_other" tag="p">
          <template #countdown><ClanCountdown :until="mission.expires_at" class="font-bold" @done="load" /></template>
          <template #reward><Number :value="mission.reward" color="violet" /></template>
          <template #double><template v-if="mission.double_points">
            (<img src="/gfx/clan/opt/optDoublePoints.gif" alt="" class="inline h-4 align-middle" /> {{ $t('clan_missions.double_points') }})</template></template>
          <template #next><strong>{{ formatMinutes(mission.next_minutes) }}</strong></template>
        </i18n-t>
        <p v-if="data.double_points_pending" class="flex items-center gap-1">
          <img src="/gfx/clan/opt/optDoublePoints.gif" alt="" class="h-5" />
          <i18n-t keypath="clan_missions.double_pending" tag="span">
            <template #double><strong>{{ $t('clan_missions.double_points') }}</strong></template>
          </i18n-t>
        </p>
        <div class="overflow-x-auto">
          <KadoTable class="w-full">
            <thead>
              <tr class="text-2xs uppercase">
                <th class="min-w-24">{{ $t('common.game') }}</th>
                <th>{{ $t('clan_missions.target_score') }}</th>
                <th>{{ $t('clan_missions.step') }}</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(step, index) in mission.steps" :key="step.id" :class="index % 2 ? 'bg-white' : 'bg-kado-blue-100'">
                <td class="text-left font-bold">
                  <RouterLink :to="{ name: 'games.show', params: { id: step.game.id } }">{{ step.game.name }}</RouterLink>
                </td>
                <td class="font-bold whitespace-nowrap">
                  <span class="inline-flex items-center gap-1">
                    <span v-if="stars[step.star]"
                          class="inline-flex items-center"
                          :title="step.beyond_last_star ? $t('clan_missions.star_beyond_red') : stars[step.star].alt">
                      <img :src="stars[step.star].img" :alt="stars[step.star].alt" />
                      <img v-if="step.beyond_last_star"
                           src="/gfx/typo/pink/plus.svg"
                           alt="+"
                           class="h-2.5" />
                    </span>
                    <Number color="blue" :value="step.target_score" />
                  </span>
                </td>
                <td>
                  <template v-if="step.skipped">{{ $t('clan_missions.step_skipped') }}</template>
                  <template v-else-if="step.done">
                    <img src="/gfx/clan/clan_home.gif" alt="" class="h-4" />
                    <i18n-t keypath="clan_missions.step_done_by" tag="span">
                      <template #player>{{ step.completed_by?.display_name }}</template>
                      <template #score><Number :value="step.score" color="blue" /></template>
                    </i18n-t>
                  </template>
                  <span v-else-if="!isMember" class="italic">{{ $t('clan_missions.step_to_do') }}</span>
                  <div v-else class="flex flex-wrap items-center justify-center gap-1">
                    <FormButton @click="play(step)">{{ $t('clan_missions.play') }}</FormButton>
                    <FormButton :variant="step.reserved_by_me ? 'pink' : 'green'"
                                :title="$t('clan_missions.reserve_title')"
                                @click="reserve(step)">{{ reserveLabel(step) }}</FormButton>
                    <span v-if="step.reserved_by" class="w-full text-xs italic">{{ $t('clan_missions.reserved_by', { player: step.reserved_by.display_name }) }}</span>
                  </div>
                </td>
              </tr>
            </tbody>
          </KadoTable>
        </div>
      </template>
      <p v-else class="italic">
        {{ $t('clan_missions.no_mission') }}
      </p>

      <p v-if="isMember && (data.banned_games.length || data.forced_games.length)" class="text-sm">
        <i18n-t v-if="data.banned_games.length"
                keypath="clan_missions.banned_games"
                tag="span"
                :plural="data.banned_games.length">
          <template #games><strong>{{ gameNames(data.banned_games) }}</strong></template>
        </i18n-t>
        <i18n-t v-if="data.forced_games.length"
                keypath="clan_missions.forced_games"
                tag="span"
                :plural="data.forced_games.length">
          <template #games><strong>{{ gameNames(data.forced_games) }}</strong></template>
        </i18n-t>
      </p>

      <KadoSectionTitle v-if="isMember">{{ $t('clan_missions.options') }}</KadoSectionTitle>
      <p v-if="isMember && !data.bonuses.length" class="italic">
        {{ $t('clan_missions.no_options') }}
      </p>
      <div v-if="isMember" class="relative flex flex-wrap gap-2">
        <div v-for="bonus in stackedBonuses" :key="bonus.type" class="relative w-[81px] text-center">
          <button type="button"
                  class="border-0 bg-transparent p-0.5 hover:p-0 hover:border-2 hover:border-solid hover:border-kado-yellow-100 hover:bg-kado-orange-500 cursor-pointer"
                  :title="bonus.count > 1 ? `${bonus.label} (x${bonus.count})` : bonus.label"
                  @click="openBonus(bonus)">
            <img :src="bonus.icon" :alt="bonus.label" class="w-[77px] h-[68px]" />
          </button>
          <!-- on a white halo fading into the icon -->
          <Number v-if="bonus.count > 1"
                  :value="`x${bonus.count}`"
                  color="bigPink"
                  class="pointer-events-none absolute top-0 right-0 bg-radial-[closest-side] from-white from-55% to-transparent px-[7px] py-1 leading-0" />
          <div class="text-2xs leading-tight">{{ bonus.label }}</div>
        </div>

        <div v-if="selectedBonus" class="absolute z-20 left-5 -top-6 w-[470px] max-w-full min-h-[150px] border-2 border-solid border-twinoid-900 bg-twinoid-600 text-kado-blue-50">
          <h3 class="h-[35px] bg-twinoid-900 px-2 text-[26px] font-semibold leading-[35px] text-kado-blue-50">{{ selectedBonus.label }}</h3>
          <img :src="selectedBonus.icon" :alt="selectedBonus.label" class="float-left py-0.5 pr-2.5 pl-0.5" />
          <p class="m-1 text-xs">{{ selectedBonus.description }}</p>

          <template v-if="!canManage">
            <p class="m-1 text-xs italic">{{ $t('clan_missions.options_managers_only') }}</p>
          </template>
          <template v-else>
            <FormSelect v-if="['ban_game', 'force_game'].includes(selectedBonus.type)" v-model="bonusGame" class="m-1">
              <option :value="null" disabled>{{ $t('clan_missions.choose_game') }}</option>
              <!-- the games already in a list can't be chosen -->
              <option v-for="g in games"
                      :key="g.id"
                      :value="g.id"
                      :disabled="gameTag(g.id) !== null">
                {{ g.name }}<template v-if="gameTag(g.id)"> ({{ gameTag(g.id) }})</template>
              </option>
            </FormSelect>
            <FormSelect v-if="selectedBonus.type === 'skip_step'" v-model="bonusStep" class="m-1">
              <option :value="null" disabled>{{ $t('clan_missions.choose_step') }}</option>
              <option v-for="s in (mission?.steps ?? []).filter((s) => !s.done)" :key="s.id" :value="s.id">{{ s.game.name }} ({{ s.target_score }})</option>
            </FormSelect>
          </template>

          <div class="clear-both flex justify-end gap-2 p-1">
            <FormButton v-if="canManage" @click="confirmBonus">{{ $t('clan_missions.use') }}</FormButton>
            <FormButton variant="pink" @click="selectedBonus = null">{{ $t('common.close') }}</FormButton>
          </div>
        </div>
      </div>

      <template v-if="data.missions.length">
        <KadoSectionTitle>{{ $t('clan_missions.period_missions') }}</KadoSectionTitle>
        <ul class="list-inside list-kado ml-4 space-y-1">
          <li v-for="m in data.missions" :key="m.id">
            {{ $t('clan_missions.mission_status', { number: m.number, status: statusLabels[m.status] ?? m.status }) }}
            <template v-if="m.status === 'completed'">
              <i18n-t keypath="clan_missions.points_double" tag="span">
                <template #points><Number :value="m.points" color="violet" signed /></template>
                <template #double><template v-if="m.double_points">,
                  <img src="/gfx/clan/opt/optDoublePoints.gif"
                       :alt="$t('clan_missions.double_points')"
                       :title="$t('clan_missions.double_points')"
                       class="h-4 align-middle" /></template></template>
              </i18n-t>
              <template v-if="m.bonus">
                — {{ $t('clan_missions.option_won') }}
                <img :src="m.bonus.icon"
                     :alt="m.bonus.label"
                     :title="m.bonus.description"
                     class="h-5 align-middle" />
                <strong>{{ m.bonus.label }}</strong>
                <span v-if="m.bonus.used" class="italic">({{ $t('clan_missions.option_used') }})</span>
              </template>
              <span v-else-if="isMember" class="italic">— {{ $t('clan_missions.no_option_won') }}</span>
            </template>
            <template v-else-if="m.status === 'failed' && m.points < 0"><i18n-t keypath="clan_missions.points" tag="span">
              <template #points><Number :value="m.points" color="violet" signed /></template>
            </i18n-t></template>
          </li>
        </ul>
      </template>
    </template>
  </div>
</template>
