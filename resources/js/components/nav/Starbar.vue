<script setup>
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()
</script>

<template>
  <aside id="topBarInfo">
    <ul>
      <li id="topBarKadoPoints">
        <span>{{ authStore.user.kado_points ?? 0 }}</span>
      </li>
      <li id="topBarGreenStar">
        <span>0</span>
      </li>
      <li id="topBarOrangeStar">
        <span>0</span>
      </li>
      <li id="topBarRedStar">
        <span>0</span>
      </li>
    </ul>
  </aside>
</template>
