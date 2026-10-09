<script setup>
// "Statut": the attacks launched by the clan and the attacks against it, as on the old site
const props = defineProps({
  clan: { type: Object, required: true },
})

const router = useRouter()
const clanStore = useClanStore()
const { fetchStatus, defend, cancelAttack, isLoading, error } = useClans()
const status = ref(null)
const tournament = ref(null)

const load = () =>
  fetchStatus(props.clan.id).then((data) => {
    status.value = data.data
    tournament.value = data.tournament
  })
watchEffect(load)

// only the kinds of attacks there are
const sections = computed(() => [
  { key: 'launched', type: 'atk', title: `Le clan ${props.clan.name} a lancé les attaques suivantes`, attacks: status.value?.launched ?? [] },
  { key: 'received', type: 'def', title: 'Ce clan est attaqué', attacks: status.value?.received ?? [] },
].filter((section) => section.attacks.length))

const doDefend = (attack, superDefense) =>
  defend(attack.id, superDefense).then((data) => router.push({ name: 'clans.play', params: { action: data.data.id } }))
const doCancel = (attack) => {
  if (confirm('Annuler cette attaque ?')) {
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
      <table v-if="status" class="statusTable w-full text-sm">
        <thead>
          <tr class="uppercase text-[10px]">
            <th class="text-left!">Joueur</th>
            <th class="text-left!">Clan</th>
            <th class="text-left!">Jeu</th>
            <th class="text-right!">Score</th>
            <th>Statut</th>
            <th v-if="hasActions" class="w-32"></th>
          </tr>
        </thead>
        <tbody>
          <!-- no attack: the frame of the table with a single line -->
          <tr v-if="!sections.length" class="oddtrue">
            <td :colspan="columns" class="py-4 italic text-kado-blue">
              Aucune attaque de ce clan ni contre ce clan pour le moment.
            </td>
          </tr>
          <template v-for="section in sections" :key="section.key">
            <tr>
              <td :colspan="columns" :class="section.type === 'atk' ? 'clanTypeAtk' : 'clanTypeDef'">
                <img :src="section.type === 'atk' ? '/gfx/clan/atksmall.gif' : '/gfx/clan/defsmall.gif'" alt="" class="mr-1" />
                {{ section.title }}
              </td>
            </tr>
            <tr v-for="(attack, index) in section.attacks" :key="attack.id" :class="index % 2 ? 'oddfalse' : 'oddtrue'">
              <td class="text-left [font-variant:small-caps]">
                <RouterLink :to="{ name: 'profile.show', params: { id: attack.attacker.etwin_id } }">{{ attack.attacker.display_name }}</RouterLink>
              </td>
              <td class="text-left font-bold">
                <RouterLink v-if="section.key === 'launched'" :to="{ name: 'clans.show', params: { id: attack.defender_clan.id } }">{{ attack.defender_clan.name }}</RouterLink>
                <RouterLink v-else :to="{ name: 'clans.show', params: { id: attack.attacker_clan.id } }">{{ attack.attacker_clan.name }}</RouterLink>
              </td>
              <td class="text-left">
                <RouterLink :to="{ name: 'games.show', params: { id: attack.game.id } }" class="text-kado-blue">{{ attack.game.name }}</RouterLink>
              </td>
              <td class="text-right font-bold text-kado-blue whitespace-nowrap">{{ formatScore(attack.score) }} pts</td>
              <td class="whitespace-nowrap">
                <ClanCountdown v-if="attack.status === 'active'" :until="attack.expires_at" @done="load" />
                <template v-else-if="attack.status === 'won'">
                  Réussie <span class="font-bold text-[#ff6b9c]">+{{ attack.points }}</span>
                </template>
                <template v-else-if="attack.status === 'repelled'">
                  Repoussée<template v-if="attack.defender"> par {{ attack.defender.display_name }}</template>
                </template>
                <template v-else>{{ attack.status_label }}</template>
              </td>
              <td v-if="hasActions" class="whitespace-nowrap">
                <div v-if="attack.status === 'active'" class="flex flex-col items-stretch gap-1">
                  <template v-if="attack.can_defend">
                    <button type="button" class="clanButton" @click="doDefend(attack, false)">Défendre</button>
                    <button type="button"
                            class="clanButton text-xs"
                            title="Utiliser l'option Défense 120%"
                            @click="doDefend(attack, true)">Défense 120%</button>
                  </template>
                  <button v-if="attack.can_cancel"
                          type="button"
                          class="clanButton pink"
                          @click="doCancel(attack)">Annuler</button>
                </div>
              </td>
            </tr>
          </template>
        </tbody>
      </table>
    </div>
  </div>
</template>

<style scoped>
.statusTable td {
  padding: 4px 8px;
}
</style>
