<script setup>
const { isLoading, error, get } = useApi()
const siteRecords = ref([])

get('/site-records')
  .then((response) => {
    siteRecords.value = response.data
  })
  .catch(() => null)
</script>

<template>
  <div>
    <h1 class="mt-0 text-center">Records du site</h1>

    <Loader v-if="isLoading">Chargement des records...</Loader>
    <MessageError v-else-if="error">Error: {{ error }}</MessageError>
    <table v-else>
      <thead>
        <tr class="text-kado-orange uppercase text-sm *:px-2">
          <th class="text-left">Nom du jeu</th>
          <th class="text-right">Record du site</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="siteRecord in siteRecords" :key="siteRecord.game.id">
          <td class="text-left">
            <RouterLink :to="{ name: 'games.show', params: { id: siteRecord.game.id } }">
              {{ siteRecord.game.name }}
            </RouterLink>
          </td>
          <td class="text-right">
            <Number v-if="siteRecord.record !== null" color="blue" :value="siteRecord.record" />
            <span v-else>-</span>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>