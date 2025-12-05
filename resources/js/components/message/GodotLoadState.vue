<script setup>
import { useGodot } from '@/composables/useGodot'

const { engineLoadProgress } = useGodot()
</script>

<template>
  <div v-if="engineLoadProgress < 1" class="fixed right-0 bottom-10 w-56 bg-slate-600 rounded-l-md text-white p-2">
    <div class="text-center font-bold mb-2">Téléchargement des ressources...</div>
    <div class="w-full bg-slate-500 h-4 rounded-md overflow-hidden mb-2">
      <div
        class="bg-green-500 h-4 transition-all duration-75"
        :style="{ width: (engineLoadProgress * 100) + '%' }"
      ></div>
    </div>
  </div>
</template>
