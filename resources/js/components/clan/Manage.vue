<script setup>
// "Gestion" (leader only): the presentation of the clan, the applications and the members
const props = defineProps({
  clan: { type: Object, required: true },
})
const emit = defineEmits(['updated'])

const authStore = useAuthStore()
const clanStore = useClanStore()
const { updateClan, fetchApplications, acceptApplication, refuseApplication, fetchMembers, kick, promote, error } = useClans()

const description = ref(props.clan.description ?? '')
const isRecruiting = ref(props.clan.is_recruiting)
const saved = ref(false)
const applications = ref([])
const members = ref([])

const loadApplications = () => fetchApplications(props.clan.id).then((data) => {
  applications.value = data.data
})
const loadMembers = () => fetchMembers(props.clan.id).then((data) => {
  members.value = data.data
})
loadApplications()
loadMembers()

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
  if (confirm(`Nommer ${member.user.display_name} chef de clan ? Vous ne pourrez plus gérer le clan.`)) {
    promote(props.clan.id, member.user.etwin_id).then(() => {
      clanStore.reload()
      emit('updated')
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
                class="w-full border-2 border-white bg-white bg-[url(/gfx/bgInput.jpg)] bg-repeat-x p-2 text-kado-blue"></textarea>
      <label class="flex items-center gap-2 font-bold">
        <input v-model="isRecruiting" type="checkbox" class="w-auto!" />
        Le clan recrute de nouveaux membres
      </label>
      <MessageSuccess v-if="saved">Présentation enregistrée.</MessageSuccess>
      <input type="submit" value="Enregistrer" class="w-auto!" />
    </form>

    <h2 class="normal-case">Membres</h2>
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
            <template v-if="m.user.etwin_id !== authStore.user?.etwin_id">
              <button type="button" class="clanButton" @click="doPromote(m)">Nommer chef</button>
              <button type="button" class="clanButton pink ml-1" @click="doKick(m)">Exclure</button>
            </template>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>
