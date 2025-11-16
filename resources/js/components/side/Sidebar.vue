<script setup>
const otherGames = [
  { name: 'Eternalfest', url: 'https://eternalfest.net' },
  { name: 'eMush', url: 'https://emush.eternaltwin.org' },
  { name: 'Neoparc', url: 'https://neoparc.eternal-twin.net' },
  { name: 'MyHordes', url: 'https://myhordes.eu' },
  { name: 'Directquiz', url: 'https://directquiz.org' },
  { name: 'La Brute', url: 'https://brute.eternaltwin.org' },
  { name: 'ePopotamo', url: 'https://epopotamo.eternaltwin.org' },
  { name: 'DinoRPG', url: 'https://dinorpg.eternaltwin.org' },
  { name: 'EternalKingdom', url: 'https://kingdom.eternaltwin.org' },
]
</script>

<template>
  <aside id="containerSide">
    <nav class="sideBoxGreen">
      <h2>Menu</h2>
      <ul id="menuSide">
        <li class="news"><a href="#" title="Nouveautés">Nouveautés</a></li>
        <li class="scores"><a href="#" title="Mes scores">Mes scores</a></li>
        <li class="account"><a href="user/settings" title="Mon compte">Mon compte</a></li>
        <li class="help"><a href="#" title="Aide">Aide</a></li>
      </ul>
    </nav>
    <aside class="sideBoxBlue">
      <h2>Top 3 clans</h2>
      <ul>
        <li class="text-center italic">Non disponible...</li>
      </ul>
    </aside>
    <aside class="sideBoxPink">
      <h2>Nos autres jeux</h2>
      <ul>
        <li class="text-center mb-1">
          <a href="https://eternal-twin.net" title="Projet EternalTwin" class="font-bold">
            Projet EternalTwin
          </a>
          <br />
          <a href="https://discord.gg/ERc3svy" title="Discord EternalTwin">
            Nous rejoindre sur Discord
          </a>
        </li>
        <li>
          <template v-for="og of otherGames" :key="og.name">
            <a :href="og.url" :title="og.name" target="_blank">{{ og.name }}</a>
            <br />
          </template>
        </li>
      </ul>
    </aside>
  </aside>
</template>
