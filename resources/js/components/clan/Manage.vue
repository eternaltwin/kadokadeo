<script setup>
// "Gestion" (the leader and the right hands): the presentation of the clan, the applications, the roles of the members.
// Only the leader names a new leader and disbands the clan.
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

const taken = (role) => members.value.filter((m) => m.combat_role === role).length

const save = () =>
  updateClan(props.clan.id, { description: description.value, is_recruiting: isRecruiting.value }).then(() => {
    saved.value = true
    emit('updated')
  })
const accept = (application) => acceptApplication(application.id).then(() => {
  loadApplications()
  loadMembers()
  emit('updated')
})
const refuse = (application) => refuseApplication(application.id).then(loadApplications)
const doKick = (member) => {
  if (confirm(`Exclure ${member.user.display_name} du clan ?`)) {
    kick(props.clan.id, member.user.etwin_id).then(() => {
      loadMembers()
      emit('updated')
    })
  }
}
const doPromote = (member) => {
  if (confirm(`Nommer ${member.user.display_name} chef de clan ? Vous deviendrez son bras droit.`)) {
    promote(props.clan.id, member.user.etwin_id).then(() => {
      clanStore.reload()
      emit('updated')
    })
  }
}
const changeRole = (member, role) => setRole(props.clan.id, member.user.etwin_id, role).finally(loadMembers)
const changeCombatRole = (member, role) => setCombatRole(props.clan.id, member.user.etwin_id, role || null).finally(loadMembers)
const doDissolve = () => {
  if (confirm(`Dissoudre le clan ${props.clan.name} ? Tous ses membres le quitteront et ses scores seront perdus.`)) {
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

    <h2 class="normal-case">Candidatures</h2>
    <p v-if="!applications.length" class="italic mx-0">Aucune candidature en attente.</p>
    <table v-else class="w-full">
      <tbody>
        <tr v-for="(application, index) in applications" :key="application.id" :class="index % 2 ? 'oddfalse' : 'oddtrue'">
          <td class="text-left">
            <RouterLink :to="{ name: 'profile.show', params: { id: application.user.etwin_id } }" class="font-bold">{{ application.user.display_name }}</RouterLink>
            <div v-if="application.message" class="text-sm italic whitespace-pre-line">{{ application.message }}</div>
          </td>
          <td class="whitespace-nowrap">
            <button type="button" class="clanButton" @click="accept(application)">Accepter</button>
            <button type="button" class="clanButton pink ml-1" @click="refuse(application)">Refuser</button>
          </td>
        </tr>
      </tbody>
    </table>

    <h2 class="normal-case">Présentation du clan</h2>
    <form @submit.prevent="save">
      <textarea v-model="description"
                rows="10"
                maxlength="5000"
                class="kadoTextarea"></textarea>
      <label class="flex items-center gap-2 font-bold">
        <input v-model="isRecruiting" type="checkbox" class="w-auto!" />
        Le clan recrute de nouveaux membres
      </label>
      <MessageSuccess v-if="saved">Présentation enregistrée.</MessageSuccess>
      <input type="submit" value="Enregistrer" class="w-auto!" />
    </form>

    <h2 class="normal-case">Membres</h2>
    <p class="mx-0 text-sm">
      Un <strong>bras droit</strong> a tous les droits du chef de clan, sauf dissoudre le clan et nommer un nouveau chef.
      <template v-for="(seat, role) in seats" :key="role">
        <br /><strong>{{ seat.label }}</strong> ({{ taken(role) }} / {{ seat.count }}) : {{ seat.description }}
      </template>
    </p>
    <div class="overflow-x-auto">
      <table class="w-full">
        <tbody>
          <tr v-for="(m, index) in members" :key="m.user.etwin_id" :class="index % 2 ? 'oddfalse' : 'oddtrue'">
            <td class="text-left [font-variant:small-caps]">
              <img v-if="m.is_leader"
                   src="/gfx/clan/clanleader.gif"
                   alt="Chef de Clan"
                   title="Chef de Clan"
                   class="mr-1" />
              {{ m.user.display_name }}
            </td>
            <td class="whitespace-nowrap">
              <template v-if="m.is_leader">Chef de clan</template>
              <select v-else
                      :value="m.role"
                      class="text-kado-blue bg-white"
                      title="Rôle dans le clan"
                      @change="changeRole(m, $event.target.value)">
                <option value="member">Membre</option>
                <option value="right_hand">Bras droit</option>
              </select>
            </td>
            <td class="whitespace-nowrap">
              <select :value="m.combat_role ?? ''"
                      class="text-kado-blue bg-white"
                      title="Siège pour les attaques et les défenses"
                      @change="changeCombatRole(m, $event.target.value)">
                <option value="">Sans siège</option>
                <option v-for="(seat, role) in seats"
                        :key="role"
                        :value="role"
                        :disabled="m.combat_role !== role && taken(role) >= seat.count">{{ seat.label }}</option>
              </select>
            </td>
            <td class="whitespace-nowrap">
              <template v-if="m.user.etwin_id !== authStore.user?.etwin_id && !m.is_leader">
                <button v-if="isLeader"
                        type="button"
                        class="clanButton"
                        @click="doPromote(m)">Nommer chef</button>
                <button type="button" class="clanButton pink ml-1" @click="doKick(m)">Exclure</button>
              </template>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <template v-if="isLeader">
      <h2 class="normal-case">Dissoudre le clan</h2>
      <p class="mx-0 text-sm">Tous les membres quitteront le clan, et ses scores de la période seront perdus.</p>
      <button type="button" class="clanButton pink" @click="doDissolve">Dissoudre le clan</button>
    </template>
  </div>
</template>
