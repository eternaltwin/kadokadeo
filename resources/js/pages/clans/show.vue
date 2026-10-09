<script setup>
// the page of a clan: Présentation, Statut, Mission, Membres, Gestion, and the choice of the game of an attack
const route = useRoute()
const router = useRouter()
const clanStore = useClanStore()
const { fetchClan, isLoading, error } = useClans()
// (their own errors)
const actions = useClans()

const clan = ref(null)
const tournament = ref(null)
const tab = computed(() => route.meta.tab ?? 'show')
const clanId = computed(() => route.params.id)

const load = () =>
  fetchClan(clanId.value).then((data) => {
    clan.value = data.data
    tournament.value = data.tournament
  })
watch(clanId, load, { immediate: true })

const viewer = computed(() => clan.value?.viewer ?? {})
const applicationMessage = ref('')
const showApplyForm = ref(false)
// the confirmation of the last action of the player on the page
const notice = ref(null)
watch(clanId, () => {
  notice.value = null
})

const apply = () =>
  actions.apply(clan.value.id, applicationMessage.value || null).then(() => {
    showApplyForm.value = false
    applicationMessage.value = ''
    notice.value = `Votre candidature a bien été envoyée au chef du clan ${clan.value.name}. Vous serez membre du clan dès qu'il l'aura acceptée.`
    clanStore.reload()
    load()
  })
const cancelApplication = () => {
  if (!confirm('Retirer votre candidature à ce clan ?')) {
    return
  }
  actions.cancelApplication(viewer.value.application_id).then(() => {
    notice.value = 'Votre candidature a été retirée.'
    clanStore.reload()
    load()
  })
}
const leave = () => {
  if (confirm('Quitter ce clan ?')) {
    actions.leave().then(() => {
      clanStore.reload()
      router.push({ name: 'clans.index' })
    })
  }
}
const updated = () => {
  load()
  clanStore.reload()
}
</script>

<template>
  <div class="relative min-h-48">
    <Loader v-if="isLoading && !clan">Chargement ...</Loader>
    <MessageError v-else-if="!clan">Clan introuvable. ({{ error }})</MessageError>

    <ClanLayout v-else :clan="clan" :tab="tab">
      <template #actions>
        <li v-if="viewer.is_leader">
          <RouterLink :to="{ name: 'clans.manage', params: { id: clan.id } }">Gérer le clan</RouterLink>
        </li>
        <li v-if="!viewer.is_member && viewer.has_clan">
          <RouterLink :to="{ name: 'clans.attack', params: { id: clan.id } }" :title="viewer.attack_blocked ?? 'Attaquer ce clan'">Attaquer ce clan</RouterLink>
        </li>
        <li v-if="!viewer.has_clan && viewer.application_id">
          <button type="button" title="Annuler ma candidature" @click="cancelApplication">Retirer ma demande</button>
        </li>
        <li v-else-if="!viewer.has_clan && clan.is_recruiting">
          <button type="button" title="Envoyer ma candidature" @click="showApplyForm = !showApplyForm">Postuler</button>
        </li>
        <li v-if="viewer.is_member">
          <button type="button" @click="leave">Quitter le clan</button>
        </li>
        <li v-if="clanStore.clan && clanStore.clan.id !== clan.id">
          <RouterLink :to="{ name: 'clans.show', params: { id: clanStore.clan.id } }">Mon clan</RouterLink>
        </li>
      </template>

      <MessageError v-if="actions.error.value">{{ actions.error.value }}</MessageError>
      <MessageSuccess v-else-if="notice">{{ notice }}</MessageSuccess>
      <p v-else-if="!viewer.has_clan && viewer.application_id" class="mx-0 mb-4 border-l-4 border-kado-cyan-800 bg-kado-cyan-100 px-2 py-1 text-sm">
        Votre candidature à ce clan est en attente de la réponse du chef de clan.
      </p>

      <form v-if="showApplyForm" class="mb-4" @submit.prevent="apply">
        <div>
          <label for="applicationMessage">Votre message au chef de clan (facultatif)</label>
          <textarea id="applicationMessage"
                    v-model="applicationMessage"
                    rows="3"
                    maxlength="500"
                    class="w-full border-2 border-white bg-white bg-[url(/gfx/bgInput.jpg)] bg-repeat-x p-2 text-kado-blue"></textarea>
        </div>
        <input type="submit" value="Envoyer votre candidature" class="w-auto!" />
      </form>

      <ClanPresentation v-if="tab === 'show'" :clan="clan" :tournament="tournament" />
      <ClanStatus v-else-if="tab === 'status'" :clan="clan" />
      <ClanMissions v-else-if="tab === 'missions'" :clan="clan" />
      <ClanMembers v-else-if="tab === 'members'" :clan="clan" />
      <ClanManage v-else-if="tab === 'manage'" :clan="clan" @updated="updated" />
      <ClanAttackPicker v-else-if="tab === 'attack'" :clan="clan" />
    </ClanLayout>
  </div>
</template>
