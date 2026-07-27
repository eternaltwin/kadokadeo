<script setup>
defineProps({
  game: { type: Object, required: true },
})

const keyMap = {
  mouse1: { image: '/gfx/controls/mouseLeftClic.gif', title: 'Clic gauche' },
  mouse2: { image: '/gfx/controls/mouseMove.gif', title: 'Déplacer la souris' },
  space: { image: '/gfx/controls/keySpace.gif', title: 'Espace' },
  enter: { image: '', title: 'Entrée' },
  arrowup: { image: '/gfx/controls/keyUpArrow.gif', title: 'Flèche haut' },
  arrowdown: { image: '/gfx/controls/keyDownArrow.gif', title: 'Flèche bas' },
  arrowleft: { image: '/gfx/controls/keyRightArrow.gif', title: 'Flèche gauche' },
  arrowright: { image: '/gfx/controls/keyLeftArrow.gif', title: 'Flèche droite' },
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
