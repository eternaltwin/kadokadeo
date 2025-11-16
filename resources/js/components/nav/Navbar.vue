<script setup></script>

<template>
  <nav id="topNav">
    <ul>
      <li>
        <RouterLink :to="{ name: 'games.index' }" id="topNavGames">
          <span>Jeux</span>
        </RouterLink>
      </li>
      <li>
        <a href="#" id="topNavCompetition"><span>Site</span></a>
      </li>
      <li>
        <a href="#" id="topNavProfile"><span>Kado</span></a>
      </li>
    </ul>
  </nav>
</template>
