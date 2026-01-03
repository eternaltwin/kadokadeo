<script setup>
import GameScript from '@/components/games/GameScript.vue'
</script>

<template>
  <div>
    <!-- <span style="font-family: 'Fredoka Bold'; font-size: 48px;" class="">Choco Mouche</span> -->
    <GameScript
      class="m-auto"
      :gameWidth="600"
      :gameHeight="640"
    />
  </div>
</template>
