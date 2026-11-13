<script setup>
import { t } from '@/i18n'
// "Statut": the attacks launched by the clan and the attacks against it still waiting for a defense, as on the old site
// (the finished ones are in "Historique"), then the wars declared by the clan and against it
const props = defineProps({
  clan: { type: Object, required: true },
})

const router = useRouter()
const clanStore = useClanStore()
const { fetchStatus, defend, improveAttack, cancelAttack, reserveDefense, isLoading, error } = useClans()
const status = ref(null)
const tournament = ref(null)

const load = () =>
  fetchStatus(props.clan.id).then((data) => {
    status.value = data.data
    tournament.value = data.tournament
  })
watchEffect(load)
// an attack received, repelled, won, a defense reserved, a war declared: at once
onClanUpdated(() => props.clan.id, ['status'], load)

// only the kinds of attacks there are
const sections = computed(() => [
  { key: 'launched', type: 'atk', title: t('clan_status.launched_title', { name: props.clan.name }), attacks: status.value?.launched ?? [] },
  { key: 'received', type: 'def', title: t('clan_status.received_title'), attacks: status.value?.received ?? [] },
].filter((section) => section.attacks.length))

const goPlay = (data) => router.push({ name: 'clans.play', params: { action: data.data.id } })
const doDefend = (attack) => defend(attack.id).then(goPlay)
const doImprove = (attack) => improveAttack(attack.id).then(goPlay)
// "Je m'en occupe": reserve the defense, take the place of another member, or give it up
const doReserve = (attack) => reserveDefense(attack.id).then(load)
const reserveLabel = (item) => (item.reserved_by_me ? t('clan_status.release') : item.reserved_by ? t('clan_status.take') : t('clan_status.reserve'))
const authStore = useAuthStore()
const doCancel = (attack) => {
  const isMine = attack.attacker.etwin_id === authStore.user?.etwin_id
  const question = isMine
    ? t('clan_status.confirm_cancel_own')
    : t('clan_status.confirm_cancel_other', { name: attack.attacker.display_name })
  if (confirm(question)) {
    cancelAttack(attack.id).then(() => {
      load()
      clanStore.reload()
    })
  }
}
</script>

<template>
  <div class="relative space-y-4">
    <MessageError v-if="error">{{ error }}</MessageError>
    <Loader v-if="isLoading && !status" />

    <div class="overflow-x-auto">
      <KadoTable v-if="status" class="w-full text-sm">
        <thead>
          <tr class="uppercase text-2xs">
            <th class="min-w-28 text-left">{{ $t('common.player') }}</th>
            <th class="min-w-28 text-left">{{ $t('clan_status.clan') }}</th>
            <th class="min-w-24 text-left">{{ $t('common.game') }}</th>
            <th class="text-right">{{ $t('common.score') }}</th>
            <th>{{ $t('clan_status.status') }}</th>
          </tr>
        </thead>
        <tbody>
          <!-- no attack: the frame of the table with a single line -->
          <tr v-if="!sections.length" class="bg-kado-blue-100">
            <td colspan="5" class="px-2 py-1 italic text-kado-blue-700">
              {{ $t('clan_status.no_attack') }}
            </td>
          </tr>
          <template v-for="section in sections" :key="section.key">
            <tr>
              <td colspan="5"
                  class="border border-l border-solid bg-[position:-34px_-6px] bg-no-repeat py-1 pr-2 pl-1 text-left text-[15px] leading-[17px]"
                  :class="section.type === 'atk'
                    ? 'border-kado-pink-400 bg-kado-pink-50 bg-[url(/gfx/clan/pinkh2_bg.jpg)] text-kado-pink-400'
                    : 'border-kado-teal-500 bg-[url(/gfx/clan/blueh2_bg.jpg)] text-kado-blue-700'">
                <img :src="section.type === 'atk' ? '/gfx/clan/atksmall.gif' : '/gfx/clan/defsmall.gif'" alt="" class="mr-1" />
                {{ section.title }}
              </td>
            </tr>
            <tr v-for="(attack, index) in section.attacks" :key="attack.id" :class="index % 2 ? 'bg-white' : 'bg-kado-blue-100'">
              <td class="px-2 py-1 text-left small-caps">
                <RouterLink :to="{ name: 'profile.show', params: { id: attack.attacker.etwin_id } }">{{ attack.attacker.display_name }}</RouterLink>
              </td>
              <td class="px-2 py-1 text-left font-bold">
                <RouterLink v-if="section.key === 'launched'" :to="{ name: 'clans.show', params: { id: attack.defender_clan.id } }">{{ attack.defender_clan.name }}</RouterLink>
                <RouterLink v-else :to="{ name: 'clans.show', params: { id: attack.attacker_clan.id } }">{{ attack.attacker_clan.name }}</RouterLink>
              </td>
              <td class="px-2 py-1 text-left">
                <RouterLink :to="{ name: 'games.show', params: { id: attack.game.id } }" class="text-kado-blue-700">{{ attack.game.name }}</RouterLink>
              </td>
              <td class="px-2 py-1 text-right font-bold text-kado-blue-700 whitespace-nowrap">
                <Number :value="attack.score" color="blue" />
              </td>
              <td class="px-2 py-1 whitespace-nowrap">
                <!-- the countdown, then the small buttons of what the player can do -->
                <div class="flex flex-col items-center justify-center gap-2">
                  <ClanCountdown :until="attack.expires_at" @done="load" />
                  <FormButton v-if="attack.can_defend" size="sm" @click="doDefend(attack)">{{ $t('clan_status.defend') }}</FormButton>
                  <FormButton v-if="attack.can_improve"
                              size="sm"
                              :title="$t('clan_status.improve_title')"
                              @click="doImprove(attack)">{{ $t('clan_status.improve') }}</FormButton>
                  <FormButton v-if="attack.can_cancel"
                              size="sm"
                              variant="pink"
                              :title="$t('clan_status.cancel_title')"
                              @click="doCancel(attack)">{{ $t('common.cancel') }}</FormButton>
                  <FormButton v-if="attack.can_reserve"
                              size="sm"
                              :variant="attack.reserved_by_me ? 'pink' : 'green'"
                              :title="$t('clan_status.reserve_title')"
                              @click="doReserve(attack)">{{ reserveLabel(attack) }}</FormButton>
                  <span v-if="attack.reserved_by" class="text-xs italic">{{ $t('clan_status.reserved_by', { name: attack.reserved_by.display_name }) }}</span>
                </div>
              </td>
            </tr>
          </template>
        </tbody>
      </KadoTable>
    </div>

    <!-- the wars declared by the clan (its targets) and against it -->
    <template v-if="status?.wars?.length">
      <KadoSectionTitle>{{ $t('clan_status.wars') }}</KadoSectionTitle>
      <ul class="list-inside list-kado ml-4 space-y-1">
        <i18n-t v-for="war in status.wars"
                :key="war.id"
                keypath="clan_status.war_declared"
                tag="li">
          <template #clan>
            <strong v-if="war.clan.id === clan.id">{{ war.clan.name }}</strong>
            <RouterLink v-else :to="{ name: 'clans.status', params: { id: war.clan.id } }" class="font-bold">{{ war.clan.name }}</RouterLink>
          </template>
          <template #target>
            <strong v-if="war.target.id === clan.id">{{ war.target.name }}</strong>
            <RouterLink v-else :to="{ name: 'clans.status', params: { id: war.target.id } }" class="font-bold">{{ war.target.name }}</RouterLink>
          </template>
        </i18n-t>
      </ul>
    </template>
  </div>
</template>
