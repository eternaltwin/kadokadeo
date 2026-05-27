<script setup>
/* TO DO LIST :
- Voir si on voit sa propre fiche ou celle d'un autre joueur
- Si ma propre fiche, charger pour tous les jeux : la ligue actuelle, le record, le temps (lien vers le replay)
- Pour 2 joueurs, idem mais charger la même chose pour le 2ème joueur. Le tableau ajoute des colonnes pour la comparaison
*/

const props = defineProps({
  profile: { type: Object, required: true },
})

const showCompare = ref(true)
</script>

<template>
  <h1 class="mt-0 text-center">Profil de XXX</h1>
  <h2 class="normal-case">Complétion [et comparatif]</h2>
  
  <table class="thinTitles">
    <thead>
      <tr>
        <th rowspan="2" class="w-30/100">Jeu</th>
        <th colspan="3">Joueur 1</th>
        <th v-show="showCompare" colspan="3">Joueur 2</th>
      </tr>
      <tr>
        <th class="w-5/100">Niv</th>
        <th class="w-20/100">Score</th>
        <th class="w-10/100">Temps</th>
        <th v-show="showCompare" class="w-5/100">Niv</th>
        <th v-show="showCompare" class="w-20/100">Score</th>
        <th v-show="showCompare" class="w-5/100">Temps</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td>
          <RouterLink :to="{ name: 'games.show', params: { id: 7 } }">Interwheel</RouterLink>
        </td>
        <td><img src="/gfx/leagues/old/8.png" alt="Ligue or" /></td>
        <td><img src="/gfx/iconRedStar.gif" alt="Etoile rouge" /> <Number :value="53800" color="blue" /></td>
        <td>05:00</td>
        <td v-show="showCompare" ><img src="/gfx/leagues/old/7.png" alt="Ligue argent" /></td>
        <td v-show="showCompare" ><img src="/gfx/iconRedStar.gif" alt="Etoile rouge" /> <Number :value="46320" color="blue" /></td>
        <td v-show="showCompare" >04:00</td>
      </tr>
    </tbody>
  </table>
  
</template>