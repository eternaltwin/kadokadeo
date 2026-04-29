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

  <Error style="width:890px;margin:20px 60px 40px 60px;font-size:0.85em;">
    Kadokadéo est en alpha! Il le restera jusqu'à avoir un site complet.<br />
    Les replays des jeux ont été réinitialisés le 1er mai 2026.<br />
    De nouveaux jeux seront ajoutés régulièrement, n'hésitez pas à revenir souvent pour les découvrir!<br />
  </Error>

  <main id="container">

    <section id="bodySection">
      <slot />
    </section>

    <template v-if="authStore.isAuthenticated">
      <Sidebar />
    </template>
  </main>
</template>
