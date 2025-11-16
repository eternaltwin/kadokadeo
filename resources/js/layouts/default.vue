<script setup>
import { useAuthStore } from '@/stores/auth'
import Navbar from '@/components/nav/Navbar.vue'
import Kalendrier from '@/components/nav/Kalendrier.vue'
import Starbar from '@/components/nav/Starbar.vue'
import Sidebar from '@/components/side/Sidebar.vue'

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
      <div class="error w-3/4 mb-12!">
        <div>
          <p>
            Kadokadéo est actuellement en alpha. Les scores que vous réaliserez finiront sans doute
            par être supprimés.
          </p>
        </div>
      </div>
      <slot />
    </section>

    <template v-if="authStore.isAuthenticated">
      <Sidebar />
    </template>
  </main>
</template>
