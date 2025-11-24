<script setup>
import Number from '@/components/Number.vue'
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()
</script>

<template>
  <aside id="topBarInfo">
    <ul>
      <li id="topBarKadoPoints">
        <Number :value="authStore.user.kado_points ?? 0" color="bigGreen" />
      </li>
      <li id="topBarGreenStar">
        <Number :value="authStore.greenStars" color="bigGreen" />
      </li>
      <li id="topBarOrangeStar">
        <Number :value="authStore.orangeStars" color="bigGreen" />
      </li>
      <li id="topBarRedStar">
        <Number :value="authStore.redStars" color="bigGreen" />
      </li>
    </ul>
  </aside>
</template>
