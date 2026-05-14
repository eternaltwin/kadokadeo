<script setup>
defineProps({
  game: { type: Object, required: true },
})

const keyMap = {
  mouse1: { image: '/gfx/gameCommandLeftClic.png', title: 'Clic gauche' },
  mouse2: { image: '', title: 'Clic droit' },
  space: { image: '', title: 'Espace' },
  enter: { image: '', title: 'Entrée' },
  arrowup: { image: '', title: 'Flèche haut' },
  arrowdown: { image: '', title: 'Flèche bas' },
  arrowleft: { image: '', title: 'Flèche gauche' },
  arrowright: { image: '', title: 'Flèche droite' },
}
</script>

<template>
  <table class="gameCommands border-0 **:border-0 noBackground">
    <thead>
      <tr>
        <th style="width: 70px" scope="col">Commande</th>
        <th scope="col">Fonction</th>
      </tr>
    </thead>
    <tbody>
      <tr v-for="control in game.controls" :key="control.id">
        <td scope="row">
          <img v-for="key in control.keys"
               :key="key"
               :src="keyMap[key]?.image || ''"
               :title="keyMap[key]?.title || ''"
               :alt="keyMap[key]?.title || ''"
          />
        </td>
        <td>{{ control.description }}</td>
      </tr>
    </tbody>
  </table>
</template>
