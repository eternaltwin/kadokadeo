<script setup>
// "Gestion" (the leader and the right hands): the presentation of the clan, the applications, the roles of the members.
// Only the leader names a new leader and disbands the clan.
import { t } from '@/i18n'

const props = defineProps({
  clan: { type: Object, required: true },
})
const emit = defineEmits(['updated'])

const router = useRouter()
const authStore = useAuthStore()
const clanStore = useClanStore()
const { updateClan, fetchApplications, acceptApplication, refuseApplication, fetchMembers, kick, promote, setRole, setCombatRole, dissolve, error } = useClans()

const isLeader = computed(() => props.clan.viewer.is_leader)
const description = ref(props.clan.description ?? '')
const isRecruiting = ref(props.clan.is_recruiting)
const saved = ref(false)
const applications = ref([])
const members = ref([])
// the seats of "Attaquant" and "Défenseur": { attacker: { label, description, count }, ... }
const seats = ref({})

const loadApplications = () => fetchApplications(props.clan.id).then((data) => {
  applications.value = data.data
})
const loadMembers = () => fetchMembers(props.clan.id).then((data) => {
  members.value = data.data
  seats.value = data.seats
})
loadApplications()
loadMembers()
// a new application, answered by another manager, the members changed: at once
onClanUpdated(() => props.clan.id, ['members'], () => {
  loadApplications()
  loadMembers()
})

const taken = (role) => members.value.filter((m) => m.combat_role === role).length

const save = () =>
  updateClan(props.clan.id, { description: description.value, is_recruiting: isRecruiting.value }).then(() => {
    saved.value = true
    emit('updated')
  })
// the application being accepted or refused: its buttons disabled until the list is loaded again
const deciding = ref(null)
const decide = (application, request) => {
  if (deciding.value) {
    return Promise.resolve()
  }
  deciding.value = application.id
  return request(application.id).then(loadApplications).catch(() => {}).finally(() => {
    deciding.value = null
  })
}
const accept = (application) => decide(application, acceptApplication).then(() => {
  loadMembers()
  emit('updated')
})
const refuse = (application) => decide(application, refuseApplication)
const doKick = (member) => {
  if (confirm(t('clan_manage.confirm_kick', { player: member.user.display_name }))) {
    kick(props.clan.id, member.user.etwin_id).then(() => {
      loadMembers()
      emit('updated')
    })
  }
}
const doPromote = (member) => {
  if (confirm(t('clan_manage.confirm_promote', { player: member.user.display_name }))) {
    promote(props.clan.id, member.user.etwin_id).then(() => {
      clanStore.reload()
      emit('updated')
    })
  }
}
const changeRole = (member, role) => setRole(props.clan.id, member.user.etwin_id, role).finally(loadMembers)
const changeCombatRole = (member, role) => setCombatRole(props.clan.id, member.user.etwin_id, role || null).finally(loadMembers)
const doDissolve = () => {
  if (confirm(t('clan_manage.confirm_dissolve', { clan: props.clan.name }))) {
    dissolve(props.clan.id).then(() => {
      clanStore.reload()
      router.push({ name: 'clans.index' })
    })
  }
}
</script>

<template>
  <div class="space-y-4">
    <MessageError v-if="error">{{ error }}</MessageError>

    <KadoSectionTitle>{{ $t('clan_manage.applications') }}</KadoSectionTitle>
    <p v-if="!applications.length" class="italic">{{ $t('clan_manage.no_applications') }}</p>
    <div v-else class="overflow-x-auto">
      <KadoTable class="w-full">
        <tbody>
          <tr v-for="(application, index) in applications" :key="application.id" :class="index % 2 ? 'bg-white' : 'bg-kado-blue-100'">
            <td class="min-w-28 text-left">
              <RouterLink :to="{ name: 'profile.show', params: { id: application.user.etwin_id } }" class="font-bold">{{ application.user.display_name }}</RouterLink>
              <div v-if="application.message" class="text-sm italic whitespace-pre-line">{{ application.message }}</div>
            </td>
            <td class="whitespace-nowrap">
              <FormButton :disabled="deciding !== null" @click="accept(application)">{{ $t('clan_manage.accept') }}</FormButton>
              <FormButton variant="pink"
                          class="ml-1"
                          :disabled="deciding !== null"
                          @click="refuse(application)">{{ $t('clan_manage.refuse') }}</FormButton>
            </td>
          </tr>
        </tbody>
      </KadoTable>
    </div>

    <KadoSectionTitle>{{ $t('clan_manage.presentation') }}</KadoSectionTitle>
    <form @submit.prevent="save">
      <FormTextarea v-model="description" rows="10" maxlength="5000" />
      <i18n-t keypath="clan_manage.markdown" tag="p" class="mx-0 mt-1 mb-2 text-xs text-kado-blue-800">
        <template #title><code>{{ $t('clan_manage.markdown_title') }}</code></template>
        <template #subtitle><code>{{ $t('clan_manage.markdown_subtitle') }}</code></template>
        <template #small_title><code>{{ $t('clan_manage.markdown_small_title') }}</code></template>
        <template #list><code>{{ $t('clan_manage.markdown_list') }}</code></template>
        <template #numbered_list><code>{{ $t('clan_manage.markdown_numbered_list') }}</code></template>
        <template #bold><code>{{ $t('clan_manage.markdown_bold') }}</code></template>
        <template #italic><code>{{ $t('clan_manage.markdown_italic') }}</code></template>
        <template #link><code>{{ $t('clan_manage.markdown_link') }}</code></template>
        <template #image><code>{{ $t('clan_manage.markdown_image') }}</code></template>
      </i18n-t>
      <label class="flex items-center gap-2 font-bold">
        <input v-model="isRecruiting" type="checkbox" />
        {{ $t('clan_manage.recruiting') }}
      </label>
      <MessageSuccess v-if="saved">{{ $t('clan_manage.saved') }}</MessageSuccess>
      <FormButton type="submit" size="lg">{{ $t('common.save') }}</FormButton>
    </form>

    <KadoSectionTitle>{{ $t('clan_manage.members') }}</KadoSectionTitle>
    <p class="text-sm">
      <i18n-t keypath="clan_manage.right_hand_help" tag="span">
        <template #right_hand><strong>{{ $t('clan_manage.right_hand_help_strong') }}</strong></template>
      </i18n-t>
      <template v-for="(seat, role) in seats" :key="role">
        <br /><strong>{{ seat.label }}</strong> {{ $t('clan_manage.seat', { taken: taken(role), count: seat.count, description: seat.description }) }}
      </template>
    </p>
    <div class="overflow-x-auto">
      <KadoTable class="w-full">
        <tbody>
          <tr v-for="(m, index) in members" :key="m.user.etwin_id" :class="index % 2 ? 'bg-white' : 'bg-kado-blue-100'">
            <td class="min-w-28 text-left small-caps">
              <img v-if="m.is_leader"
                   src="/gfx/clan/clanleader.gif"
                   :alt="$t('clan_manage.leader_icon')"
                   :title="$t('clan_manage.leader_icon')"
                   class="mr-1" />
              {{ m.user.display_name }}
            </td>
            <td class="whitespace-nowrap">
              <template v-if="m.is_leader">{{ $t('clan_manage.leader') }}</template>
              <FormSelect v-else
                          :model-value="m.role"
                          :title="$t('clan_manage.role')"
                          @update:model-value="changeRole(m, $event)">
                <option value="member">{{ $t('clan_manage.role_member') }}</option>
                <option value="right_hand">{{ $t('clan_manage.role_right_hand') }}</option>
              </FormSelect>
            </td>
            <td class="whitespace-nowrap">
              <FormSelect :model-value="m.combat_role ?? ''"
                          :disabled="m.combat_role_locked"
                          :title="m.combat_role_locked ? $t('clan_manage.seat_locked') : $t('clan_manage.seat_title')"
                          @update:model-value="changeCombatRole(m, $event)">
                <option value="">{{ $t('clan_manage.no_seat') }}</option>
                <option v-for="(seat, role) in seats"
                        :key="role"
                        :value="role"
                        :disabled="m.combat_role !== role && taken(role) >= seat.count">{{ seat.label }}</option>
              </FormSelect>
            </td>
            <td class="whitespace-nowrap">
              <template v-if="m.user.etwin_id !== authStore.user?.etwin_id && !m.is_leader">
                <FormButton v-if="isLeader" @click="doPromote(m)">{{ $t('clan_manage.promote') }}</FormButton>
                <FormButton v-if="!m.is_new"
                            variant="pink"
                            class="ml-1"
                            @click="doKick(m)">{{ $t('clan_manage.kick') }}</FormButton>
                <span v-else class="ml-1 text-xs italic" :title="$t('clan_manage.new_member_title')">{{ $t('clan_manage.new_member') }}</span>
              </template>
            </td>
          </tr>
        </tbody>
      </KadoTable>
    </div>

    <template v-if="isLeader">
      <KadoSectionTitle>{{ $t('clan_manage.dissolve') }}</KadoSectionTitle>
      <p class="text-sm">{{ $t('clan_manage.dissolve_help') }}</p>
      <FormButton variant="pink" @click="doDissolve">{{ $t('clan_manage.dissolve') }}</FormButton>
    </template>
  </div>
</template>
