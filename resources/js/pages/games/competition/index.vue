<script setup>
const { isLoading, error, get } = useApi()
const leaderboard = ref([])

get('/competition')
  .then((response) => {
    leaderboard.value = response.data
  })
  .catch(() => null)
</script>

<template>
  <div>
    <h1 class="mt-0 text-center">La mécanique des 1500</h1>
    <p class="mb-4 text-center">Période courante · 12 meilleurs jeux</p>

    <Loader v-if="isLoading">Chargement du classement...</Loader>
    <MessageError v-else-if="error">Error: {{ error }}</MessageError>
    <table v-else class="w-full">
      <thead>
        <tr class="text-kado-orange uppercase text-sm *:px-2">
          <th class="text-right">Rang</th>
          <th class="text-left">Joueur</th>
          <th class="text-right">Points</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="player in leaderboard" :key="player.user.etwin_id">
          <td class="text-right">{{ player.rank }}</td>
          <td class="text-left">
            <RouterLink :to="{ name: 'profile.show', params: { id: player.user.etwin_id } }">
              {{ player.user.display_name }}
            </RouterLink>
          </td>
          <td class="text-right"><Number color="blue" :value="player.score" /></td>
        </tr>
      </tbody>
    </table>
  </div>
</template>