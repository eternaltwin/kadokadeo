<script setup>
import Announcement from '@/components/message/Announcement.vue'
import PendingRuns from '@/components/message/PendingRuns.vue'
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

  <Announcement style="width: 890px; margin: 20px 60px 40px 60px; font-size: 0.85em" />
  <PendingRuns style="width: 890px; margin: 0 60px 40px 60px; font-size: 0.85em" />

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
