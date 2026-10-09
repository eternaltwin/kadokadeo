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

    <p v-if="status && !sections.length" class="mx-0 italic">Aucune attaque de ce clan ni contre ce clan pour le moment.</p>
    <div v-else class="overflow-x-auto">
      <table v-if="status" class="w-full text-sm">
        <thead>
          <tr class="uppercase text-[10px]">
            <th>Joueur</th>
            <th>Clan</th>
            <th>Jeu</th>
            <th>Score jeu</th>
            <th>Statut</th>
          </tr>
        </thead>
        <tbody>
          <template v-for="section in sections" :key="section.key">
            <tr>
              <td colspan="5" :class="section.type === 'atk' ? 'clanTypeAtk' : 'clanTypeDef'">
                <img :src="section.type === 'atk' ? '/gfx/clan/atksmall.gif' : '/gfx/clan/defsmall.gif'" alt="" />
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
              <td class="font-bold text-kado-blue whitespace-nowrap">{{ attack.score }} pts</td>
              <td class="whitespace-nowrap">
                <template v-if="attack.status === 'active'">
                  <ClanCountdown :until="attack.expires_at" @done="load" />
                  <div v-if="attack.can_defend" class="mt-1 flex flex-col gap-1">
                    <button type="button" class="clanButton" @click="doDefend(attack, false)">Défendre</button>
                    <button type="button"
                            class="clanButton text-xs"
                            title="Utiliser l'option Défense 120%"
                            @click="doDefend(attack, true)">
                      <img src="/gfx/clan/opt/optSuperDefense.gif" alt="" class="h-4" /> Défense 120%
                    </button>
                  </div>
                  <button v-if="attack.can_cancel"
                          type="button"
                          class="clanButton pink mt-1"
                          @click="doCancel(attack)">Annuler</button>
                </template>
                <template v-else-if="attack.status === 'won'">
                  Réussie <span class="font-bold text-[#ff6b9c]">+{{ attack.points }}</span>
                </template>
                <template v-else-if="attack.status === 'repelled'">
                  Repoussée<template v-if="attack.defender"> par {{ attack.defender.display_name }}</template>
                </template>
                <template v-else>{{ attack.status_label }}</template>
              </td>
            </tr>
          </template>
        </tbody>
      </table>
    </div>
  </div>
</template>
