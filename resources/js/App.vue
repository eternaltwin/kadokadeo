<script setup>
import { computed } from 'vue'
import { useRoute } from 'vue-router'

import DefaultLayout from '@/layouts/default.vue'

const layouts = {
  DefaultLayout,
}

const route = useRoute()
const layout = computed(() => {
  return layouts[route.meta?.layout || 'DefaultLayout']
})
</script>

<template>
  <component :is="layout">
    <router-view />
  </component>
</template>
