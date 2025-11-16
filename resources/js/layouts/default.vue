<script setup>
import Error from '@/components/message/Error.vue'
import Kalendrier from '@/components/nav/Kalendrier.vue'
import Navbar from '@/components/nav/Navbar.vue'
import Starbar from '@/components/nav/Starbar.vue'
import Sidebar from '@/components/side/Sidebar.vue'
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()
</script>

<template>
  <header id="topPage">
    <nav id="languageNav">
      <ul>
        <li>
          <a href="#" title="Français">
            <div data-lang="fr" alt="french" title="Français"></div>
          </a>
        </li>
      </ul>
    </nav>
    <h1><span>KadoKadeo</span></h1>
    <template v-if="authStore.isAuthenticated">
      <Navbar />
      <Kalendrier />
      <Starbar />
    </template>
  </header>

  <main id="container">
    <section id="bodySection">
      <Error class="w-3/4 mb-12!">
        Kadokadéo est actuellement en alpha. Les scores que vous réaliserez finiront sans doute par
        être supprimés.
      </Error>
      <slot />
    </section>

    <template v-if="authStore.isAuthenticated">
      <Sidebar />
    </template>
  </main>
</template>
