<script setup>
// "Membres": the ranking of the members during the period: 1 point by mission step, the points of their successful
// attacks and defenses
import { t } from '@/i18n'

const props = defineProps({
  clan: { type: Object, required: true },
})

const route = useRoute()
const router = useRouter()
const { fetchMembers, setStatus, isLoading, error } = useClans()
const members = ref([])

const load = () => fetchMembers(props.clan.id).then((data) => {
  members.value = data.data
})
watchEffect(load)
// the members, their points (steps, attacks, defenses): at once
onClanUpdated(() => props.clan.id, ['members', 'status', 'missions'], load)

const sorts = {
  names: (a, b) => a.user.display_name.localeCompare(b.user.display_name),
  points: (a, b) => b.points - a.points,
  performances: (a, b) => b.performance - a.performance,
  attacks: (a, b) => b.attacks_won - a.attacks_won,
  defenses: (a, b) => b.defenses_won - a.defenses_won,
  missions: (a, b) => b.mission_steps - a.mission_steps,
}
const sort = computed(() => (sorts[route.query.sort] ? route.query.sort : 'points'))
const roleLabels = computed(() => ({ right_hand: t('clan_members.right_hand') }))
const combatRoleLabels = computed(() => ({ attacker: t('clan_members.attacker'), defender: t('clan_members.defender') }))
const sorted = computed(() => [...members.value].sort(sorts[sort.value]))
const sortBy = (key) => router.replace({ query: { ...route.query, sort: key } })

// the totals of the clan
const total = (key) => members.value.reduce((sum, m) => sum + m[key], 0)

// the statuses ("dispo le soir"...), seen by the clan only: his own, or anyone's for the leader and the right hands
const showStatus = computed(() => props.clan.viewer.is_member)
const editing = ref(null)
const draft = ref('')
const editStatus = (m) => {
  editing.value = m.user.etwin_id
  draft.value = m.status ?? ''
}
const saveStatus = (m) => setStatus(props.clan.id, m.user.etwin_id, draft.value).then(() => {
  editing.value = null
  return load()
})
</script>

<template>
  <div class="relative space-y-4">
    <MessageError v-if="error">{{ error }}</MessageError>
    <Loader v-if="isLoading && !members.length" />
    <p>{{ $t('clan_members.count', { count: members.length }, members.length) }}</p>

    <div class="overflow-x-auto">
      <KadoTable class="w-full">
        <thead>
          <tr class="text-[10px] uppercase">
            <th class="min-w-28 cursor-pointer text-right" @click="sortBy('names')">{{ $t('common.player') }}</th>
            <th class="cursor-pointer" :title="$t('clan_members.points_title')" @click="sortBy('points')">
              {{ $t('clan_members.points') }}
            </th>
            <th class="cursor-pointer" :title="$t('clan_members.performance_title')" @click="sortBy('performances')">
              <img src="/assets/img/gfx/icons/clan_points.gif" :alt="$t('clan_members.performance')" class="h-5" />
            </th>
            <th class="cursor-pointer" :title="$t('clan_members.missions_title')" @click="sortBy('missions')">
              <img src="/assets/img/gfx/icons/sgame.gif" :alt="$t('clan_members.missions')" class="h-5" />
            </th>
            <th class="cursor-pointer" :title="$t('clan_members.attacks_title')" @click="sortBy('attacks')">
              <img src="/assets/img/gfx/icons/atk.gif" :alt="$t('clan_members.attacks')" class="h-5" />
            </th>
            <th class="cursor-pointer" :title="$t('clan_members.defenses_title')" @click="sortBy('defenses')">
              <img src="/assets/img/gfx/icons/def.gif" :alt="$t('clan_members.defenses')" class="h-5" />
            </th>
            <th v-if="showStatus" class="min-w-40 text-left" :title="$t('clan_members.status_title')">{{ $t('clan_members.status') }}</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="(m, index) in sorted" :key="m.user.etwin_id" :class="index % 2 ? 'bg-white' : 'bg-kado-blue-100'">
            <td class="text-right small-caps">
              <img v-if="m.is_leader"
                   src="/gfx/clan/clanleader.gif"
                   :alt="$t('clan_members.leader')"
                   :title="$t('clan_members.leader')"
                   class="mr-1" />
              <RouterLink :to="{ name: 'profile.show', params: { id: m.user.etwin_id } }">{{ m.user.display_name }}</RouterLink>
              <span v-if="roleLabels[m.role] || combatRoleLabels[m.combat_role]" class="ml-1 text-[10px] [font-variant:normal]">
                ({{ [roleLabels[m.role], combatRoleLabels[m.combat_role]].filter(Boolean).join(', ') }})
              </span>
            </td>
            <td class="text-right font-bold"><Number :value="m.points" color="blue" /></td>
            <td class="text-right"><Number :value="m.performance" color="orange" /></td>
            <td class="text-right"><Number :value="m.mission_steps" color="green" /></td>
            <td class="text-right" :title="$t('clan_members.won_out_of', { won: m.attacks_won, total: m.attacks })"><Number :value="m.attacks_won" color="pink" /></td>
            <td class="text-right" :title="$t('clan_members.won_out_of', { won: m.defenses_won, total: m.defenses })"><Number :value="m.defenses_won" color="blue" /></td>
            <td v-if="showStatus" class="text-left text-xs">
              <form v-if="editing === m.user.etwin_id" class="flex items-center gap-1" @submit.prevent="saveStatus(m)">
                <FormInput v-model="draft"
                           maxlength="60"
                           :placeholder="$t('clan_members.status_placeholder')"
                           class="w-full min-w-0"
                           @keydown.esc="editing = null" />
                <FormButton type="submit" size="sm">{{ $t('clan_members.ok') }}</FormButton>
                <FormButton variant="pink" size="sm" @click="editing = null">{{ $t('common.cancel') }}</FormButton>
              </form>
              <template v-else>
                <span class="break-words">{{ m.status }}</span>
                <a v-if="m.can_edit_status"
                   href="#"
                   class="ml-1 text-kado-orange-500"
                   @click.prevent="editStatus(m)">{{ $t('common.edit') }}</a>
              </template>
            </td>
          </tr>
        </tbody>
        <tfoot v-if="members.length > 1">
          <tr class="border-t-2 border-solid border-kado-teal-500 font-bold">
            <td class="text-right small-caps">{{ $t('clan_members.total') }}</td>
            <td class="text-right"><Number :value="total('points')" color="blue" /></td>
            <td class="text-right"><Number :value="total('performance')" color="orange" /></td>
            <td class="text-right"><Number :value="total('mission_steps')" color="green" /></td>
            <td class="text-right" :title="$t('clan_members.won_out_of', { won: total('attacks_won'), total: total('attacks') })"><Number :value="total('attacks_won')" color="pink" /></td>
            <td class="text-right" :title="$t('clan_members.won_out_of', { won: total('defenses_won'), total: total('defenses') })"><Number :value="total('defenses_won')" color="blue" /></td>
            <td v-if="showStatus" />
          </tr>
        </tfoot>
      </KadoTable>
    </div>
  </div>
</template>
