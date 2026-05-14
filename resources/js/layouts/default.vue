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

  <Error style="width: 890px; margin: 20px 60px 40px 60px; font-size: 0.85em">
    Kadokadéo est en alpha! Il le restera jusqu'à avoir un site complet.<br />
    Les replays des jeux ont été réinitialisés le 14 mai 2026.<br />
  </Error>

  <main id="container">
    <section id="bodySection" class="w-full flex">
      <div class="flex-1">
        <slot />
      </div>

      <template v-if="authStore.isAuthenticated">
        <div class="w-[150px] relative">
          <div class="absolute right-0 translate-x-1/4 text-xs w-[200px]">
            <Sidebar />
          </div>
        </div>
      </template>
    </section>
  </main>
</template>
