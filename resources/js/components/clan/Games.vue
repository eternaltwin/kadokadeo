<script setup>
import KadoPoints from '@svg/k.svg'

import { t } from '@/i18n'

// "Parties de clan": the paid games of the player for the attacks and the defenses (used once the games of the day are),
// bought by packs with Kado points, given to the clan, distributed by the leader and the right hands
const props = defineProps({
  clan: { type: Object, required: true },
})
const emit = defineEmits(['updated'])

const authStore = useAuthStore()
const { fetchClanGames, buyClanGames, donateClanGames, distributeClanGames, fetchMembers, isLoading, error } = useClans()
const data = ref(null)
const members = ref([])
const donateCount = ref(1)
const distribution = reactive({ member: null, count: 1 })
const notice = ref(null)

const load = () => fetchClanGames().then((response) => {
  data.value = response.data
  if (response.data.clan?.can_distribute && !members.value.length) {
    fetchMembers(props.clan.id).then((membersData) => {
      members.value = membersData.data
    })
  }
})
load()

const done = (message) => {
  notice.value = message
  authStore.fetchUser()
  load()
  // the chest of the clan in its menu
  emit('updated')
}
const buy = (pack) => {
  if (confirm(t('clan_games.confirm_buy', { count: pack.count, price: pack.price }, pack.count))) {
    buyClanGames(pack.count).then(() => done(t('clan_games.bought', { count: pack.count }, pack.count)))
  }
}
const donate = () => donateClanGames(props.clan.id, donateCount.value).then(() => done(t('clan_games.donated', { count: donateCount.value }, donateCount.value)))
const distribute = () => {
  const member = members.value.find((m) => m.user.etwin_id === distribution.member)
  distributeClanGames(props.clan.id, distribution.member, distribution.count)
    .then(() => done(t('clan_games.distributed', { count: distribution.count, name: member?.user.display_name }, distribution.count)))
}
</script>

<template>
  <div class="relative space-y-4">
    <MessageError v-if="error">{{ error }}</MessageError>
    <MessageSuccess v-else-if="notice">{{ notice }}</MessageSuccess>
    <Loader v-if="isLoading && !data" />

    <template v-if="data">
      <i18n-t keypath="clan_games.intro" tag="p">
        <template #free><Number :value="data.attack_games" color="green" /></template>
        <template #per_day>{{ data.attack_games_per_day }}</template>
        <template #games><Number :value="data.games" color="blue" /></template>
        <template #points><strong>{{ formatScore(data.kado_points) }}</strong></template>
      </i18n-t>

      <KadoSectionTitle>{{ $t('clan_games.buy_title') }}</KadoSectionTitle>
      <div class="space-y-2">
        <FormButton v-for="pack in data.packs"
                    :key="pack.count"
                    :disabled="data.kado_points < pack.price"
                    :title="data.kado_points < pack.price ? $t('account.not_enough_points') : $t('clan_games.unit_price', { price: pack.unit_price })"
                    @click="buy(pack)"
                    class="flex items-center gap-1">
          {{ $t('clan_games.pack', { count: pack.count, price: formatScore(pack.price) }, pack.count) }} <KadoPoints class="inline size-4"/>
        </FormButton>
      </div>

      <KadoSectionTitle>{{ $t('clan_games.donate_title') }}</KadoSectionTitle>
      <i18n-t keypath="clan_games.donate_help" tag="p" class="text-sm">
        <template #games><Number :value="data.clan.games" color="orange" /></template>
        <template #gem><img src="/gfx/gemOrange.svg" class="w-5 max-w-none"></template>
      </i18n-t>
      <form class="flex items-center gap-2" @submit.prevent="donate">
        <FormInput v-model.number="donateCount"
                   type="number"
                   min="1"
                   :max="data.games"
                   class="w-20" />
        <FormButton type="submit" size="lg" :disabled="data.games < 1">{{ $t('clan_games.donate') }}</FormButton>
      </form>

      <template v-if="data.clan.can_distribute">
        <KadoSectionTitle>{{ $t('clan_games.distribute_title') }}</KadoSectionTitle>
        <form class="flex flex-wrap items-center gap-2" @submit.prevent="distribute">
          <FormSelect v-model="distribution.member">
            <option :value="null" disabled>{{ $t('clan_games.choose_player') }}</option>
            <option v-for="m in members" :key="m.user.etwin_id" :value="m.user.etwin_id">{{ m.user.display_name }}</option>
          </FormSelect>
          <FormInput v-model.number="distribution.count"
                     type="number"
                     min="1"
                     :max="data.clan.games"
                     class="w-20" />
          <FormButton type="submit" size="lg" :disabled="!distribution.member || data.clan.games < 1">{{ $t('clan_games.distribute') }}</FormButton>
        </form>
      </template>

      <template v-if="data.clan.transfers.length">
        <KadoSectionTitle>{{ $t('clan_games.last_donations') }}</KadoSectionTitle>
        <ul class="list-inside list-kado ml-4 space-y-1 text-sm">
          <li v-for="(transfer, index) in data.clan.transfers" :key="index">
            <template v-if="transfer.type === 'donation'">{{ $t('clan_games.donation', { from: transfer.from?.display_name, count: transfer.count }) }}</template>
            <template v-else>{{ $t('clan_games.transfer', { from: transfer.from?.display_name, count: transfer.count, to: transfer.to?.display_name }) }}</template>
          </li>
        </ul>
      </template>
    </template>
  </div>
</template>
