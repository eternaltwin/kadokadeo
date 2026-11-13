<script setup>
import KadoPoints from '@svg/k.svg'

import { t } from '@/i18n'

// the page of a clan: Présentation, Statut, Mission, Membres, Gestion, Parties de clan, Historique, and the choice of the game of an
// attack
const route = useRoute()
const router = useRouter()
const clanStore = useClanStore()
const authStore = useAuthStore()
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
// its presentation, its members (the viewer may be out of it now): at once
onClanUpdated(clanId, ['clan', 'members'], load)
// the application of the viewer answered (he is not in the clan yet: told on his own channel)
useChannel(() => userChannel(authStore.user?.id), {
  'notification.received': (e) => {
    if (['clan_accepted', 'clan_refused'].includes(e.notification.type) && String(e.notification.clan?.id) === String(clanId.value)) {
      load()
    }
  },
})

const viewer = computed(() => clan.value?.viewer ?? {})
const applicationMessage = ref('')
const showApplyForm = ref(false)
// an application costs Kado points (ClanSettings::$application_price), given back if the clan refuses it
const applicationPrice = computed(() => clanStore.rules?.application_price ?? 0)
const canPayApplication = computed(() => (authStore.user?.kado_points ?? 0) >= applicationPrice.value)
// sent and not yet shown on the page: the button stays disabled, a click more would not send it again
const applying = ref(false)
// the confirmation of the last action of the player on the page
const notice = ref(null)
watch(clanId, () => {
  notice.value = null
})

const apply = () => {
  if (applying.value) {
    return
  }
  applying.value = true
  actions.apply(clan.value.id, applicationMessage.value || null).then(() => {
    showApplyForm.value = false
    applicationMessage.value = ''
    notice.value = t('clan_show.applied', { clan: clan.value.name })
    authStore.fetchUser()
    clanStore.reload()
    return load()
  }).catch(() => {}).finally(() => {
    applying.value = false
  })
}
const cancelApplication = () => {
  if (!confirm(t('clan_show.confirm_cancel_application'))) {
    return
  }
  actions.cancelApplication(viewer.value.application_id).then(() => {
    notice.value = applicationPrice.value ? t('clan_show.application_cancelled_refunded') : t('clan_show.application_cancelled')
    authStore.fetchUser()
    clanStore.reload()
    load()
  })
}
const leave = () => {
  if (viewer.value.is_new_member) {
    alert(t('clan_show.new_member_cannot_leave'))
    return
  }
  if (confirm(t('clan_show.confirm_leave'))) {
    actions.leave().then(() => {
      clanStore.reload()
      router.push({ name: 'clans.index' })
    })
  }
}
// "Déclarer la guerre": the targets of the members of the clan of the player (3 at most, until the end of the period), shown
// in "Statut"
const toggleWar = () => {
  const atWar = viewer.value.at_war
  if (!confirm(atWar ? t('clan_show.confirm_peace', { clan: clan.value.name }) : t('clan_show.confirm_war', { clan: clan.value.name }))) {
    return
  }
  ;(atWar ? actions.endWar(clan.value.id) : actions.declareWar(clan.value.id)).then(() => {
    notice.value = atWar
      ? t('clan_show.peace_made', { clan: clan.value.name })
      : t('clan_show.war_declared', { clan: clan.value.name })
    load()
  })
}
const updated = () => {
  load()
  clanStore.reload()
}
</script>

<template>
  <div class="relative min-h-48">
    <Loader v-if="isLoading && !clan">{{ $t('clan_show.loading') }}</Loader>
    <MessageError v-else-if="!clan">{{ $t('clan_show.not_found', { error }) }}</MessageError>

    <ClanLayout v-else :clan="clan" :tab="tab">
      <template #actions>
        <ClanMenuAction v-if="viewer.can_manage" :to="{ name: 'clans.manage', params: { id: clan.id } }">{{ $t('clan_show.manage') }}</ClanMenuAction>
        <ClanMenuAction v-if="viewer.is_member" :to="{ name: 'clans.games', params: { id: clan.id } }">{{ $t('clan_show.games') }}</ClanMenuAction>
        <ClanMenuAction v-if="viewer.is_member" :to="{ name: 'clans.forum', params: { id: clan.id } }">{{ $t('titles.forum') }}</ClanMenuAction>
        <ClanMenuAction :to="{ name: 'clans.history', params: { id: clan.id } }">{{ $t('common.history') }}</ClanMenuAction>
        <ClanMenuAction v-if="!viewer.is_member && viewer.has_clan"
                        :to="{ name: 'clans.attack', params: { id: clan.id } }"
                        :title="viewer.attack_blocked ?? $t('clan_show.attack')">{{ $t('clan_show.attack') }}</ClanMenuAction>
        <ClanMenuAction v-if="viewer.can_declare_war"
                        :title="viewer.at_war ? $t('clan_show.stop_war_title') : $t('clan_show.declare_war_title')"
                        @click="toggleWar">{{ viewer.at_war ? $t('clan_show.make_peace') : $t('clan_show.declare_war') }}</ClanMenuAction>
        <ClanMenuAction v-if="!viewer.has_clan && viewer.application_id" :title="$t('clan_show.cancel_application_title')" @click="cancelApplication">{{ $t('clan_show.cancel_application') }}</ClanMenuAction>
        <ClanMenuAction v-else-if="!viewer.has_clan && clan.is_recruiting && !applying" :title="$t('clan_show.apply_title')" @click="showApplyForm = !showApplyForm">{{ $t('clan_show.apply') }}</ClanMenuAction>
        <ClanMenuAction v-if="viewer.is_member" @click="leave" :class="{'grayscale cursor-not-allowed': viewer.is_new_member}">{{ $t('clan_show.leave') }}</ClanMenuAction>
        <ClanMenuAction v-if="clanStore.clan && clanStore.clan.id !== clan.id" :to="{ name: 'clans.show', params: { id: clanStore.clan.id } }">{{ $t('clan_show.my_clan') }}</ClanMenuAction>
      </template>

      <MessageError v-if="actions.error.value">{{ actions.error.value }}</MessageError>
      <MessageSuccess v-else-if="notice">{{ notice }}</MessageSuccess>
      <KadoNotice v-else-if="!viewer.has_clan && viewer.application_id"
                  variant="warning"
                  as="p"
                  class="my-4 font-bold text-kado-orange-700">
        {{ $t('clan_show.pending_application') }}
      </KadoNotice>

      <ClanUnfinishedActions v-if="viewer.is_member" :actions="viewer.unfinished_actions ?? []" @updated="load" />

      <form v-if="showApplyForm && !viewer.application_id" class="mb-4 space-y-2" @submit.prevent="apply">
        <div>
          <label for="applicationMessage" class="font-bold">{{ $t('clan_show.message_label') }}</label>
          <FormTextarea id="applicationMessage"
                        v-model="applicationMessage"
                        rows="3"
                        maxlength="500" />
        </div>
        <FormButton type="submit"
                    size="lg"
                    :disabled="applying || !canPayApplication"
                    :title="canPayApplication ? '' : $t('account.not_enough_points')">
          <template v-if="!applying"><Number :value="applicationPrice" color="green" /> <KadoPoints class="inline size-5" /></template>
          {{ applying ? $t('clan_show.sending') : $t('clan_show.send_application') }}
        </FormButton>
      </form>

      <ClanPresentation v-if="tab === 'show'" :clan="clan" :tournament="tournament" />
      <ClanStatus v-else-if="tab === 'status'" :clan="clan" />
      <ClanMissions v-else-if="tab === 'missions'" :clan="clan" />
      <ClanMembers v-else-if="tab === 'members'" :clan="clan" />
      <ClanManage v-else-if="tab === 'manage'" :clan="clan" @updated="updated" />
      <ClanAttackPicker v-else-if="tab === 'attack'" :clan="clan" />
      <ClanHistory v-else-if="tab === 'history'" :clan="clan" />
      <ClanGames v-else-if="tab === 'games' && viewer.is_member" :clan="clan" @updated="load" />
    </ClanLayout>
  </div>
</template>
