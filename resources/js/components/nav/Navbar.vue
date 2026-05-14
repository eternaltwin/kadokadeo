<script setup></script>

<template>
  <nav id="topNav">
    <ul>
      <li>
        <RouterLink :to="{ name: 'games.index' }" id="topNavGames">
          <span>Jeux</span>
        </RouterLink>
      </li>
      <li class="grayscale">
        <RouterLink to="/" id="topNavCompetition"><span>Site</span></RouterLink>
      </li>
      <li>
        <RouterLink :to="{ name: 'profile.index' }" id="topNavProfile"><span>Kado</span></RouterLink>
      </li>
    </ul>
  </nav>
</template>
