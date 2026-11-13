<script setup>
// "Attaquer ce clan": the score of the run on the chosen game becomes the attack
const props = defineProps({
  clan: { type: Object, required: true },
})

const router = useRouter()
const { attack, error } = useClans()
const clanStore = useClanStore()

const choose = (game) =>
  attack(props.clan.id, game.id).then((data) => router.push({ name: 'clans.play', params: { action: data.data.id } }))
</script>

<template>
  <div class="space-y-4">
    <MessageError v-if="clan.viewer.attack_blocked">{{ clan.viewer.attack_blocked }}</MessageError>
    <template v-else>
      <i18n-t keypath="clan_attack_picker.rules" tag="p">
        <template #clan><strong>{{ clan.name }}</strong></template>
        <template #hours>{{ clanStore.rules?.attack_hours }}</template>
        <template #points><Number :value="clan.viewer.attack_points" color="pink" /></template>
      </i18n-t>
      <MessageError v-if="error">{{ error }}</MessageError>
      <ClanGamePicker :title="$t('clan_attack_picker.attack_with')" @select="choose" />
    </template>
  </div>
</template>
